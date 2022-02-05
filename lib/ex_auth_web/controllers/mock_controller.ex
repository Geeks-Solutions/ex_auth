defmodule ExAuthWeb.MockController do
  use ExAuthWeb, :controller

  def login(conn, %{"email" => _email, "password" => _pass} = user) do
    return_success(conn, user)
  end

  def login(conn, _) do
    return_failure(conn)
  end

  def register(conn, %{"email" => _email, "password" => _pass} = user) do
    return_success(conn, user)
  end

  def register(conn, _) do
    return_failure(conn)
  end

  def verify_token(conn, %{"token" => "valid"}) do
    return_success(conn, %{"email" => "email"})
  end

  def verify_token(conn, %{"token" => "invalid"}) do
    return_failure(conn)
  end

  def reset_password(conn, %{"user" => "valid@email.com"} = user) do
    return_success(conn, user)
  end

  def reset_password(conn, %{"user" => "invalid"}) do
    return_failure(conn)
  end

  defp return_success(conn, user) do
    res = %{
      "data" => %{
        "user" => user,
        "token" => "Valid token in testing env"
      }
    }

    conn
    |> json(res)
  end

  defp return_failure(conn) do
    conn
    |> put_status(400)
    |> json(%{"status" => "failed", "error" => "some reason", "message" => "some message"})
  end
end
