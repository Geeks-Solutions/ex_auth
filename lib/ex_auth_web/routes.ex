defmodule ExAuthWeb.Routes do
  @moduledoc """
  ExAuth.Routes must be used in your phoenix routes as follows:

  ```elixir
  use Media.Routes, scope: "/", pipe_through: [:browser, :authenticate]
  ```

  `:scope` defaults to `"/ex_auth"`

  `:pipe_through` defaults to ex_auth's `[:ex_auth_api]`, you can customize the pipeline as you want.

  The supported routes are:
  ```elixir
    post("/login", UserController, :login, as: :ex_auth)
    post("/register", UserController, :register, as: :ex_auth)
    post("/verify_token", UserController, :verify_token, as: :ex_auth)
    post("/reset_password", UserController, :reset_password, as: :ex_auth)
    put("/new_password", UserController, :new_password, as: :ex_auth)
  ```
  """

  # use Phoenix.Router

  defmacro __using__(options \\ []) do
    scoped = Keyword.get(options, :scope, "/ex_auth")
    custom_pipes = Keyword.get(options, :pipe_through, [])
    # browser_pipes = [:ex_auth_browser] ++ custom_pipes
    api_pipes = [:ex_auth_api] ++ custom_pipes

    quote do
      pipeline :ex_auth_browser do
        plug(:accepts, ["html", "json"])
        plug(:fetch_session)
        plug(:fetch_flash)
        plug(:protect_from_forgery)
        plug(:put_secure_browser_headers)
      end

      pipeline :ex_auth_api do
        plug(:accepts, ["json"])
      end

      scope unquote(scoped), ExAuthWeb do
        pipe_through(unquote(api_pipes))

        post("/login", UserController, :login, as: :ex_auth)
        post("/register", UserController, :register, as: :ex_auth)
        post("/verify_token", UserController, :verify_token, as: :ex_auth)
        post("/reset_password", UserController, :reset_password, as: :ex_auth)
        put("/new_password", UserController, :new_password, as: :ex_auth)
      end
    end
  end
end
