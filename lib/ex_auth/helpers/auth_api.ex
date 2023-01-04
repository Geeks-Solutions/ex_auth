defmodule ExAuth.AuthAPI do
  @moduledoc """
  This module is responsible to abstract the calls to AUTH server
  """
  alias ExAuth.Helpers

  def verify_token(token, type \\ "login") do
    query_params = "?token=#{token}&type=#{type}"
    project_id = Helpers.project_id()

    url = Helpers.endpoint() <> "/api/v1/project/#{project_id}/verify_token" <> query_params

    Helpers.endpoint_post_callback(url, %{}, Helpers.headers())
  end

  def get_user(user_id) do
    url = Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/user/#{user_id}"

    Helpers.endpoint_get_callback(url, Helpers.headers())
  end

  def logout(params) do
    url = Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/logout"

    Helpers.endpoint_post_callback(url, params, Helpers.headers())
  end

  def delete_user(user_id) do
    url = Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/delete/#{user_id}"

    Helpers.endpoint_delete_callback(url, Helpers.headers())
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

    Helpers.endpoint_get_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id()}/users?#{filter}&#{pagination}",
      Helpers.headers()
    )
  end

  def register(%{email: email} = user) do
    if Helpers.valid_email?(email) do
      Helpers.endpoint_post_callback(
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
    Helpers.endpoint_post_callback(
      Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/register",
      user,
      Helpers.headers()
    )
  end

  def login(user) do
    url = Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/login"

    Helpers.endpoint_post_callback(url, user, Helpers.headers())
  end

  def update_private_user(%{email: email} = user, user_id) do
    if Helpers.valid_email?(email) do
      url = Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/privateuser/#{user_id}"

      Helpers.endpoint_put_callback(url, user, Helpers.headers())
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

    Helpers.endpoint_put_callback(url, user, Helpers.headers())
  end

  def update_user(%{email: email} = user, user_id) do
    if Helpers.valid_email?(email) do
      url = Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/user/#{user_id}"

      Helpers.endpoint_put_callback(url, user, Helpers.headers())
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

    Helpers.endpoint_put_callback(url, user, Helpers.headers())
  end

  def reset_password(%{"user" => email} = user) do
    if Helpers.valid_email?(email) do
      Helpers.endpoint_post_callback(
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
    Helpers.endpoint_post_callback(
      Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/reset_password",
      user,
      Helpers.headers()
    )
  end

  def get_project_roles do
    Helpers.endpoint_get_callback(
      Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/roles",
      Helpers.headers()
    )
  end

  def verify_password(user_id, password) do
    Helpers.endpoint_post_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id()}/user/#{user_id}/verify_password",
      %{password: password},
      Helpers.headers()
    )
  end

  def send_verification(user_id) do
    Helpers.endpoint_get_callback(
      Helpers.endpoint() <>
        "/api/v1/project/#{Helpers.project_id()}/user/#{user_id}/resend_verification",
      Helpers.headers()
    )
  end

  def verify_user(user_id) do
    Helpers.endpoint_put_callback(
      Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/verify_user/#{user_id}",
      %{},
      Helpers.headers()
    )
  end

  def login_as_user(user_id) do
    Helpers.endpoint_get_callback(
      "#{Helpers.endpoint()}/api/v1/project/#{Helpers.project_id()}/login/#{user_id}",
      Helpers.headers()
    )
  end
end
