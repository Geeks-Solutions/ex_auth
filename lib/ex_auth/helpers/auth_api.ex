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

    Helpers.endpoint_get_callback(url, Helpers.headers())
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

  ## not to be exposed for the host project internal use only
  def update_private_user(user, user_id) do
    url = Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/privateuser/#{user_id}"

    Helpers.endpoint_put_callback(url, user, Helpers.headers())
  end

  # def update_user(user, user_id) do
  #   url = Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/user/#{user_id}"

  #   Helpers.endpoint_put_callback(url, user, Helpers.headers())
  # end

  def reset_password(user) do
    Helpers.endpoint_post_callback(
      Helpers.endpoint() <> "/api/v1/project/#{Helpers.project_id()}/reset_password",
      user,
      Helpers.headers()
    )
  end
end
