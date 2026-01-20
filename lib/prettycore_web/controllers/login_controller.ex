defmodule PrettycoreWeb.LoginController do
  use PrettycoreWeb, :controller
  alias Prettycore.Auth

  def create(conn, %{"username" => username, "password" => password}) do
    case Auth.authenticate(username, password) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_session(:username, user.username)
        |> put_session(:user_role, user.role)
        |> configure_session(renew: true)
        |> redirect(to: ~p"/ui/platform")

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
