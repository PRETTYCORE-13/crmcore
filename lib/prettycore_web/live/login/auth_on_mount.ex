defmodule PrettycoreWeb.AuthOnMount do
  import Phoenix.LiveView, only: [redirect: 2]
  import Phoenix.Component, only: [assign: 3]
  import Ecto.Query
  alias Prettycore.Repo

  @impl true
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
        # Obtener el logo de la empresa
        company_logo = get_company_logo()

        {:cont,
         socket
         |> assign(:current_user_id, user_id)
         |> assign(:current_user_email, email_from_session)
         |> assign(:company_logo, company_logo)}
    end
  end

  defp get_company_logo do
    query = from e in "sys_empresa",
            select: e.sys_logo,
            limit: 1

    case Repo.one(query) do
      nil -> nil
      logo when is_binary(logo) ->
        # Si el logo viene en base64, asegurarse de que tenga el prefijo correcto
        if String.starts_with?(logo, "data:image") do
          logo
        else
          "data:image/png;base64,#{logo}"
        end
      _ -> nil
    end
  rescue
    _ -> nil
  end
end
