defmodule PrettycoreWeb.Plugs.TrackSession do
  @moduledoc """
  En cada request HTTP:
  - Si la sesión fue cerrada a la fuerza (sysadmin), invalida la cookie y redirige al login.
  - Si la sesión está activa, toca last_seen_at (máximo cada 5 min para no saturar DB).
  """
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]
  alias Prettycore.Auth

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :session_token) do
      nil -> conn
      token ->
        case Auth.check_and_touch_session(token) do
          :force_closed ->
            conn
            |> configure_session(drop: true)
            |> redirect(to: "/")
            |> halt()

          _ -> conn
        end
    end
  end
end
