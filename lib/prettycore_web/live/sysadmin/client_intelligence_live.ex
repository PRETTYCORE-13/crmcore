defmodule PrettycoreWeb.SysAdmin.ClientIntelligenceLive do
  use PrettycoreWeb, :live_view

  import PrettycoreWeb.SysAdminLayout

  alias Prettycore.ClientIntelligence

  @refresh_interval_ms 60_000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(@refresh_interval_ms, self(), :refresh)

    {:ok,
     socket
     |> assign(:current_page, "intelligence")
     |> assign(:log_limit, 50)
     |> load_data()}
  end

  @impl true
  def handle_info(:refresh, socket), do: {:noreply, load_data(socket)}

  @impl true
  def handle_event("load_more", _params, socket) do
    new_limit = socket.assigns.log_limit + 50
    {:noreply,
     socket
     |> assign(:log_limit, new_limit)
     |> assign(:detailed_events, ClientIntelligence.list_detailed_events(new_limit))}
  end

  # ── Helpers ──────────────────────────────────────────────────

  defp load_data(socket) do
    limit = socket.assigns[:log_limit] || 50
    socket
    |> assign(:stats, ClientIntelligence.global_stats())
    |> assign(:breakdown, ClientIntelligence.event_type_breakdown())
    |> assign(:top_clients, ClientIntelligence.list_most_active(10))
    |> assign(:detailed_events, ClientIntelligence.list_detailed_events(limit))
  end

  defp event_config("viewed"),   do: {"Vista",       "bg-blue-100 text-blue-700",    "👁"}
  defp event_config("edited"),   do: {"Editado",      "bg-violet-100 text-violet-700", "✏️"}
  defp event_config("created"),  do: {"Nuevo",        "bg-emerald-100 text-emerald-700","✚"}
  defp event_config("exported"), do: {"Excel",        "bg-amber-100 text-amber-700",  "⬇"}
  defp event_config("filtered"), do: {"Filtro",       "bg-cyan-100 text-cyan-700",    "⌕"}
  defp event_config(_),          do: {"Otro",         "bg-gray-100 text-gray-600",    "•"}

  defp breakdown_style("viewed"),   do: {"👁  Vistas",       "border-blue-200 bg-blue-50",   "text-blue-700"}
  defp breakdown_style("edited"),   do: {"✏️  Edits",        "border-violet-200 bg-violet-50","text-violet-700"}
  defp breakdown_style("created"),  do: {"✚  Nuevos",       "border-emerald-200 bg-emerald-50","text-emerald-700"}
  defp breakdown_style("exported"), do: {"⬇  Excel",        "border-amber-200 bg-amber-50",  "text-amber-700"}
  defp breakdown_style("filtered"), do: {"⌕  Filtros",      "border-cyan-200 bg-cyan-50",    "text-cyan-700"}

  defp score_bar_color(score) when score >= 70, do: "bg-emerald-500"
  defp score_bar_color(score) when score >= 30, do: "bg-amber-400"
  defp score_bar_color(_),                      do: "bg-gray-300"

  defp score_color(score) when score >= 70, do: "text-emerald-600"
  defp score_color(score) when score >= 30, do: "text-amber-600"
  defp score_color(_),                      do: "text-gray-400"

  defp relative_time(nil), do: "—"
  defp relative_time(dt) do
    diff = DateTime.diff(DateTime.utc_now(), dt, :second)
    cond do
      diff < 60    -> "hace #{diff}s"
      diff < 3600  -> "hace #{div(diff, 60)}min"
      diff < 86400 -> "hace #{div(diff, 3600)}h"
      true         -> "hace #{div(diff, 86400)}d"
    end
  end

  defp format_exact(nil), do: "—"
  defp format_exact(dt) do
    dt
    |> DateTime.shift_zone!("America/Mexico_City")
    |> Calendar.strftime("%d/%m/%Y %H:%M:%S")
  rescue
    _ -> "—"
  end

  defp format_metadata(%{} = m) when map_size(m) == 0, do: nil
  defp format_metadata(%{"field" => f, "value" => v}), do: "#{f}: #{v}"
  defp format_metadata(%{"nombre" => n}) when n != "", do: n
  defp format_metadata(%{"sysudn" => s, "ruta" => r}), do: "UDN #{s} · Ruta #{r}"
  defp format_metadata(%{"filename" => f}), do: f
  defp format_metadata(m), do: m |> Map.take(["field","value","nombre","sysudn","ruta","filename","button"]) |> Enum.map_join(", ", fn {k,v} -> "#{k}: #{v}" end)

  @impl true
  def render(assigns) do
    ~H"""
    <.sidebar current_page={@current_page} current_user_name={@current_user_name}>
      <div class="p-6 max-w-6xl">

        <!-- Header -->
        <div class="mb-6 flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold text-gray-900">Client Intelligence</h1>
            <p class="text-sm text-gray-500 mt-1">
              Log de actividad detallado. Se actualiza cada 60s.
            </p>
          </div>
          <div class="flex items-center gap-2 text-xs text-gray-400">
            <span class="inline-block w-2 h-2 rounded-full bg-blue-400 animate-pulse"></span>
            En vivo
          </div>
        </div>

        <!-- Stats globales -->
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 mb-6">
          <div class="bg-white rounded-2xl border border-gray-200 p-4 shadow-sm">
            <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide">Eventos hoy</p>
            <p class="text-3xl font-bold text-blue-600 mt-1"><%= @stats.events_today %></p>
          </div>
          <div class="bg-white rounded-2xl border border-gray-200 p-4 shadow-sm">
            <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide">Esta semana</p>
            <p class="text-3xl font-bold text-violet-600 mt-1"><%= @stats.events_week %></p>
          </div>
          <div class="bg-white rounded-2xl border border-gray-200 p-4 shadow-sm">
            <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide">Clientes únicos</p>
            <p class="text-3xl font-bold text-emerald-600 mt-1"><%= @stats.unique_clients_week %></p>
          </div>
          <div class="bg-white rounded-2xl border border-gray-200 p-4 shadow-sm">
            <p class="text-xs font-semibold text-gray-400 uppercase tracking-wide">Total histórico</p>
            <p class="text-3xl font-bold text-gray-700 mt-1"><%= @stats.total_events %></p>
          </div>
        </div>

        <!-- Breakdown por tipo de acción -->
        <div class="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden mb-6">
          <div class="px-5 py-3 border-b border-gray-100">
            <h2 class="text-sm font-semibold text-gray-700">Acciones por tipo</h2>
          </div>
          <div class="grid grid-cols-2 sm:grid-cols-5 divide-x divide-y sm:divide-y-0 divide-gray-100">
            <%= for type <- ~w(viewed edited created exported filtered) do %>
              <% {label, card_class, text_class} = breakdown_style(type) %>
              <% counts = Map.get(@breakdown, type, %{today: 0, week: 0}) %>
              <div class={"p-4 #{card_class}"}>
                <p class={"text-xs font-semibold #{text_class} mb-2"}><%= label %></p>
                <div class="flex items-end gap-3">
                  <div>
                    <p class="text-[10px] text-gray-400 uppercase">Hoy</p>
                    <p class={"text-2xl font-bold #{text_class}"}><%= counts.today %></p>
                  </div>
                  <div class="mb-0.5">
                    <p class="text-[10px] text-gray-400 uppercase">Semana</p>
                    <p class="text-sm font-semibold text-gray-500"><%= counts.week %></p>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">

          <!-- Top clientes activos (compacto) -->
          <div class="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
            <div class="px-5 py-3 border-b border-gray-100">
              <h2 class="text-sm font-semibold text-gray-700">Top clientes activos (30d)</h2>
            </div>
            <%= if @top_clients == [] do %>
              <div class="py-10 text-center text-gray-400 text-sm">Sin actividad aún.</div>
            <% else %>
              <ul class="divide-y divide-gray-50">
                <%= for {s, idx} <- Enum.with_index(@top_clients, 1) do %>
                  <li class="px-5 py-2.5 flex items-center gap-3">
                    <span class="text-xs font-bold text-gray-300 w-4"><%= idx %></span>
                    <div class="flex-1 min-w-0">
                      <p class="text-sm font-semibold text-gray-800 truncate"><%= s.client_code %></p>
                      <div class="flex items-center gap-2 mt-0.5">
                        <div class="flex-1 h-1 bg-gray-100 rounded-full overflow-hidden">
                          <div class={"h-full rounded-full #{score_bar_color(s.activity_score)}"} style={"width: #{s.activity_score}%"}></div>
                        </div>
                        <span class={"text-xs font-bold #{score_color(s.activity_score)}"}>
                          <%= s.activity_score %>
                        </span>
                      </div>
                    </div>
                    <div class="text-right text-[10px] text-gray-400 shrink-0">
                      <p><%= s.view_count_30d %> views</p>
                      <p><%= s.edit_count_30d %> edits</p>
                    </div>
                  </li>
                <% end %>
              </ul>
            <% end %>
          </div>

          <!-- Actividad reciente (mini feed) -->
          <div class="lg:col-span-2 bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
            <div class="px-5 py-3 border-b border-gray-100">
              <h2 class="text-sm font-semibold text-gray-700">Actividad reciente</h2>
            </div>
            <%= if @detailed_events == [] do %>
              <div class="py-10 text-center text-gray-400 text-sm">Sin actividad aún.</div>
            <% else %>
              <ul class="divide-y divide-gray-50 max-h-64 overflow-y-auto">
                <%= for event <- Enum.take(@detailed_events, 15) do %>
                  <% {label, badge_class, icon} = event_config(event.event_type) %>
                  <li class="px-5 py-2.5 flex items-center gap-3">
                    <span class={"text-xs font-semibold px-2 py-0.5 rounded-full #{badge_class} shrink-0"}>
                      <%= icon %> <%= label %>
                    </span>
                    <div class="flex-1 min-w-0">
                      <p class="text-sm font-semibold text-gray-800 truncate">
                        <%= if event.client_code == "*", do: "—", else: event.client_code %>
                      </p>
                      <p class="text-xs text-gray-400">
                        <%= if event.user, do: event.user.username, else: "—" %>
                        <%= if m = format_metadata(event.metadata), do: " · #{m}" %>
                      </p>
                    </div>
                    <span class="text-xs text-gray-400 shrink-0"><%= relative_time(event.inserted_at) %></span>
                  </li>
                <% end %>
              </ul>
            <% end %>
          </div>
        </div>

        <!-- Log detallado completo -->
        <div class="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
          <div class="px-5 py-3 border-b border-gray-100 flex items-center justify-between">
            <h2 class="text-sm font-semibold text-gray-700">
              Log detallado
              <span class="ml-2 text-xs text-gray-400 font-normal"><%= length(@detailed_events) %> entradas</span>
            </h2>
          </div>

          <!-- Móvil: cards -->
          <div class="sm:hidden divide-y divide-gray-100">
            <%= for event <- @detailed_events do %>
              <% {label, badge_class, icon} = event_config(event.event_type) %>
              <details class="group">
                <summary class="flex items-center gap-3 px-4 py-3 cursor-pointer list-none select-none">
                  <span class={"text-xs font-semibold px-2 py-0.5 rounded-full #{badge_class} shrink-0"}>
                    <%= icon %> <%= label %>
                  </span>
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-semibold text-gray-800 truncate">
                      <%= if event.client_code == "*", do: "—", else: event.client_code %>
                    </p>
                    <p class="text-xs text-gray-400"><%= if event.user, do: event.user.username, else: "—" %></p>
                  </div>
                  <div class="flex items-center gap-1 shrink-0">
                    <span class="text-xs text-gray-400"><%= relative_time(event.inserted_at) %></span>
                    <svg class="w-4 h-4 text-gray-300 transition-transform group-open:rotate-180" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <polyline points="6 9 12 15 18 9" />
                    </svg>
                  </div>
                </summary>
                <div class="px-4 pb-3 pt-1 bg-gray-50 grid grid-cols-2 gap-2 text-xs">
                  <div>
                    <p class="text-gray-400 uppercase font-semibold tracking-wide text-[10px]">Fecha y hora</p>
                    <p class="text-gray-700 font-mono"><%= format_exact(event.inserted_at) %></p>
                  </div>
                  <div>
                    <p class="text-gray-400 uppercase font-semibold tracking-wide text-[10px]">Cliente</p>
                    <p class="text-gray-700"><%= if event.client_code == "*", do: "Global", else: event.client_code %></p>
                  </div>
                  <%= if m = format_metadata(event.metadata) do %>
                    <div class="col-span-2">
                      <p class="text-gray-400 uppercase font-semibold tracking-wide text-[10px]">Detalle</p>
                      <p class="text-gray-700"><%= m %></p>
                    </div>
                  <% end %>
                </div>
              </details>
            <% end %>
          </div>

          <!-- Desktop: tabla completa -->
          <div class="hidden sm:block overflow-x-auto">
            <table class="w-full text-sm">
              <thead>
                <tr class="border-b border-gray-100 bg-gray-50">
                  <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide whitespace-nowrap">Fecha y hora</th>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">Acción</th>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">Usuario</th>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">Cliente</th>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">Detalle</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-50">
                <%= for event <- @detailed_events do %>
                  <% {label, badge_class, icon} = event_config(event.event_type) %>
                  <tr class="hover:bg-gray-50 transition-colors">
                    <td class="px-4 py-3 text-xs font-mono text-gray-500 whitespace-nowrap">
                      <%= format_exact(event.inserted_at) %>
                    </td>
                    <td class="px-4 py-3">
                      <span class={"inline-flex items-center gap-1 text-xs font-semibold px-2 py-0.5 rounded-full #{badge_class}"}>
                        <%= icon %> <%= label %>
                      </span>
                    </td>
                    <td class="px-4 py-3 text-sm text-gray-700">
                      <%= if event.user, do: event.user.username, else: "—" %>
                    </td>
                    <td class="px-4 py-3 text-sm font-mono text-gray-700">
                      <%= if event.client_code == "*", do: "—", else: event.client_code %>
                    </td>
                    <td class="px-4 py-3 text-xs text-gray-500">
                      <%= format_metadata(event.metadata) %>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>

          <!-- Cargar más -->
          <%= if length(@detailed_events) >= @log_limit do %>
            <div class="px-5 py-4 border-t border-gray-100 text-center">
              <button
                type="button"
                phx-click="load_more"
                class="text-sm font-semibold text-blue-600 hover:text-blue-800"
              >
                Cargar más entradas
              </button>
            </div>
          <% end %>
        </div>

      </div>
    </.sidebar>
    """
  end
end
