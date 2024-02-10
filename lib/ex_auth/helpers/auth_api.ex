defmodule ExAuth.AuthAPI do
  @moduledoc """
  This module is responsible to abstract the calls to AUTH server
  """
  alias ExAuth.Helpers
  alias ExGeeks.Helpers, as: GeeksHelpers

  def verify_token(token, type \\ "login") do
    query_params = "?token=#{token}&type=#{type}"
    project_id = Helpers.project_id()

    url = Helpers.endpoint() <> "/api/v1/project/#{project_id}/verify_token" <> query_params

    GeeksHelpers.endpoint_post_callback(url, %{}, Helpers.headers())
  end

  def get_user(user_id) do
    url = Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/user/#{user_id}"

    GeeksHelpers.endpoint_get_callback(url, Helpers.headers())
  end

  @doc """
  Provided a `token` it will revoke it to avoid further usage
  """
  def logout(%{token: _} = params) do
    url = Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/logout"

    GeeksHelpers.endpoint_post_callback(url, params, Helpers.headers())
  end

  def delete_user(user_id) do
    url = Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/delete/#{user_id}"

    GeeksHelpers.endpoint_delete_callback(url, Helpers.headers())
  end

  def get_users(filter \\ %{}, limit \\ nil, start \\ 0)

  def get_users(filter, limit, _start) when limit in [nil, 0] do
    users(filter, "")
  end

  def get_users(filter, limit, start) do
    if is_nil(start) do
      users(filter, "")
    else
      pagination = "limit=#{limit}&start=#{start}"
      users(filter, pagination)
    end
  end

  def users(filter, pagination) do
    filter =
      filter
      |> Enum.reduce("", fn {key, value}, acc ->
        acc <> "filter[#{key}]=#{value}&"
      end)

      GeeksHelpers.endpoint_get_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id()}/users?#{filter}&#{pagination}",
      Helpers.headers()
    )
  end

  def register(%{email: email} = user) do
    if Helpers.valid_email?(email) do
      GeeksHelpers.endpoint_post_callback(
        Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/register",
        user,
        Helpers.headers()
      )
    else
      %{
        "error" => "Invalid Email Format",
        "message" => "Please use a valid email",
        "status" => "failed"
      }
    end
  end

  def register(user) do
    GeeksHelpers.endpoint_post_callback(
      Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/register",
      user,
      Helpers.headers()
    )
  end

  def login(user) do
    url = Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/login"

    GeeksHelpers.endpoint_post_callback(url, user, Helpers.headers())
  end

  def update_private_user(%{email: email} = user, user_id) do
    if Helpers.valid_email?(email) do
      url = Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/privateuser/#{user_id}"

      GeeksHelpers.endpoint_put_callback(url, user, Helpers.headers())
    else
      %{
        "error" => "Invalid Email Format",
        "message" => "Please use a valid email",
        "status" => "failed"
      }
    end
  end

  ## not to be exposed for the host project internal use only
  def update_private_user(user, user_id) do
    url = Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/privateuser/#{user_id}"

    GeeksHelpers.endpoint_put_callback(url, user, Helpers.headers())
  end

  def update_user(%{email: email} = user, user_id) do
    if Helpers.valid_email?(email) do
      url = Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/user/#{user_id}"

      GeeksHelpers.endpoint_put_callback(url, user, Helpers.headers())
    else
      %{
        "error" => "Invalid Email Format",
        "message" => "Please use a valid email",
        "status" => "failed"
      }
    end
  end

  def update_user(user, user_id) do
    url = Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/user/#{user_id}"

    GeeksHelpers.endpoint_put_callback(url, user, Helpers.headers())
  end

  def reset_password(%{"user" => email} = user) do
    if Helpers.valid_email?(email) do
      GeeksHelpers.endpoint_post_callback(
        Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/reset_password",
        user,
        Helpers.headers()
      )
    else
      %{
        "error" => "Invalid Email Format",
        "message" => "Please use a valid email",
        "status" => "failed"
      }
    end
  end

  def reset_password(user) do
    GeeksHelpers.endpoint_post_callback(
      Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/reset_password",
      user,
      Helpers.headers()
    )
  end

  def get_project_roles do
    GeeksHelpers.endpoint_get_callback(
      Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/roles",
      Helpers.headers()
    )
  end

  def verify_password(user_id, password) do
    GeeksHelpers.endpoint_post_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id()}/user/#{user_id}/verify_password",
      %{password: password},
      Helpers.headers()
    )
  end

  def send_verification(user_id) do
    GeeksHelpers.endpoint_get_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id()}/user/#{user_id}/resend_verification",
      Helpers.headers()
    )
  end

  def verify_user(user_id) do
    GeeksHelpers.endpoint_put_callback(
      Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/verify_user/#{user_id}",
      %{},
      Helpers.headers()
    )
  end

  def login_as_user(user_id) do
    GeeksHelpers.endpoint_get_callback(
      "#{Helpers.endpoint()}/api/v1/project/#{Helpers.project_id()}/login/#{user_id}",
      Helpers.headers()
    )
  end

 @doc """
  Returns the url of the social media provider to send the user to so he authenticates with his Social account.
  The provider will then redirect the user to the `redirect_uri` with a code that must be used server side
  to collect the fields data.
 """
 def get_social_connect_link(provider, redirect_uri, scopes \\ nil) do
  scopes = if is_nil(scopes), do: "", else: "&scope[]=#{Enum.join(scopes, "&scope[]=")}"
  GeeksHelpers.endpoint_get_callback(
    Helpers.endpoint() <>
      "/api/v1/project/#{Helpers.project_id()}/auth/#{provider}?redirect_uri=#{redirect_uri}#{scopes}",
      Helpers.headers()
  )
 end

 @doc """
  Provided the code obtained from the authentication step, this will return the fields for the user account
  alongside the operation type
   - `register` if the user is not yet registered to auth
   - `login` if a user with the same login field already exists
  In case of a login, the response will also include a user_token
 """
 def social_connect(provider, code, redirect_uri, fields \\ nil) do
  fields = if is_nil(fields), do: "", else: "&fields[]=#{Enum.join(fields, "&fields[]=")}"
  GeeksHelpers.endpoint_get_callback(
    Helpers.endpoint() <>
      "/api/v1/auth/project/#{Helpers.project_id()}/#{provider}/callback?code=#{code}&redirect_uri=#{redirect_uri}#{fields}",
      Helpers.headers()
  )
 end

 @doc """
 Takes an ID as a parameter to return a challenge for signature.
 The nature of the challenge depends on the configuration of the `login_field` on the project
 """
 def get_challenge(id) do
  GeeksHelpers.endpoint_post_callback(
    Helpers.endpoint() <>
    "/api/v1/project/#{Helpers.project_id()}/login_challenge",
    id,
    Helpers.headers()
   )
 end

 @doc """
 Given an ID, a challenge and the signature of this challenge, it validates the signature and returns a user token.
 It will register a new user if the ID is new
 It will login the user carrying the ID if it exists already
 """
 def connect(connect) do
  GeeksHelpers.endpoint_post_callback(
    Helpers.endpoint() <>
    "/api/v1/project/#{Helpers.project_id()}/connect",
    connect,
    Helpers.headers()
  )
 end
end
