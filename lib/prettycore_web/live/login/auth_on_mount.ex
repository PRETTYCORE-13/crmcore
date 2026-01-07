defmodule PrettycoreWeb.AuthOnMount do
  import Phoenix.LiveView, only: [redirect: 2]
  import Phoenix.Component, only: [assign: 3]

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
        {:cont,
         socket
         |> assign(:current_user_id, user_id)
         |> assign(:current_user_email, email_from_session)}
    end
  end
end
