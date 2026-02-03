defmodule PrettycoreWeb.MenuLayout do
  use Phoenix.Component

  @menu [
    %{id: "inicio", label: "Inicio"},
  #  %{id: "programacion", label: "Programación"},
    %{id: "workorder", label: "Workorder"},
    %{id: "clientes", label: "Clientes"}
  ]

  # Props y slot
  attr :current_page, :string, required: true
  attr :menu_event, :string, default: "change_page"
  attr :show_programacion_children, :boolean, default: false
  attr :sidebar_open, :boolean, default: true
  attr :current_user_email, :string, default: nil
  attr :current_user_name, :string, default: nil
  attr :company_logo, :string, default: nil
  slot :inner_block, required: true

  def sidebar(assigns) do
    assigns = assign(assigns, :menu_items, @menu)

    ~H"""
    <div class="pc-platform">
      <!-- Sidebar -->
      <aside class={"pc-platform-sidebar" <> if @sidebar_open, do: " pc-platform-sidebar-open", else: ""}>
        <!-- HEADER: Logo + nombre + toggle -->
        <div class="pc-sidebar-header">
          <div class="pc-sidebar-brand">
            <img
              src="https://prettycore.xyz/IMAGENES/PRETTYCORE.png"
              alt="PrettyCore"
              class="pc-sidebar-brand-full pc-sidebar-logo-open"
            />
            <img
              src="https://prettycore.xyz/IMAGENES/Logo%20Prettycore%20(8).png"
              alt="PrettyCore"
              class="pc-sidebar-brand-icon pc-sidebar-logo-closed"
            />
          </div>
          <button
            type="button"
            class="pc-sidebar-toggle"
            phx-click={@menu_event}
            phx-value-id="toggle_sidebar"
          >
            <%= if @sidebar_open do %>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="11 17 6 12 11 7" /><polyline points="18 17 13 12 18 7" />
              </svg>
            <% else %>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="13 17 18 12 13 7" /><polyline points="6 17 11 12 6 7" />
              </svg>
            <% end %>
          </button>
        </div>

        <!-- CUERPO DEL MENÚ -->
        <div class="pc-sidebar-body">
          <div>
            <!-- SECCIÓN: MENÚ -->
            <div class="pc-sidebar-section-label">Menú</div>
            <nav class="pc-sidebar-nav">
              <%= for item <- @menu_items do %>
                <button
                  type="button"
                  class={menu_item_class(menu_active?(item.id, @current_page))}
                  phx-click={@menu_event}
                  phx-value-id={item.id}
                >
                  <span class="pc-nav-icon"><.pc_icon name={item.id} /></span>
                  <span class="pc-nav-label">{item.label}</span>
                </button>
                <%= if item.id == "programacion" and @show_programacion_children do %>
                  <div class="pc-submenu">
                    <button
                      type="button"
                      class={submenu_item_class("programacion_sql", @current_page)}
                      phx-click={@menu_event}
                      phx-value-id="programacion_sql"
                    >
                      <span class="pc-submenu-dot" />
                      <span class="pc-nav-label">Herramienta SQL</span>
                    </button>
                  </div>
                <% end %>
              <% end %>
            </nav>
          </div>

          <!-- SECCIÓN INFERIOR -->
          <div>
            <div class="pc-sidebar-section-label">Cuenta</div>
            <nav class="pc-sidebar-nav">
              <!-- USUARIO -->
              <div class="pc-sidebar-user">
                <div class="pc-sidebar-user-avatar">
                  <%= if @company_logo do %>
                    <img src={@company_logo} alt="Logo" class="pc-sidebar-user-avatar-img" />
                  <% else %>
                    {((@current_user_name && String.first(@current_user_name)) || "?") |> String.upcase()}
                  <% end %>
                </div>
                <span class="pc-nav-label">{@current_user_name || "Usuario"}</span>
              </div>
              <!-- LOGOUT -->
              <.link
                href="/logout"
                class="pc-nav-item pc-nav-logout"
                data-confirm="¿Cerrar sesión?"
              >
                <span class="pc-nav-icon"><.pc_icon name="logout" /></span>
                <span class="pc-nav-label">Cerrar sesión</span>
              </.link>
            </nav>
          </div>
        </div>
      </aside>
      <!-- CONTENIDO -->
      <main class="pc-platform-main">{render_slot(@inner_block)}</main>
    </div>
    """
  end

  ## ICONOS — outline style
  attr :name, :string, required: true

  def pc_icon(assigns) do
    ~H"""
    <%= case @name do %>
      <% "inicio" -> %>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
          <path d="M3 9.5L12 4l9 5.5" />
          <path d="M19 13v6a1 1 0 0 1-1 1h-4v-5h-4v5H6a1 1 0 0 1-1-1v-6" />
        </svg>
      <% "programacion" -> %>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
          <rect x="2" y="3" width="20" height="14" rx="2" />
          <line x1="8" y1="21" x2="16" y2="21" />
          <line x1="12" y1="17" x2="12" y2="21" />
        </svg>
      <% "workorder" -> %>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
          <path d="M9 5H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2" />
          <rect x="9" y="3" width="6" height="4" rx="1" />
          <line x1="9" y1="12" x2="15" y2="12" />
          <line x1="9" y1="16" x2="13" y2="16" />
        </svg>
      <% "clientes" -> %>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
          <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
          <circle cx="9" cy="7" r="4" />
          <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
          <path d="M16 3.13a4 4 0 0 1 0 7.75" />
        </svg>
      <% "config" -> %>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="12" cy="12" r="3" />
          <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" />
        </svg>
      <% "programacion_sql" -> %>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
          <ellipse cx="12" cy="5" rx="9" ry="3" />
          <path d="M21 12c0 1.66-4 3-9 3s-9-1.34-9-3" />
          <path d="M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3V5" />
        </svg>
      <% "logout" -> %>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
          <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
          <polyline points="16 17 21 12 16 7" />
          <line x1="21" y1="12" x2="9" y2="12" />
        </svg>
      <% _ -> %>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
          <circle cx="12" cy="12" r="8" />
        </svg>
    <% end %>
    """
  end

  ## HELPERS
  defp menu_active?("programacion", current)
       when current in ["programacion", "programacion_sql"],
       do: true

  defp menu_active?(id, current), do: id == current

  defp menu_item_class(true), do: "pc-nav-item pc-nav-item-active"
  defp menu_item_class(false), do: "pc-nav-item"

  defp submenu_item_class(id, current),
    do: if(id == current, do: "pc-submenu-item pc-submenu-item-active", else: "pc-submenu-item")
end
