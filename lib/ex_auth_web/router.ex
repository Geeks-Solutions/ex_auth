defmodule ExAuthWeb.Router do
  use ExAuthWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ExAuthWeb do
    pipe_through :browser

    get "/", PageController, :index
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
