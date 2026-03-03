defmodule PrettycoreWeb.WorkOrder do
  use PrettycoreWeb, :live_view

  import PrettycoreWeb.PlatformLayout
  alias Prettycore.Workorders
  alias Prettycore.WorkorderApi

  def mount(_params, _session, socket) do
    workorders = Workorders.list_enc()

    {:ok,
     socket
     |> assign(:current_page, "workorder")
     |> assign(:show_programacion_children, false)
     |> assign(:sidebar_open, true)
     |> assign(:workorders, workorders)
     |> assign(:open_key, nil)
     |> assign(:detalles, %{})
     |> assign(:filter, "por_aceptar")
     # filtros avanzados
     |> assign(:sysudn_filter, "")
     |> assign(:fecha_desde, "")
     |> assign(:fecha_hasta, "")
     |> assign(:usuario_filter, "")
     # drawer lateral
     |> assign(:filters_open, false)}
  end

  ## Navegación / toggle sidebar

  def handle_event("change_page", %{"id" => "toggle_sidebar"}, socket) do
    {:noreply, update(socket, :sidebar_open, fn open -> not open end)}
  end

  def handle_event("change_page", %{"id" => "inicio"}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/admin/platform")}
  end

  def handle_event("change_page", %{"id" => "programacion"}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/admin/programacion")}
  end

  def handle_event("change_page", %{"id" => "programacion_sql"}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/admin/programacion/sql")}
  end

  def handle_event("change_page", %{"id" => "workorder"}, socket) do
    {:noreply, socket}
  end

  def handle_event("change_page", _params, socket) do
    {:noreply, socket}
  end

  ## Cambiar estado (API Aceptar / Rechazar)

  def handle_event("cambiar_estado", %{"ref" => ref, "estado" => estado_str}, socket) do
    estado = String.to_integer(estado_str)

    case WorkorderApi.cambiar_estado(ref, estado) do
      {:ok, _body} ->
        workorders = Workorders.list_enc()
        {:noreply, assign(socket, :workorders, workorders)}

      {:error, reason} ->
        IO.inspect(reason, label: "error cambiar_estado")
        {:noreply, socket}
    end
  end

  ## Filtro básico (Todas / Pendientes)

  def handle_event("set_filter", %{"filter" => filter}, socket) do
    {:noreply, assign(socket, :filter, filter)}
  end

  ## Toggle drawer de filtros

  def handle_event("toggle_filters", _params, socket) do
    {:noreply, update(socket, :filters_open, fn open -> not open end)}
  end

  ## Filtros avanzados (UDN, rango de fechas, usuario)

  def handle_event("set_filters", params, socket) do
    {:noreply,
     socket
     |> assign(:sysudn_filter, Map.get(params, "sysudn", ""))
     |> assign(:fecha_desde, Map.get(params, "fecha_desde", ""))
     |> assign(:fecha_hasta, Map.get(params, "fecha_hasta", ""))
     |> assign(:usuario_filter, Map.get(params, "usuario", ""))}
  end

  ## Abrir / cerrar detalle

  def handle_event(
        "toggle_detalle",
        %{"sysudn" => sysudn, "systra" => systra, "serie" => serie, "folio" => folio},
        socket
      ) do
    key = "#{sysudn}|#{systra}|#{serie}|#{folio}"

    detalles_cache = socket.assigns.detalles

    detalles =
      Map.get(detalles_cache, key) ||
        Workorders.list_det(sysudn, systra, serie, folio)

    open_key =
      if socket.assigns.open_key == key do
        nil
      else
        key
      end

    {:noreply,
     socket
     |> assign(:detalles, Map.put(detalles_cache, key, detalles))
     |> assign(:open_key, open_key)}
  end

  ## Helpers

  defp image_src(nil), do: nil

  defp image_src(url) when is_binary(url) do
    trimmed = String.trim(url)
    if trimmed == "", do: nil, else: trimmed
  end

  defp filter_workorders(workorders, "todas"), do: workorders

  defp filter_workorders(workorders, "por_aceptar") do
    Enum.filter(workorders, &(&1.estado == 100))
  end

  defp filter_workorders(workorders, _), do: workorders

  ## Render

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.platform_shell
      current_page={@current_page}
      show_programacion_children={@show_programacion_children}
      sidebar_open={@sidebar_open}
    >
      <% base = filter_workorders(@workorders, @filter) %> <% sysudn_opts =
        @workorders
        |> Enum.map(& &1.sysudn)
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq() %> <% usuario_opts =
        @workorders
        |> Enum.map(&Map.get(&1, :usuario))
        |> Enum.reject(&(&1 in [nil, ""]))
        |> Enum.uniq() %> <% fecha_desde_date =
        case @fecha_desde do
          "" ->
            nil

          s ->
            case Date.from_iso8601(s) do
              {:ok, d} -> d
              _ -> nil
            end
        end %> <% fecha_hasta_date =
        case @fecha_hasta do
          "" ->
            nil

          s ->
            case Date.from_iso8601(s) do
              {:ok, d} -> d
              _ -> nil
            end
        end %> <% sysudn_filter = @sysudn_filter %> <% usuario_filter = @usuario_filter %> <% filtered =
        Enum.filter(base, fn w ->
          # UDN
          sysudn_ok =
            sysudn_filter == "" or w.sysudn == sysudn_filter

          # Usuario
          usuario_val = (Map.get(w, :usuario, "") || "") |> to_string()

          usuario_ok =
            usuario_filter == "" or usuario_val == usuario_filter

          # Fecha -> Date
          fecha =
            case Map.get(w, :fecha) do
              %NaiveDateTime{} = nd ->
                NaiveDateTime.to_date(nd)

              %DateTime{} = dt ->
                DateTime.to_date(dt)

              %Date{} = d ->
                d

              s when is_binary(s) ->
                s
                |> String.slice(0, 10)
                |> Date.from_iso8601()
                |> case do
                  {:ok, d} -> d
                  _ -> nil
                end

              _ ->
                nil
            end

          fecha_ok =
            cond do
              is_nil(fecha_desde_date) and is_nil(fecha_hasta_date) ->
                true

              is_nil(fecha) ->
                false

              true ->
                after_start =
                  is_nil(fecha_desde_date) or
                    Date.compare(fecha, fecha_desde_date) in [:eq, :gt]

                before_end =
                  is_nil(fecha_hasta_date) or
                    Date.compare(fecha, fecha_hasta_date) in [:eq, :lt]

                after_start and before_end
            end

          sysudn_ok and usuario_ok and fecha_ok
        end) %>
      <section class="wo-page">
        <header class="wo-header">
          <div class="wo-hero-main">
            <div class="wo-hero-icon">🛠️</div>

            <div>
              <h1 class="wo-title">Órdenes de trabajo</h1>

              <p class="wo-subtitle">Visualiza tus órdenes y las imágenes asociadas.</p>
            </div>
          </div>

          <div class="wo-header-right">
            <div class="wo-stats">
              <div class="wo-stat-card">
                <span class="wo-stat-label">Total de órdenes</span>
                <span class="wo-stat-value">{length(filtered)}</span>
              </div>
            </div>
            <!-- Botón debajo del total para abrir el menú lateral -->
            <button
              type="button"
              class={"wo-filters-toggle" <> if @filters_open, do: " wo-filters-toggle-open", else: ""}
              phx-click="toggle_filters"
            >
              <span class="wo-filters-toggle-icon">
                <svg viewBox="0 0 24 24" aria-hidden="true">
                  <path
                    fill="currentColor"
                    d="M5 7h14a1 1 0 0 1 0 2H5a1 1 0 0 1 0-2Zm3 5h8a1 1 0 0 1 0 2H8a1 1 0 0 1 0-2Zm3 5h2a1 1 0 0 1 0 2h-2a1 1 0 0 1 0-2Z"
                  />
                </svg>
              </span>
               <span class="wo-filters-toggle-text">Filtros</span>
            </button>
          </div>
        </header>
        <!-- Drawer lateral de filtros -->
        <div class={
            "wo-filters-drawer" <>
              if @filters_open, do: " wo-filters-drawer-open", else: ""
          }>
          <div class="wo-filters-drawer-header">
            <span class="wo-filters-drawer-title">Filtros</span>
            <button
              type="button"
              class="wo-filters-drawer-close"
              phx-click="toggle_filters"
            >
              ✕
            </button>
          </div>

          <form class="wo-filters-drawer-body" phx-change="set_filters">
            <!-- ESTADO: Todas / Pendientes -->
            <div class="wo-filter-field">
              <label class="wo-filter-label">Estado</label>
              <div class="wo-filters">
                <button
                  type="button"
                  class={"wo-filter-btn" <> if @filter == "todas", do: " wo-filter-btn-active", else: ""}
                  phx-click="set_filter"
                  phx-value-filter="todas"
                >
                  Todas
                </button>
                <button
                  type="button"
                  class={"wo-filter-btn" <> if @filter == "por_aceptar", do: " wo-filter-btn-active", else: ""}
                  phx-click="set_filter"
                  phx-value-filter="por_aceptar"
                >
                  Pendientes
                </button>
              </div>
            </div>

            <div class="wo-filter-field">
              <label class="wo-filter-label">UDN</label>
              <select name="sysudn" class="wo-filter-select">
                <option value="" selected={@sysudn_filter == ""}>Todas las UDN</option>

                <%= for opt <- sysudn_opts do %>
                  <option value={opt} selected={@sysudn_filter == opt}>{opt}</option>
                <% end %>
              </select>
            </div>

            <div class="wo-filter-field">
              <label class="wo-filter-label">Fecha desde</label>
              <input
                type="date"
                name="fecha_desde"
                class="wo-filter-date"
                value={@fecha_desde}
              />
            </div>

            <div class="wo-filter-field">
              <label class="wo-filter-label">Fecha hasta</label>
              <input
                type="date"
                name="fecha_hasta"
                class="wo-filter-date"
                value={@fecha_hasta}
              />
            </div>

            <div class="wo-filter-field">
              <label class="wo-filter-label">Usuario</label>
              <select name="usuario" class="wo-filter-select">
                <option value="" selected={@usuario_filter == ""}>Todos los usuarios</option>

                <%= for opt <- usuario_opts do %>
                  <option value={opt} selected={@usuario_filter == opt}>{opt}</option>
                <% end %>
              </select>
            </div>
          </form>
        </div>

        <div class="wo-table-card">
          <%= if filtered == [] do %>
            <div class="wo-empty">
              <div class="wo-empty-icon">📭</div>

              <h2 class="wo-empty-title">Sin órdenes registradas</h2>

              <p class="wo-empty-text">No hay órdenes para el filtro seleccionado.</p>
            </div>
          <% else %>
            <div class="wo-table-wrapper">
              <table class="wo-table">
                <thead>
                  <tr>
                    <th>Identificador</th>

                    <th>Descripción</th>

                    <th>Tipo</th>

                    <th class="wo-th-center">Acciones</th>
                  </tr>
                </thead>

                <tbody>
                  <%= for w <- filtered do %>
                    <% key = "#{w.sysudn}|#{w.systra}|#{w.serie}|#{w.folio}" %>
                    <!-- Fila principal -->
                    <tr
                      class={"wo-row" <> if @open_key == key, do: " wo-row-open", else: ""}
                      phx-click="toggle_detalle"
                      phx-value-sysudn={w.sysudn}
                      phx-value-systra={w.systra}
                      phx-value-serie={w.serie}
                      phx-value-folio={w.folio}
                    >
                      <td>{"#{w.sysudn} #{w.serie} #{w.folio}"}</td>

                      <td>{Map.get(w, :descripcion, "")}</td>

                      <td><span class="wo-row-meta-badge">{w.tipo}</span></td>

                      <td class="wo-td-center">
                        <%= if @filter != "todas" do %>
                          <button
                            type="button"
                            class="wo-btn wo-btn-accept"
                            phx-click="cambiar_estado"
                            phx-value-ref={w.referencia}
                            phx-value-estado="1"
                            phx-bubble="false"
                          >
                            Aceptar
                          </button>
                          <button
                            type="button"
                            class="wo-btn wo-btn-reject"
                            phx-click="cambiar_estado"
                            phx-value-ref={w.referencia}
                            phx-value-estado="0"
                            phx-bubble="false"
                          >
                            Rechazar
                          </button>
                        <% else %>
                          <span class="wo-disabled">—</span>
                        <% end %>
                      </td>
                    </tr>
                    <!-- Fila de detalles -->
                    <%= if @open_key == key do %>
                      <tr class="wo-row-detail">
                        <td colspan="4">
                          <div class="wo-detail-grid">
                            <% detalles = Map.get(@detalles, key, []) %> <% visibles =
                              Enum.filter(detalles, fn d ->
                                src = image_src(Map.get(d, :image_url))
                                not is_nil(src)
                              end) %>
                            <%= if visibles == [] do %>
                              <div class="wo-detail-img wo-detail-img-empty">Sin imágenes</div>
                            <% else %>
                              <%= for det <- visibles do %>
                                <% src = image_src(Map.get(det, :image_url)) %>
                                <div class="wo-detail-card">
                                  <div class="wo-detail-meta">
                                    <span class="wo-detail-label">
                                      {Map.get(det, :descripcion) ||
                                        Map.get(det, :concepto) ||
                                        "Detalle"}
                                    </span>
                                  </div>

                                  <img
                                    class="wo-detail-img"
                                    src={src}
                                    alt="Imagen de la orden"
                                  />
                                </div>
                              <% end %>
                            <% end %>
                          </div>
                        </td>
                      </tr>
                    <% end %>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>
      </section>
    </.platform_shell>
    """
  end
end
