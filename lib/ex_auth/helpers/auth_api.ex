defmodule ExAuth.AuthAPI do
  @moduledoc """
  Client helpers for Auth backend API v1.

  Functions in this module build requests for the configured Auth project and
  return the decoded JSON response produced by `ExGeeks.Helpers`.

  Pass `project_name: name` in `opts` to target a configured secondary project;
  otherwise the default `:project_id` and `:private_key` configuration is used.
  """

  alias ExAuth.Helpers
  alias ExGeeks.Helpers, as: GeeksHelpers

  @type json ::
          nil
          | boolean()
          | number()
          | String.t()
          | [json()]
          | %{optional(String.t() | atom()) => json()}
  @type json_map :: %{optional(String.t() | atom()) => json()}
  @type opts :: keyword(String.t())
  @type user_id :: String.t()
  @type token :: String.t()
  @type token_type :: String.t()
  @type provider :: String.t()
  @type role :: %{optional(String.t()) => json()}
  @type user :: %{optional(String.t()) => json()}
  @type project :: %{optional(String.t()) => json()}
  @type auth_token :: %{optional(String.t()) => json()}
  @type message_response :: %{optional(String.t()) => json()}
  @type error_response :: %{optional(String.t()) => json()}
  @type api_response(data) ::
          %{optional(String.t()) => data | json()}
          | error_response()

  @type user_response :: api_response(%{optional(String.t()) => user() | json()})
  @type login_response ::
          api_response(%{optional(String.t()) => user() | auth_token() | json()})
  @type users_response :: api_response(%{optional(String.t()) => [user()] | json()})
  @type roles_response :: api_response([role()])
  @type dashboard_response :: api_response(json_map())
  @type project_response :: project() | api_response(project())

  @doc """
  Clears locally cached ExAuth data.

  This does not call the Auth API. It currently clears cached project roles so
  the next `get_project_roles/2` call fetches fresh data from
  `GET /api/v1/project/{project_id}/roles`.
  """
  @spec clear_cache() :: any()
  def clear_cache do
    Helpers.cache_delete(:roles)
  end

  @doc """
  Verifies an Auth token.

  Calls `POST /api/v1/project/{project_id}/verify_token` with a token and token
  type, such as `"login"`, `"reset"`, or `"verify"`.
  """
  @spec verify_token(token(), token_type(), opts()) :: user_response()
  def verify_token(token, type \\ "login", opts \\ []) do
    project_id = Helpers.project_id(opts[:project_name])
    body = %{token: token, type: type}

    url = Helpers.endpoint() <> "/api/v1/project/#{project_id}/verify_token"

    # When verifying a token, the private key is not necessary (and is slowing down response time)
    GeeksHelpers.endpoint_post_callback(url, body, Helpers.headers(nil, "ignored"))
  end

  @doc """
  Retrieves full user information as a project admin.

  Calls `GET /api/v1/project/{project_id}/user/{user_id}`.
  """
  @spec get_user(user_id(), opts()) :: user_response()
  def get_user(user_id, opts \\ []) do
    url =
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/user/#{user_id}"

    GeeksHelpers.endpoint_get_callback(url, Helpers.headers(opts[:project_name]))
  end

  @doc """
  Retrieves public user information.

  Calls `GET /api/v1/project/{project_id}/public_user/{user_id}` and returns
  only fields configured as public in Auth.
  """
  @spec get_public_user(user_id(), opts()) :: user_response()
  def get_public_user(user_id, opts \\ []) do
    url =
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/public_user/#{user_id}"

    GeeksHelpers.endpoint_get_callback(url, Helpers.headers(opts[:project_name]))
  end

  @doc """
  Revokes a token to prevent further usage.

  Calls `POST /api/v1/project/{project_id}/logout` with a payload containing a
  `:token` key.
  """
  @spec logout(%{required(:token) => token(), optional(atom()) => json()}, opts()) ::
          api_response(message_response())
  def logout(%{token: _} = params, opts \\ []) do
    url =
      Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/logout"

    GeeksHelpers.endpoint_post_callback(url, params, Helpers.headers(opts[:project_name]))
  end

  @doc """
  Deletes a project user as a project admin.

  Calls `DELETE /api/v1/project/{project_id}/delete/{user_id}`.
  """
  @spec delete_user(user_id(), opts()) :: api_response(message_response())
  def delete_user(user_id, opts \\ []) do
    url =
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/delete/#{user_id}"

    GeeksHelpers.endpoint_delete_callback(url, Helpers.headers(opts[:project_name]))
  end

  @doc """
  Retrieves project users as a project admin.

  Calls `GET /api/v1/project/{project_id}/users` with query string filters and
  optional `limit`/`start` pagination.
  """
  @spec get_users(json_map(), nil | non_neg_integer(), nil | non_neg_integer(), opts()) ::
          users_response()
  def get_users(filter \\ %{}, limit \\ nil, start \\ 0, opts \\ [])

  def get_users(filter, limit, _start, opts) when limit in [nil, 0] do
    users(filter, "", opts)
  end

  def get_users(filter, limit, start, opts) do
    if is_nil(start) do
      users(filter, "", opts)
    else
      pagination = "limit=#{limit}&start=#{start}"
      users(filter, pagination, opts)
    end
  end

  @doc """
  Internal request helper for v1 user search.

  Calls `GET /api/v1/project/{project_id}/users` using the already-built
  pagination query string.
  """
  @spec users(json_map(), String.t(), opts()) :: users_response()
  def users(filter, pagination, opts) do
    filter =
      filter
      |> Enum.reduce("", fn {key, value}, acc ->
        acc <> "filter[#{key}]=#{value}&"
      end)

    GeeksHelpers.endpoint_get_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/users?#{filter}&#{pagination}",
      Helpers.headers(opts[:project_name])
    )
  end

  @doc """
  Registers a new project user.

  Calls `POST /api/v1/project/{project_id}/register`. If an `:email` key is
  present, ExAuth validates its format before making the request.
  """
  @spec register(json_map(), opts()) :: login_response() | error_response()
  def register(user, opts \\ [])

  def register(%{email: email} = user, opts) do
    if Helpers.valid_email?(email) do
      GeeksHelpers.endpoint_post_callback(
        Helpers.endpoint() <>
          "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/register",
        user,
        Helpers.headers(opts[:project_name])
      )
    else
      %{
        "error" => "Invalid Email Format",
        "message" => "Please use a valid email",
        "status" => "failed"
      }
    end
  end

  def register(user, opts) do
    GeeksHelpers.endpoint_post_callback(
      Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/register",
      user,
      Helpers.headers(opts[:project_name])
    )
  end

  @doc """
  Logs in a project user.

  Calls `POST /api/v1/project/{project_id}/login` and returns the user and login
  token on success.
  """
  @spec login(json_map(), opts()) :: login_response()
  def login(user, opts \\ []) do
    url = Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/login"

    GeeksHelpers.endpoint_post_callback(url, user, Helpers.headers(opts[:project_name]))
  end

  @doc """
  Updates user information as a project admin.

  Calls `PUT /api/v1/project/{project_id}/privateuser/{user_id}`. If an `:email`
  key is present, ExAuth validates its format before making the request.
  """
  @spec update_private_user(json_map(), user_id(), opts()) :: user_response() | error_response()
  def update_private_user(user, user_id, opts \\ [])

  def update_private_user(%{email: email} = user, user_id, opts) do
    if Helpers.valid_email?(email) do
      url =
        Helpers.endpoint() <>
          "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/privateuser/#{user_id}"

      GeeksHelpers.endpoint_put_callback(url, user, Helpers.headers(opts[:project_name]))
    else
      %{
        "error" => "Invalid Email Format",
        "message" => "Please use a valid email",
        "status" => "failed"
      }
    end
  end

  ## not to be exposed for the host project internal use only
  def update_private_user(user, user_id, opts) do
    url =
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/privateuser/#{user_id}"

    GeeksHelpers.endpoint_put_callback(url, user, Helpers.headers(opts[:project_name]))
  end

  @doc """
  Updates the current user with a user token.

  Calls `PUT /api/v1/project/{project_id}/user`. If an `:email` key is present,
  ExAuth validates its format before making the request.
  """
  @spec update_user(json_map(), token(), opts()) :: user_response() | error_response()
  def update_user(user, user_token, opts \\ [])

  def update_user(%{email: email} = user, user_token, opts) do
    if Helpers.valid_email?(email) do
      url =
        Helpers.endpoint() <>
          "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/user"

      GeeksHelpers.endpoint_put_callback(url, user, Helpers.headers(nil, user_token))
    else
      %{
        "error" => "Invalid Email Format",
        "message" => "Please use a valid email",
        "status" => "failed"
      }
    end
  end

  def update_user(user, user_token, opts) do
    url =
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/user/"

    GeeksHelpers.endpoint_put_callback(url, user, Helpers.headers(nil, user_token))
  end

  @doc """
  Requests a reset password token.

  Calls `POST /api/v1/project/{project_id}/reset_password`. If the payload has a
  string `"user"` key, ExAuth validates it as an email before making the request.
  """
  @spec reset_password(json_map(), opts()) :: api_response(message_response()) | error_response()
  def reset_password(user, opts \\ [])

  def reset_password(%{"user" => email} = user, opts) do
    if Helpers.valid_email?(email) do
      GeeksHelpers.endpoint_post_callback(
        Helpers.endpoint() <>
          "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/reset_password",
        user,
        Helpers.headers(opts[:project_name])
      )
    else
      %{
        "error" => "Invalid Email Format",
        "message" => "Please use a valid email",
        "status" => "failed"
      }
    end
  end

  def reset_password(user, opts) do
    GeeksHelpers.endpoint_post_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/reset_password",
      user,
      Helpers.headers(opts[:project_name])
    )
  end

  @doc """
  Sets a new password using a reset token.

  Calls `POST /api/v1/project/{project_id}/new_password` with the reset token in
  the `token` header and the new password in the request body.
  """
  @spec new_password(String.t(), token(), opts()) :: api_response(message_response())
  def new_password(password, token, opts \\ []) do
    GeeksHelpers.endpoint_post_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/new_password",
      %{"password" => password},
      Helpers.headers(nil, token)
    )
  end

  @doc """
  Retrieves all roles configured for the Auth project.

  Calls `GET /api/v1/project/{project_id}/roles` when the cache is empty or
  `refresh` is `true`. This function returns the extracted role list from the
  response `data`, not the full API envelope.
  """
  @spec get_project_roles(boolean(), opts()) :: [role()]
  def get_project_roles(refresh \\ false, opts \\ []) do
    key =
      if is_nil(opts[:project_name]),
        do: String.to_atom("roles"),
        else: String.to_atom("roles_" <> opts[:project_name])

    roles = Helpers.cache_get(key)

    if is_nil(roles) or refresh do
      %{"data" => roles} =
        GeeksHelpers.endpoint_get_callback(
          Helpers.endpoint() <>
            "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/roles",
          Helpers.headers(opts[:project_name])
        )

      Helpers.cache_set(key, roles)
      roles
    else
      roles
    end
  end

  @doc """
  Returns a role id by role title.

  This does not call an endpoint directly; it reads from `get_project_roles/2`.
  """
  @spec get_role_id(String.t(), opts()) :: String.t()
  def get_role_id(role_title, opts \\ []) do
    [role_object] =
      get_project_roles(false, opts)
      |> Enum.filter(fn %{"title" => title} -> title == role_title end)

    Map.get(role_object, "id")
  end

  @doc """
  Returns a role object by role id.

  This does not call an endpoint directly; it reads from `get_project_roles/2`.
  Enabling caching is recommended to avoid repeated Auth API requests.
  """
  @spec get_role_object(String.t(), opts()) :: role()
  def get_role_object(role_id, opts \\ []) do
    [role_object] =
      get_project_roles(false, opts)
      |> Enum.filter(fn %{"id" => id} -> id == role_id end)

    role_object
  end

  @doc """
  Verifies a user's password as a project admin.

  Calls `POST /api/v1/project/{project_id}/user/{user_id}/verify_password`.
  """
  @spec verify_password(user_id(), String.t(), opts()) :: api_response(json_map())
  def verify_password(user_id, password, opts \\ []) do
    GeeksHelpers.endpoint_post_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/user/#{user_id}/verify_password",
      %{password: password},
      Helpers.headers(opts[:project_name])
    )
  end

  @doc """
  Requests a new verification token for a user.

  Calls `GET /api/v1/project/{project_id}/user/{user_id}/resend_verification`.
  """
  @spec send_verification(user_id(), opts()) :: api_response(message_response())
  def send_verification(user_id, opts \\ []) do
    GeeksHelpers.endpoint_get_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/user/#{user_id}/resend_verification",
      Helpers.headers(opts[:project_name])
    )
  end

  @doc """
  Verifies a user as a project admin.

  Calls `PUT /api/v1/project/{project_id}/verify_user/{user_id}`.
  """
  @spec verify_user(user_id(), opts()) :: user_response()
  def verify_user(user_id, opts \\ []) do
    GeeksHelpers.endpoint_put_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/verify_user/#{user_id}",
      %{},
      Helpers.headers(opts[:project_name])
    )
  end

  @doc """
  Generates a login token for a project user as a project admin.

  Calls `GET /api/v1/project/{project_id}/login/{user_id}`.
  """
  @spec login_as_user(user_id(), opts()) :: login_response()
  def login_as_user(user_id, opts \\ []) do
    GeeksHelpers.endpoint_get_callback(
      "#{Helpers.endpoint()}/api/v1/project/#{Helpers.project_id(opts[:project_name])}/login/#{user_id}",
      Helpers.headers(opts[:project_name])
    )
  end

  @doc """
  Returns an OAuth provider URL for social login.

  Calls the Auth OAuth authorization endpoint for the configured project. The
  provider redirects the user to `redirect_uri` with a code to exchange through
  `social_connect/5`.
  """
  @spec get_social_connect_link(provider(), String.t(), nil | [String.t()], opts()) ::
          api_response(json_map())
  def get_social_connect_link(provider, redirect_uri, scopes \\ nil, opts \\ []) do
    oauth_link([provider: provider, redirect_uri: redirect_uri, scopes: scopes], opts)
  end

  @doc """
  Builds and requests an OAuth authorization link.

  Expects `:provider` and `:redirect_uri` in `params`, and optionally `:scopes`.
  Calls the same Auth OAuth authorization endpoint as
  `get_social_connect_link/4`.
  """
  @spec oauth_link(keyword(), opts()) :: api_response(json_map())
  def oauth_link(params, opts \\ []) do
    if is_nil(params[:provider]) or is_nil(params[:redirect_uri]),
      do: raise("provider and redirect_uri are mandatory")

    scopes =
      if is_nil(params[:scopes]),
        do: "",
        else: "&scope[]=#{Enum.join(params[:scopes], "&scope[]=")}"

    GeeksHelpers.endpoint_get_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/auth/#{params[:provider]}?redirect_uri=#{params[:redirect_uri]}#{scopes}",
      Helpers.headers(opts[:project_name], opts[:token])
    )
  end

  @doc """
  Exchanges an OAuth callback code for social account data.

  Calls the Auth OAuth callback endpoint. The response includes the operation
  type, such as `"register"` or `"login"`; login responses can include a user
  token.
  """
  @spec social_connect(provider(), String.t(), String.t(), nil | [String.t()], opts()) ::
          api_response(json_map())
  def social_connect(provider, code, redirect_uri, fields \\ nil, opts \\ []) do
    oauth_token(
      [provider: provider, code: code, redirect_uri: redirect_uri, fields: fields],
      opts
    )
  end

  @doc """
  Exchanges an OAuth callback code for account data.

  Expects `:provider`, `:code`, and `:redirect_uri` in `params`, and optionally
  `:fields`. Calls the same Auth OAuth callback endpoint as `social_connect/5`.
  """
  @spec oauth_token(keyword(), opts()) :: api_response(json_map())
  def oauth_token(params, opts \\ []) do
    if is_nil(params[:provider]) or is_nil(params[:code]) or is_nil(params[:redirect_uri]),
      do: raise("provider, code and redirect_uri are mandatory")

    fields =
      if is_nil(params[:fields]),
        do: "",
        else: "&fields[]=#{Enum.join(params[:fields], "&fields[]=")}"

    GeeksHelpers.endpoint_get_callback(
      Helpers.endpoint() <>
        "/api/v1/auth/project/#{Helpers.project_id(opts[:project_name])}/#{params[:provider]}/callback?code=#{params[:code]}&redirect_uri=#{params[:redirect_uri]}#{fields}",
      Helpers.headers(opts[:project_name], opts[:token])
    )
  end

  @doc """
  Refreshes stored OAuth provider data for a user.

  Calls `GET /api/v1/project/{project_id}/{provider}/refresh/{user_id}`.
  """
  @spec refresh_token(user_id(), provider(), opts()) :: api_response(json_map())
  def refresh_token(user_id, provider, opts \\ []) do
    GeeksHelpers.endpoint_get_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/#{provider}/refresh/#{user_id}",
      Helpers.headers(opts[:project_name])
    )
  end

  @doc """
  Returns a challenge for signature-based authentication.

  Calls `POST /api/v1/project/{project_id}/login_challenge`. The challenge
  depends on the project's configured `login_field`.
  """
  @spec get_challenge(json_map(), opts()) :: api_response(json_map())
  def get_challenge(id, opts \\ []) do
    GeeksHelpers.endpoint_post_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/login_challenge",
      id,
      Helpers.headers(opts[:project_name])
    )
  end

  @doc """
  Logs in or registers a user with a signed challenge.

  Calls `POST /api/v1/project/{project_id}/connect` with the identifier,
  challenge, and signature. Auth registers a new user when the identifier is new
  and logs in the existing user otherwise.
  """
  @spec connect(json_map(), opts()) :: login_response()
  def connect(connect, opts \\ []) do
    GeeksHelpers.endpoint_post_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/connect",
      connect,
      Helpers.headers(opts[:project_name])
    )
  end

  @doc """
  Returns dashboard data for the given facets.

  Calls `POST /api/v1/project/{project_id}/dashboard` with a list of facets, for
  example `"totalRegisteredUsers"` or `"referrerLeaderboard"`.
  """
  @spec dashboard([String.t()], opts()) :: dashboard_response()
  def dashboard(facets, opts \\ []) do
    GeeksHelpers.endpoint_post_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/dashboard",
      %{"facets" => facets},
      Helpers.headers(opts[:project_name])
    )
  end

  @doc """
  Returns dashboard data for the given facets and timeframe.

  Calls `POST /api/v1/project/{project_id}/dashboard` with `facets` and a
  `timeframe` containing `start` and `end` timestamps.
  """
  @spec dashboard([String.t()], integer(), integer(), opts()) :: dashboard_response()
  def dashboard(facets, time_start, time_end, opts \\ []) do
    GeeksHelpers.endpoint_post_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/dashboard",
      %{"facets" => facets, "timeframe" => %{"start" => time_start, "end" => time_end}},
      Helpers.headers(opts[:project_name])
    )
  end

  @doc """
  Retrieves the configured Auth project.

  Calls `GET /api/v1/project/{project_id}`.
  """
  @spec get_project(opts()) :: project_response()
  def get_project(opts \\ []) do
    GeeksHelpers.endpoint_get_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}",
      Helpers.headers(opts[:project_name])
    )
  end
end
