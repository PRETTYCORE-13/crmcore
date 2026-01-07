defmodule PrettycoreWeb.Inicio do
  use PrettycoreWeb, :live_view_admin

  import PrettycoreWeb.MenuLayout

  # Recibimos el :email desde la ruta /admin/platform/:email
  def mount(_params, session, socket) do
    current_path = "/admin/platform"

    {:ok,
     socket
     |> assign(:current_page, "inicio")
     |> assign(:sidebar_open, true)
     |> assign(:show_programacion_children, false)
     |> assign(:current_user_email, session["user_email"])
     |> assign(:current_path, current_path)}
  end

  ## Navegación centralizada con CASE (modelo recomendado)
  @impl true
  def handle_event("change_page", %{"id" => id}, socket) do
    email = socket.assigns.current_user_email

    case id do
      "toggle_sidebar" ->
        {:noreply, update(socket, :sidebar_open, &(not &1))}

      "inicio" ->
        {:noreply,
         socket
         |> assign(:current_page, "inicio")
         |> assign(:show_programacion_children, false)
         |> push_navigate(to: ~p"/admin/platform")}

      "programacion" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/programacion")}

      "programacion_sql" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/programacion/sql")}

      "workorder" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/workorder")}

      "clientes" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/clientes")}

      "config" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/configuracion")}

      _ ->
        {:noreply, socket}
    end
  end

  ## Render
  @impl true
  def render(assigns) do
    ~H"""
    <section>
      <header class="pc-page-header">
        <h1>Inicio</h1>

        <p>Resumen general de tu espacio PrettyCore.</p>

        <p class="pc-small-muted">
          Correo actual: {@current_user_email} <br /> URL actual: {@current_path}
        </p>
      </header>

      <div class="pc-page-grid">
        <div class="pc-page-card">
          <h2>Actividad reciente</h2>

          <p>Aquí puedes mostrar un resumen de lo último que pasó.</p>
        </div>

        <div class="pc-page-card">
          <h2>Accesos rápidos</h2>

          <p>Enlaces, dashboards o módulos frecuentes.</p>
        </div>
      </div>
    </section>
    """
  end
end
