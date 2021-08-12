defmodule ExAuth.Helpers do
  @moduledoc """
  Helper functions for the library
  """
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

  def project_id do
    env(:project_id, %{raise: true})
  end

  def private_key do
    env(:private_key, %{raise: true}) |> Bcrypt.hash_pwd_salt()
  end

  def endpoint do
    env(:endpoint, %{raise: false, default: "https://auth.geeks.solutions"})
  end

  def endpoint_get_callback(
        url,
        headers \\ [{"content-type", "application/json"}]
      ) do
    case HTTPoison.get(url, headers) do
      {:ok, response} ->
        fetch_response_body(response)

      {:error, error} ->
        {:error, error}
    end
  end

  def endpoint_put_callback(
        url,
        args,
        headers \\ [{"content-type", "application/json"}]
      ) do
    {:ok, body} = args |> Poison.encode()

    case HTTPoison.put(url, body, headers) do
      {:ok, response} ->
        fetch_response_body(response)

      {:error, _error} ->
        {:error, "users credentials server error"}
    end
  end

  def endpoint_post_callback(
        url,
        args,
        headers \\ [{"content-type", "application/json"}]
      ) do
    {:ok, body} = args |> Poison.encode()

    case HTTPoison.post(url, body, headers) do
      {:ok, response} ->
        fetch_response_body(response)

      {:error, _error} ->
        {:error, "users credentials server error"}
    end
  end

  def endpoint_delete_callback(
        url,
        headers \\ [{"content-type", "application/json"}]
      ) do
    # to use a delete request with a body
    # refer to Httpoison.request/5
    # {:ok, body} = args |> Poison.encode()

    case HTTPoison.delete(url, headers) do
      {:ok, response} ->
        fetch_response_body(response)

      {:error, _error} ->
        {:error, "users credentials server error"}
    end
  end

  defp fetch_response_body(response) do
    case Poison.decode(response.body) do
      {:ok, body} ->
        body

      _ ->
        {:error, response.body}
    end
  end
end
