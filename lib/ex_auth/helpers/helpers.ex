defmodule ExAuth.Helpers do
  @moduledoc """
  Helper functions for the library
  """
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
end
