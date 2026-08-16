defmodule ExAuthWeb.Router do
  use ExAuthWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  use ExAuthWeb.Routes

  if Mix.env() == :test do
    scope "/mock/auth", ExAuthWeb do
      pipe_through :api

      post "/api/v1/project/:project_id/login", MockController, :login
      post "/api/v1/project/:project_id/register", MockController, :register
      post "/api/v1/project/:project_id/verify_token", MockController, :verify_token
      post "/api/v1/project/:project_id/reset_password", MockController, :reset_password
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", ExAuthWeb do
  #   pipe_through :api
  # end
end
