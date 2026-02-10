defmodule PrettycoreWeb.AuthOnMount do
  import Phoenix.LiveView, only: [redirect: 2]
  import Phoenix.Component, only: [assign: 3]

  alias Prettycore.Api.Client, as: Api
  require Logger

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

        {:cont,
         socket
         |> assign(:current_user_id, user_id)
         |> assign(:current_user_email, email_from_session)
         |> assign(:current_user_name, user_name)
         |> assign(:company_logo, company_logo)
         |> assign(:frog_token, frog_token)}
    end
  end

  defp get_company_logo(token) do
    # Primero buscar en caché
    case :persistent_term.get(:company_logo_cache, nil) do
      nil ->
        # No hay caché, consultar API
        logo = fetch_company_logo(token)
        if logo, do: :persistent_term.put(:company_logo_cache, logo)
        logo

      cached_logo ->
        cached_logo
    end
  end

  defp fetch_company_logo(token) do
    case Api.get_all("SYS_EMPRESA", token) do
      {:ok, [empresa | _]} ->
        logo = Map.get(empresa, "SYSEMP_LOGOTIPO")
        format_logo(logo)

      {:ok, empresa} when is_map(empresa) ->
        logo = Map.get(empresa, "SYSEMP_LOGOTIPO")
        format_logo(logo)

      {:error, reason} ->
        Logger.warning("No se pudo obtener logo de empresa: #{inspect(reason)}")
        nil
    end
  rescue
    e ->
      Logger.warning("Error al obtener logo de empresa: #{inspect(e)}")
      nil
  end

  defp format_logo(nil), do: nil
  defp format_logo(""), do: nil

  defp format_logo(logo) when is_binary(logo) do
    if String.starts_with?(logo, "data:image") do
      logo
    else
      "data:image/png;base64,#{logo}"
    end
  end

  defp format_logo(_), do: nil
end
