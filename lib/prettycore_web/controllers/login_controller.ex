defmodule PrettycoreWeb.LoginController do
  use PrettycoreWeb, :controller
  alias Prettycore.Auth

  def create(conn, %{"username" => user, "password" => pass}) do
    case Auth.authenticate(user, pass) do
      {:ok, %{id: id}} ->
        conn
        # guarda ID real
        |> put_session(:user_id, id)
        # rotar session id
        |> configure_session(renew: true)
        |> redirect(to: ~p"/ui/platform")

      {:ok, _} ->
        conn
        # fallback si no tienes id
        |> put_session(:user_id, user)
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
