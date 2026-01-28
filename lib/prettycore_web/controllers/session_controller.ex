# lib/prettycore_web/controllers/session_controller.ex
defmodule PrettycoreWeb.SessionController do
  use PrettycoreWeb, :controller
  alias Prettycore.Auth
  alias Prettycore.Api.Client, as: Api
  require Logger

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

        # Obtener token FROG si el usuario tiene usuario_frog configurado
        frog_token = get_frog_token(user_struct)

        conn
        |> put_session(:user_id, user_id)
        |> put_session(:user_email, email)
        |> put_session(:frog_token, frog_token)
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

  defp get_frog_token(user_struct) do
    usuario_frog = Map.get(user_struct, :usuario_frog)

    if usuario_frog && usuario_frog != "" do
      case Api.get_frog_credentials(usuario_frog) do
        {:ok, token} ->
          Logger.info("FROG token obtenido para usuario: #{usuario_frog}")
          token

        {:error, reason} ->
          Logger.warning("No se pudo obtener FROG token: #{inspect(reason)}")
          nil
      end
    else
      nil
    end
  end
end
