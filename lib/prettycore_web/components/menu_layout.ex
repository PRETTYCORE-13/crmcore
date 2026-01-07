defmodule PrettycoreWeb.MenuLayout do
  use Phoenix.Component

  @menu [
    %{id: "inicio", label: "Inicio"},
    %{id: "programacion", label: "Programación"},
    %{id: "workorder", label: "Workorder"},
    %{id: "clientes", label: "Clientes"}
  ]

  # Props y slot
  attr :current_page, :string, required: true
  attr :menu_event, :string, default: "change_page"
  attr :show_programacion_children, :boolean, default: false
  attr :sidebar_open, :boolean, default: true
  attr :current_user_email, :string, default: nil
  slot :inner_block, required: true

  def sidebar(assigns) do
    assigns = assign(assigns, :menu_items, @menu)

    ~H"""
    <div class="pc-platform">
      <!-- Sidebar -->
      <aside class={"pc-platform-sidebar" <> if @sidebar_open, do: " pc-platform-sidebar-open", else: ""}>
        <!-- BLOQUE SUPERIOR -->
        <div class="pc-platform-sidebar-top-row">
          <!-- Logo PrettyCore -->
          <div class="pc-platform-logo-group mini">
            <img
              class="pc-platform-logo-img"
              src="https://prettycore.xyz/IMAGENES/Logo%20Prettycore%20(8).png"
              alt="PrettyCore logo"
            />
          </div>
          <!-- Logo Direem -->
          <div class="pc-platform-logo-group mini">
            <img
              class="pc-platform-logo-img"
              src="https://th.bing.com/th/id/R.7d592b78f7652da436b9ab21fc4fc25f?rik=g7VE7dZo6JaZrA&riu=http%3a%2f%2fgetwallpapers.com%2fwallpaper%2ffull%2f6%2f6%2f1%2f579397.jpg&ehk=WXw%2bNSZCri4XZrLylh33jyOiBetpiK2UKJLVW0%2bp5Fk%3d&risl=&pid=ImgRaw&r=0"
              alt="Direem Negocios logo"
            />
          </div>
          <!-- Toggle -->
          <button
            type="button"
            class="pc-menu-item pc-menu-toggle mini"
            phx-click={@menu_event}
            phx-value-id="toggle_sidebar"
          >
            <span class="pc-menu-item-icon">
              <%= if @sidebar_open do %>
                <svg viewBox="0 0 24 24">
                  <path
                    fill="currentColor"
                    d="M15 4a1 1 0 0 1 .7 1.7L11.4 10l4.3 4.3A1 1 0 1 1 14.3 16L9.6 11.3a1 1 0 0 1 0-1.4L14.3 5A1 1 0 0 1 15 4Z"
                  />
                </svg>
              <% else %>
                <svg viewBox="0 0 24 24">
                  <path
                    fill="currentColor"
                    d="M9 4a1 1 0 0 0-.7 1.7L12.6 10l-4.3 4.3A1 1 0 0 0 9.7 16l4.7-4.7a1 1 0 0 0 0-1.4L9.7 5A1 1 0 0 0 9 4Z"
                  />
                </svg>
              <% end %>
            </span>
          </button>
        </div>
        <!-- BLOQUE DE USUARIO -->
        <div class="pc-user-block">
          <!-- AVATAR -->
          <div class="pc-user-avatar">
            {((@current_user_email && String.first(@current_user_email)) || "?")
            |> String.upcase()}
          </div>
          <!-- TEXTO (oculto si sidebar está cerrado) -->
          <div class="pc-user-info">
            <div class="pc-user-name">{@current_user_email || "desconocido"}</div>
            
            <div class="pc-user-role">Usuario</div>
          </div>
        </div>
        <!-- CUERPO DEL MENÚ -->
        <div class="pc-platform-sidebar-body">
          <nav class="pc-platform-menu">
            <%= for item <- @menu_items do %>
              <button
                type="button"
                class={menu_item_class(menu_active?(item.id, @current_page))}
                phx-click={@menu_event}
                phx-value-id={item.id}
              >
                <span class="pc-menu-item-indicator" />
                <span class="pc-menu-item-icon"><.pc_icon name={item.id} /></span>
                <span class="pc-menu-item-label">{item.label}</span>
              </button>
              <%= if item.id == "programacion" and @show_programacion_children do %>
                <div class="pc-submenu">
                  <button
                    type="button"
                    class={submenu_item_class("programacion_sql", @current_page)}
                    phx-click={@menu_event}
                    phx-value-id="programacion_sql"
                  >
                    <span class="pc-submenu-item-icon"><.pc_icon name="programacion_sql" /></span>
                    <span class="pc-submenu-item-label">Herramienta SQL</span>
                  </button>
                </div>
              <% end %>
            <% end %>
          </nav>
          <!-- CONFIGURACIÓN -->
          <button
            type="button"
            class={menu_item_class(menu_active?("config", @current_page)) <> " pc-menu-item-bottom"}
            phx-click={@menu_event}
            phx-value-id="config"
          >
            <span class="pc-menu-item-indicator" />
            <span class="pc-menu-item-icon"><.pc_icon name="config" /></span>
            <span class="pc-menu-item-label">Configuración</span>
          </button>
          <!-- LOGOUT -->
          <.link
            href="/logout"
            class="pc-menu-item pc-menu-item-bottom"
            data-confirm="¿Cerrar sesión?"
          >
            <span class="pc-menu-item-indicator" />
            <span class="pc-menu-item-icon"><.pc_icon name="logout" /></span>
            <span class="pc-menu-item-label">Cerrar sesión</span>
          </.link>
        </div>
      </aside>
      <!-- CONTENIDO -->
      <main class="pc-platform-main">{render_slot(@inner_block)}</main>
    </div>
    """
  end

  ## ICONOS
  attr :name, :string, required: true

  def pc_icon(assigns) do
    ~H"""
    <%= case @name do %>
      <% "inicio" -> %>
        <svg viewBox="0 0 24 24">
          <path
            fill="currentColor"
            d="M10 21v-5h4v5h4.5c.8 0 1.5-.7 1.5-1.5V11l-8-6-8 6v8.5c0 .8.7 1.5 1.5 1.5H10Z"
          />
        </svg>
      <% "programacion" -> %>
        <svg viewBox="0 0 24 24">
          <path
            fill="currentColor"
            d="M4 4c-1.1 0-2 .9-2 2v8c0 1.1.9 2 2 2h6v2H8c-.6 0-1 .4-1 1s.4 1 1 1h8c.6 0 1-.4 1-1s-.4-1-1-1h-2v-2h6c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2H4Z"
          />
        </svg>
      <% "workorder" -> %>
        <svg viewBox="0 0 24 24">
          <path
            fill="currentColor"
            d="M8 3c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V8.5L13.5 3H8Z"
          />
        </svg>
      <% "clientes" -> %>
        <svg viewBox="0 0 24 24">
          <path
            fill="currentColor"
            d="M8 3c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V8.5L13.5 3H8Z"
          />
        </svg>
      <% "config" -> %>
        <svg viewBox="0 0 24 24">
          <path
            fill="currentColor"
            d="M10.7 2.3c.4-.6 1.2-.6 1.6 0l1 1.6c.2.3.5.5.9.6l1.8.5c.7.2 1.1.9.9 1.5l-.5 1.8c-.1.3 0 .7.3 1l1.4 1.4c.5.5.5 1.3 0 1.8l-1.4 1.4c-.3.3-.4.6-.3 1l.5 1.8c.2.7-.2 1.4-.9 1.5l-1.8.5c-.4.1-.7.3-.9.6l-1 1.6Z"
          />
        </svg>
      <% "programacion_sql" -> %>
        <svg viewBox="0 0 24 24">
          <path
            fill="currentColor"
            d="M12 3C7.6 3 4 4.3 4 6v12c0 1.7 3.6 3 8 3s8-1.3 8-3V6c0-1.7-3.6-3-8-3Z"
          />
        </svg>
      <% "logout" -> %>
        <svg viewBox="0 0 24 24">
          <path
            fill="currentColor"
            d="M10 4a1 1 0 0 1 1 1v3h2V5a3 3 0 0 0-3-3H7a3 3 0 0 0-3 3v14a3 3 0 0 0 3 3h3a3 3 0 0 0 3-3v-3h-2v3a1 1 0 0 1-1 1H7Z"
          />
        </svg>
      <% _ -> %>
        <svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="8" fill="currentColor" /></svg>
    <% end %>
    """
  end

  ## HELPERS
  defp menu_active?("programacion", current)
       when current in ["programacion", "programacion_sql"],
       do: true

  defp menu_active?(id, current), do: id == current

  defp menu_item_class(true), do: "pc-menu-item pc-menu-item-active"
  defp menu_item_class(false), do: "pc-menu-item"

  defp submenu_item_class(id, current),
    do: if(id == current, do: "pc-submenu-item pc-submenu-item-active", else: "pc-submenu-item")
end
