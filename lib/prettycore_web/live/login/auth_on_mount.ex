defmodule PrettycoreWeb.AuthOnMount do
  import Phoenix.LiveView, only: [redirect: 2]
  import Phoenix.Component, only: [assign: 3]

  alias Prettycore.Auth

  def on_mount(:ensure_authenticated, params, session, socket) do
    user_id = session["user_id"]
    email_from_session = session["user_email"]
    email_from_url = params["email"]

    cond do
      # Sin sesión → fuera
      is_nil(user_id) or is_nil(email_from_session) ->
        {:halt, redirect(socket, to: "/")}

      # El email en URL no coincide → lo mandamos a SU ruta correcta
      not is_nil(email_from_url) and email_from_url != email_from_session ->
        correct_path = "/admin/platform/#{email_from_session}"
        {:halt, redirect(socket, to: correct_path)}

      true ->
        # Obtener token FROG de la sesión
        frog_token = session["frog_token"]
        # Obtener el logo de la empresa desde la API
        company_logo = get_company_logo(frog_token)
        # Obtener nombre de usuario de la sesión
        user_name = session["user_name"]

        # Cargar permisos del usuario desde DB
        user = Auth.get_user(user_id)
        user_role = (user && user.role) || "user"
        user_permissions = (user && user.permissions) || ["inicio"]

        {:cont,
         socket
         |> assign(:current_user_id, user_id)
         |> assign(:current_user_email, email_from_session)
         |> assign(:current_user_name, user_name)
         |> assign(:company_logo, company_logo)
         |> assign(:frog_token, frog_token)
         |> assign(:user_role, user_role)
         |> assign(:user_permissions, user_permissions)}
    end
  end

  defp get_company_logo(_token) do
    :persistent_term.get(:company_logo_cache, nil)
  end
end
