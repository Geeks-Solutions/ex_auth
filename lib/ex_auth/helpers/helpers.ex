defmodule ExAuth.Helpers do
  @moduledoc """
  Helper functions for the library
  """
  alias ExAuth.AuthAPI
  alias ExGeeks.Helpers, as: GeeksHelpers
  require Logger

  @email_regex ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/
  def env(key, opts \\ %{default: nil, raise: false}) do
    Application.get_env(:ex_auth, key)
    |> case do
      nil ->
        if opts |> Map.get(:raise, false),
          do: raise("Please configure :#{key} to use ex_auth as desired,
          i.e:
          config, :ex_auth,
            #{key}: VALUE_HERE "),
          else: opts |> Map.get(:default)

      value when key == :secondary_projects ->
        Poison.decode!(value)

      value ->
        value
    end
  end

  def headers do
    [
      {"content-type", "application/json"},
      {"privatekey", private_key()}
    ]
  end

  def headers(nil), do: headers()

  def headers(project_name) do
    private_key = Map.get(env(:secondary_projects), project_name)["key"]
    [
      {"content-type", "application/json"},
      {"privatekey", private_key}
    ]
  end

  def headers(project_name \\ nil, token \\ nil)
  def headers(nil, nil), do: headers()
  def headers(project_name, nil), do: headers(project_name)
  def headers(_, token) do
    [
      {"content-type", "application/json"},
      {"token", token}
    ]
  end

  def project_id do
    env(:project_id, %{raise: true})
  end

  def project_id(nil) do
    project_id()
  end

  def project_id(project_name) do
    Map.get(env(:secondary_projects), project_name)["id"]
  end

  def private_key do
    env(:private_key, %{raise: true})
  end

  def endpoint do
    env(:endpoint, %{raise: false, default: "https://auth.geeks.solutions"})
  end

  def ws_endpoint do
    env(:ws_endpoint, %{raise: false, default: "wss://auth.geeks.solutions/socket/websocket"})
  end

  # This version is required in case a user wants to empty his email when this is not
  # a login field
  def valid_email?(email) when is_nil(email) or email == "", do: true

  def valid_email?(email) do
    String.match?(email, @email_regex)
  end

  def cache_get(key) do
    if env(:cache, %{raise: false, default: false}),
    do: ExGeeks.EtsCaching.get(:ex_auth, key),
    else: nil
  end

  def cache_set(key, value) do
    if env(:cache, %{raise: false, default: false}),
    do: ExGeeks.EtsCaching.set(:ex_auth, key, value),
    else: nil
  end

  def cache_delete(key) do
    if env(:cache, %{raise: false, default: false}),
    do: ExGeeks.EtsCaching.delete(:ex_auth, key),
    else: nil
  end

  # Return the current user context based on the authorization header
  def build_user_context_socket(params) do
    if is_nil(Map.get(params, "authorization", nil)) do
      default_value_user(params) |> add_fields(params)
    else
      user_process(
        params,
        Map.get(params, "token-type", nil),
        Map.get(params, "auth-project", nil)
      )
    end
  end

  defp user_process(params, nil, auth_project), do: user_process(params, "login", auth_project)

  defp user_process(params, type, auth_project) do
    with "Bearer " <> token when is_binary(token) <- Map.get(params, "authorization"),
         {:ok, current_user} <- authorize(token, type, auth_project) do
      %{current_user: current_user, token: token, token_type: type} |> add_fields(params)
    else
      {:error, "invalid authorization token"} ->
        {:error, "invalid authorization token"}

      _ ->
        default_value_user(params) |> add_fields(params)
    end
  end

  defp default_value_user(%{
         private: %{absinthe: %{context: %{current_user: current_user}}}
       }) do
    %{current_user: current_user}
  end

  defp default_value_user(_), do: %{current_user: nil}

  defp add_fields(main_data, _params) do
    roles = get_roles(main_data)

    new_current_user =
      return_add_fields(main_data.current_user, %{
        role: roles
      })

    main_data
    |> Map.put(:current_user, new_current_user)
  end

  defp get_roles(main_data) do
    case main_data do
      %{current_user: %{user: %{info: info}}, token: _token} ->
        roles =
          Enum.reduce(info.roles_object, [], fn %{title: title} = _role, acc ->
            List.insert_at(acc, -1, title)
          end)

        roles

      _ ->
        nil
    end
  end

  defp return_add_fields(current_user, %{
         role: role
       }) do
    map =
      case current_user do
        nil ->
          %{}

        _ ->
          current_user
      end

    map
    |> Map.put(:roles, role)
  end

  defp authorize(token, type, auth_project) do
    case AuthAPI.verify_token(token, type, project_name: auth_project) do
      %{
        "data" => %{
          "token" => %{"token" => _token, "type" => ^type},
          "user" => user
        }
      } ->
        {:ok,
         %{
           user: %{
             info: user |> GeeksHelpers.atomize_keys()
           }
         }}

      %{"message" => err, "status" => "failed"} ->
        Logger.error("GQL Context: #{err}")
        {:error, "ex_auth: GQL Context - #{err}"}

      %{"error" => _} ->
        Logger.error("ex_auth: GQL Context - invalid authorization token")
        {:error, "invalid authorization token"}
    end
  end
end
