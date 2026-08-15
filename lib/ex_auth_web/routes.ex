defmodule ExAuthWeb.Routes do
  @moduledoc """
  ExAuthWeb.Routes can be used in a host Phoenix router as follows:

  ```elixir
  scope "/" do
    pipe_through [:api]

    use ExAuthWeb.Routes, scope: "/ex_auth"
  end
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
