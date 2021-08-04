defmodule ExAuth.AuthAPI do
  @moduledoc """
  This module is responsible to abstract the calls to AUTH server
  """
  alias ExAuth.Helpers

  def verify_token(token, type \\ "login") do
    query_params = "?token=#{token}&type=#{type}"
    project_id = Helpers.project_id()

    url = Helpers.endpoint() <> "/api/v1/project/#{project_id}/verify_token" <> query_params

    Helpers.endpoint_post_callback(url, %{}, [
      {"content-type", "application/json"},
      {"privatekey", Helpers.private_key()}
    ])
  end

  def register(user) do
    Helpers.endpoint_post_callback(
      Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/register",
      user,
      [
        {"content-type", "application/json"},
        {"privatekey", Helpers.private_key()}
      ]
    )
  end

  def login(user) do
    url = Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/login"

    Helpers.endpoint_post_callback(url, user, [
      {"content-type", "application/json"},
      {"privatekey", Helpers.private_key()}
    ])
  end

  def update_user(user, user_id) do
    url = Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/privateuser/#{user_id}"

    Helpers.endpoint_put_callback(url, user, [
      {"content-type", "application/json"},
      {"privatekey", Helpers.private_key()}
    ])
  end

  def reset_password(user) do
    Helpers.endpoint_post_callback(
      Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/reset_password",
      user,
      [
        {"content-type", "application/json"},
        {"privatekey", Helpers.private_key()}
      ]
    )
  end
end
