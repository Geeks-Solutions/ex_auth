defmodule ExAuth.AuthAPIV2 do
  @moduledoc """
  This module is responsible to abstract the calls to AUTH server
  """
  alias ExAuth.Helpers
  alias ExGeeks.Helpers, as: GeeksHelpers

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
    GeeksHelpers.endpoint_post_callback(
      Helpers.endpoint() <>
        "/api/v2/project/#{Helpers.project_id()}/users?#{pagination}",
      filter,
      Helpers.headers()
    )
  end

  def send_verification(user_id, metadata \\ %{}) when not is_nil(user_id) do
    GeeksHelpers.endpoint_post_callback(
      Helpers.endpoint() <>
        "/api/v2/project/#{Helpers.project_id()}/user/#{user_id}/resend_verification",
      %{"metadata" => metadata},
      Helpers.headers()
    )
  end

  def send_verification(_ ,_ ), do: %{"status" => "failed", "message" => "ExAuth: Provide a user_id"}
end
