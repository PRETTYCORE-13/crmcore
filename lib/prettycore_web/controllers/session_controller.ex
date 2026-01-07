# lib/prettycore_web/controllers/session_controller.ex
defmodule PrettycoreWeb.SessionController do
  use PrettycoreWeb, :controller
  alias Prettycore.Auth

  def create(conn, %{"username" => user, "password" => pass}) do
    case Auth.authenticate(user, pass) do
      {:ok, user_struct} ->
        # Tomamos id y email de la estructura si existen,
        # y usamos el username como fallback.
        user_id =
          user_struct
          |> Map.get(:id, user)

        email =
          user_struct
          |> Map.get(:email, user)

        conn
        |> put_session(:user_id, user_id)
        |> put_session(:user_email, email)
        |> configure_session(renew: true)
        # Redirige a /admin/platform/<email>
        |> redirect(to: ~p"/admin/platform")

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Usuario o contraseña incorrectos")
        |> redirect(to: ~p"/")
    end
  end

  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/")
  end
end
