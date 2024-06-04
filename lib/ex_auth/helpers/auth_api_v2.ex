defmodule ExAuth.AuthAPIV2 do
  @moduledoc """
  This module is responsible to abstract the calls to AUTH server
  """
  alias ExAuth.Helpers
  alias ExGeeks.Helpers, as: GeeksHelpers

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
    GeeksHelpers.endpoint_post_callback(
      Helpers.endpoint() <>
        "/api/v2/project/#{Helpers.project_id(opts[:project_name])}/users?#{pagination}",
      filter,
      Helpers.headers(opts[:project_name])
    )
  end

  def send_verification(user_id, metadata \\ %{}, opts \\ []) when not is_nil(user_id) do
    GeeksHelpers.endpoint_post_callback(
      Helpers.endpoint() <>
        "/api/v2/project/#{Helpers.project_id(opts[:project_name])}/user/#{user_id}/resend_verification",
      %{"metadata" => metadata},
      Helpers.headers(opts[:project_name])
    )
  end

  def send_verification(_ ,_ , _), do: %{"status" => "failed", "message" => "ExAuth: Provide a user_id"}
end
