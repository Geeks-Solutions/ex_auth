defmodule ExAuthWeb.PageController do
  use ExAuthWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
