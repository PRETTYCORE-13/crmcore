defmodule PrettycoreWeb.PageController do
  use PrettycoreWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
