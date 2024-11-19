defmodule ExAuth.AuthAPI do
  @moduledoc """
  This module is responsible to abstract the calls to AUTH server
  """
  alias ExAuth.Helpers
  alias ExGeeks.Helpers, as: GeeksHelpers

  @doc """
  This function will clear all caches that have been set by ex_auth
  forcing a refresh when functions requiring the data are called
  """
  def clear_cache do
    Helpers.cache_delete(:roles)
  end

  def verify_token(token, type \\ "login", opts \\ []) do
    project_id = Helpers.project_id(opts[:project_name])
    body = %{token: token, type: type}

    url = Helpers.endpoint() <> "/api/v1/project/#{project_id}/verify_token"

    GeeksHelpers.endpoint_post_callback(url, body, Helpers.headers(opts[:project_name]))
  end

  def get_user(user_id, opts \\ []) do
    url =
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/user/#{user_id}"

    GeeksHelpers.endpoint_get_callback(url, Helpers.headers(opts[:project_name]))
  end

  @doc """
  Provided a `token` it will revoke it to avoid further usage
  """
  def logout(%{token: _} = params, opts \\ []) do
    url =
      Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/logout"

    GeeksHelpers.endpoint_post_callback(url, params, Helpers.headers(opts[:project_name]))
  end

  def delete_user(user_id, opts \\ []) do
    url =
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/delete/#{user_id}"

    GeeksHelpers.endpoint_delete_callback(url, Helpers.headers(opts[:project_name]))
  end

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

  def login(user, opts \\ []) do
    url = Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/login"

    GeeksHelpers.endpoint_post_callback(url, user, Helpers.headers(opts[:project_name]))
  end

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
  Will get all the roles set in your AUTH project
  If you enabled caching, the results will be stored locally and you can refresh it by providing the `true` param
  If caching is not enabled, it will run a request to auth everytime this is called
  """
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

  def get_role_id(role_title, opts \\ []) do
    [role_object] =
      get_project_roles(false, opts)
      |> Enum.filter(fn %{"title" => title} -> title == role_title end)

    Map.get(role_object, "id")
  end

  @doc """
  Provided a valid role_id will return the full role object
  title and id
  It is strongly advised to enable caching when calling this function
  to avoid multiple requests to the Auth API
  """
  def get_role_object(role_id, opts \\ []) do
    [role_object] =
      get_project_roles(false, opts)
      |> Enum.filter(fn %{"id" => id} -> id == role_id end)

    role_object
  end

  def verify_password(user_id, password, opts \\ []) do
    GeeksHelpers.endpoint_post_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/user/#{user_id}/verify_password",
      %{password: password},
      Helpers.headers(opts[:project_name])
    )
  end

  def send_verification(user_id, opts \\ []) do
    GeeksHelpers.endpoint_get_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/user/#{user_id}/resend_verification",
      Helpers.headers(opts[:project_name])
    )
  end

  def verify_user(user_id, opts \\ []) do
    GeeksHelpers.endpoint_put_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/verify_user/#{user_id}",
      %{},
      Helpers.headers(opts[:project_name])
    )
  end

  def login_as_user(user_id, opts \\ []) do
    GeeksHelpers.endpoint_get_callback(
      "#{Helpers.endpoint()}/api/v1/project/#{Helpers.project_id(opts[:project_name])}/login/#{user_id}",
      Helpers.headers(opts[:project_name])
    )
  end

  @doc """
   Returns the url of the social media provider to send the user to so he authenticates with his Social account.
   The provider will then redirect the user to the `redirect_uri` with a code that must be used server side
   to collect the fields data.
  """
  def get_social_connect_link(provider, redirect_uri, scopes \\ nil, opts \\ []) do
    oauth_link([provider: provider, redirect_uri: redirect_uri, scopes: scopes], opts)
  end

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
   Provided the code obtained from the authentication step, this will return the fields for the user account
   alongside the operation type
    - `register` if the user is not yet registered to auth
    - `login` if a user with the same login field already exists
   In case of a login, the response will also include a user_token
  """
  def social_connect(provider, code, redirect_uri, fields \\ nil, opts \\ []) do
    oauth_token(
      [provider: provider, code: code, redirect_uri: redirect_uri, fields: fields],
      opts
    )
  end

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

  def refresh_token(user_id, provider, opts \\ []) do
    GeeksHelpers.endpoint_get_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/#{provider}/refresh/#{user_id}",
      Helpers.headers(opts[:project_name])
    )
  end

  @doc """
  Takes an ID as a parameter to return a challenge for signature.
  The nature of the challenge depends on the configuration of the `login_field` on the project
  """
  def get_challenge(id, opts \\ []) do
    GeeksHelpers.endpoint_post_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/login_challenge",
      id,
      Helpers.headers(opts[:project_name])
    )
  end

  @doc """
  Given an ID, a challenge and the signature of this challenge, it validates the signature and returns a user token.
  - It will register a new user if the ID is new
  - It will login the user carrying the ID if it exists already
  """
  def connect(connect, opts \\ []) do
    GeeksHelpers.endpoint_post_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/connect",
      connect,
      Helpers.headers(opts[:project_name])
    )
  end

  @doc """
  Provides the result of the dashboard for the given facets:
  - facets: a list of facet ['totalRegisteredUsers','referrerLeaderboard' etc..]
  - (optional) time_start: a timestamp to define the start date for range facets
  - (optional) time_end: a timestamp to define the end date for range facets
  """
  def dashboard(facets, opts \\ []) do
    GeeksHelpers.endpoint_post_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/dashboard",
      %{"facets" => facets},
      Helpers.headers(opts[:project_name])
    )
  end

  def dashboard(facets, time_start, time_end, opts \\ []) do
    GeeksHelpers.endpoint_post_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}/dashboard",
      %{"facets" => facets, "timeframe" => %{"start" => time_start, "end" => time_end}},
      Helpers.headers(opts[:project_name])
    )
  end

  def get_project(opts \\ []) do
    GeeksHelpers.endpoint_get_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id(opts[:project_name])}",
      Helpers.headers(opts[:project_name])
    )
  end
end
