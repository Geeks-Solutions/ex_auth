defmodule ExAuthWeb.UserController do
  use ExAuthWeb, :controller
  alias ExAuth.AuthAPI

  def login(conn, user) do
    AuthAPI.login(user)
    |> format_response(conn)
  end

  def register(conn, params) do
    AuthAPI.register(params)
    |> format_response(conn)
  end

  def verify_token(conn, %{"token" => token} = params) do
    AuthAPI.verify_token(token, Map.get(params, "type", "login"))
    |> format_response(conn)
  end

  def verify_token(conn, _params),
    do: invalid_params(conn, "Invalid params please provide a token, i.e. {token: value}")

  def reset_password(conn, params) do
    AuthAPI.reset_password(params)
    |> format_response(conn)
  end

  def new_password(conn, %{"token" => token, "new_password" => new_password}) do
    with %{"data" => %{"token" => _token, "user" => %{"user_id" => id}}} <-
           AuthAPI.verify_token(token, "reset"),
         resp <- AuthAPI.update_private_user(%{"password" => new_password}, id) do
      resp |> format_response(conn)
    else
      %{"error" => _error} = err ->
        err |> format_response(conn)
    end
  end

  # def update(conn, %{"user_id" => user_id, "user" => user}) do
  #   AuthAPI.update_user(user, user_id)
  #   |> format_response(conn)
  # end

  def update(conn, _),
    do: invalid_params(conn, "Invalid params please provide a token, i.e. {token: value}")

  def invalid_params(conn, error),
    do:
      conn
      |> put_status(400)
      |> put_view(ExAuthWeb.ErrorView)
      |> render("error.json", error: error)

  def format_response(resp, conn) do
    case resp do
      %{
        "data" => data
      } ->
        conn
        |> render(
          "data.json",
          data: data
        )

      %{"status" => "failed"} = response ->
        conn
        |> put_status(400)
        |> put_view(ExAuthWeb.ErrorView)
        |> render("error.json", error: response)

      error when is_binary(error) ->
        conn
        |> put_status(400)
        |> put_view(ExAuthWeb.ErrorView)
        |> render("error.json", error: error)

      error ->
        conn
        |> put_status(400)
        |> put_view(ExAuthWeb.ErrorView)
        |> render("error.json", error: "#{inspect(error)}")
    end
  end
end
