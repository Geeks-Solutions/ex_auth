defmodule ExAuth.AuthAPIV2 do
  @moduledoc """
  Client helpers for Auth backend API v2 endpoints supported by ExAuth.

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
  @type user :: %{"user_id" => String.t(), optional(String.t()) => json()}
  @type message_response :: %{"message" => String.t(), optional(String.t()) => json()}
  @type error_response :: %{"message" => String.t(), optional(String.t()) => json()}
  @type api_response(data) ::
          %{
            "status" => String.t(),
            optional("message") => String.t(),
            optional("data") => data,
            optional(String.t()) => json()
          }
          | error_response()

  @type users_response :: api_response(%{"users" => [user()], optional(String.t()) => json()})

  @doc """
  Retrieves project users as a project admin using the v2 search endpoint.

  Calls `POST /api/v2/project/{project_id}/users` with the filter in the request
  body and optional `limit`/`start` pagination in the query string.
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
  Internal request helper for v2 user search.

  Calls `POST /api/v2/project/{project_id}/users` using the already-built
  pagination query string.
  """
  @spec users(json_map(), String.t(), opts()) :: users_response()
  def users(filter, pagination, opts) do
    GeeksHelpers.endpoint_post_callback(
      Helpers.endpoint() <>
        "/api/v2/project/#{Helpers.project_id(opts[:project_name])}/users?#{pagination}",
      filter,
      Helpers.headers(opts[:project_name])
    )
  end

  @doc """
  Requests a verification token for a user with optional metadata.

  Calls `POST /api/v2/project/{project_id}/user/{user_id}/resend_verification`
  and sends `%{"metadata" => metadata}` as the request body.
  """
  @spec send_verification(user_id(), json_map(), opts()) :: api_response(message_response())
  def send_verification(user_id, metadata \\ %{}, opts \\ []) when not is_nil(user_id) do
    GeeksHelpers.endpoint_post_callback(
      Helpers.endpoint() <>
        "/api/v2/project/#{Helpers.project_id(opts[:project_name])}/user/#{user_id}/resend_verification",
      %{"metadata" => metadata},
      Helpers.headers(opts[:project_name])
    )
  end

  @doc """
  Returns a local failure when no user id is provided.

  This clause does not call the Auth API.
  """
  @spec send_verification(nil, json_map(), opts()) :: %{
          "status" => "failed",
          "message" => String.t()
        }
  def send_verification(_, _, _),
    do: %{"status" => "failed", "message" => "ExAuth: Provide a user_id"}
end
