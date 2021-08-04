defmodule ExAuthWeb.UserView do
  use ExAuthWeb, :view

  def render("data.json", %{data: data}) do
    data
  end
end
