defmodule PrettycoreWeb.HealthController do
  use PrettycoreWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok", app: "prettycore"})
  end
end
