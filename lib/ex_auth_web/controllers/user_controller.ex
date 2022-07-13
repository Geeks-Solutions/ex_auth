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

  def new_password(conn, %{"new_password" => ""}),
    do: invalid_params(conn, "Please enter a valid password.")

  def new_password(conn, %{"token" => token, "new_password" => new_password}) do
    res = AuthAPI.new_password(%{"password" => new_password, "token" => token})

    res |> format_response(conn)
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
