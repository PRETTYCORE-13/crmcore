defmodule PrettycoreWeb.Tienda do
  use PrettycoreWeb, :live_view_admin

  alias Prettycore.Productos

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:current_page, "tienda")
      |> assign(:sidebar_open, true)
      |> assign(:show_programacion_children, false)
      |> assign(:productos, [])
      |> assign(:loading, true)
      |> assign(:syncing, false)
      |> assign(:search, "")

    if connected?(socket) do
      send(self(), :load_productos)
    end

    {:ok, socket}
  end

  @impl true
  def handle_info(:load_productos, socket) do
    productos = Productos.list_productos()
    {:noreply, assign(socket, productos: productos, loading: false)}
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    productos = Productos.search_productos(q)
    {:noreply, assign(socket, search: q, productos: productos)}
  end

  @impl true
  def handle_event("sync", _, socket) do
    socket = assign(socket, syncing: true)
    send(self(), :do_sync)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:do_sync, socket) do
    case Productos.sync_from_api() do
      {:ok, count} ->
        productos = Productos.list_productos()
        {:noreply,
         socket
         |> assign(syncing: false, productos: productos, search: "")
         |> put_flash(:info, "#{count} productos sincronizados")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(syncing: false)
         |> put_flash(:error, "Error al sincronizar productos")}
    end
  end

  @impl true
  def handle_event("change_page", %{"id" => id}, socket) do
    case id do
      "toggle_sidebar" -> {:noreply, update(socket, :sidebar_open, &(not &1))}
      "inicio" -> {:noreply, push_navigate(socket, to: ~p"/admin/platform")}
      "clientes" -> {:noreply, push_navigate(socket, to: ~p"/admin/clientes")}
      "tienda" -> {:noreply, socket}
      "usuarios" -> {:noreply, push_navigate(socket, to: ~p"/admin/usuarios")}
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="p-3 sm:p-6 max-w-7xl mx-auto min-h-screen bg-gray-50">
      <!-- Header -->
      <header class="mb-6">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold text-gray-900">Tienda</h1>
            <p class="text-sm text-gray-500 mt-0.5">Catálogo de productos</p>
          </div>
          <div class="flex items-center gap-3">
            <%= if not @loading do %>
              <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-white text-gray-500 border border-gray-200">
                <%= length(@productos) %> productos
              </span>
            <% end %>
            <button
              phx-click="sync"
              disabled={@syncing}
              class={"inline-flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-medium transition-all #{if @syncing, do: "bg-gray-100 text-gray-400 cursor-not-allowed", else: "bg-purple-600 text-white hover:bg-purple-500"}"}
            >
              <svg class={"w-4 h-4 #{if @syncing, do: "animate-spin"}"} fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
              </svg>
              <%= if @syncing, do: "Sincronizando...", else: "Sincronizar" %>
            </button>
          </div>
        </div>
      </header>

      <!-- Search -->
      <%= if not @loading do %>
        <div class="mb-6">
          <div class="relative max-w-sm">
            <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <svg class="h-4 w-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>
            <input
              type="text"
              phx-keyup="search"
              name="q"
              value={@search}
              placeholder="Buscar por nombre, código o marca..."
              class="block w-full pl-9 pr-4 py-2 bg-white border border-gray-300 rounded-xl text-sm text-gray-900 placeholder-gray-400 focus:ring-2 focus:ring-purple-600 focus:border-transparent transition-all"
            />
          </div>
        </div>
      <% end %>

      <!-- Loading -->
      <%= if @loading do %>
        <div class="flex flex-col items-center justify-center py-24 text-gray-400">
          <svg class="animate-spin h-8 w-8 mb-3 text-purple-500" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
          </svg>
          <p class="text-sm">Cargando productos...</p>
        </div>
      <% else %>
        <%= if Enum.empty?(@productos) do %>
          <div class="text-center py-20 text-gray-400">
            <svg class="w-10 h-10 mx-auto mb-3 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4zM3 6h18M16 10a4 4 0 01-8 0" />
            </svg>
            <p class="text-sm font-medium">Sin productos</p>
            <p class="text-xs mt-1">Presiona "Sincronizar" para actualizar la lista de productos</p>
          </div>
        <% else %>
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
            <%= for producto <- @productos do %>
              <div class="bg-white border border-gray-200 rounded-2xl p-5 hover:shadow-md hover:border-purple-200 transition-all duration-200">
                <div class="flex items-start justify-between mb-3">
                  <div class={"w-10 h-10 rounded-xl flex items-center justify-center text-white text-sm font-bold flex-shrink-0 #{if producto.activo, do: "bg-purple-600", else: "bg-gray-300"}"}>
                    <%= producto.codigo |> String.first() |> String.upcase() %>
                  </div>
                  <span class={"inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium #{if producto.activo, do: "bg-green-50 text-green-600 border border-green-200", else: "bg-gray-100 text-gray-400 border border-gray-200"}"}>
                    <%= if producto.activo, do: "Activo", else: "Inactivo" %>
                  </span>
                </div>

                <h3 class="text-sm font-semibold text-gray-900 leading-tight mb-1 line-clamp-2">
                  <%= producto.descripcion %>
                </h3>
                <p class="text-xs text-gray-400 mb-3"><%= producto.desc_corta %></p>

                <div class="space-y-1 text-xs border-t border-gray-100 pt-3">
                  <div class="flex justify-between">
                    <span class="text-gray-400">Código</span>
                    <span class="font-mono font-medium text-gray-700"><%= producto.codigo %></span>
                  </div>
                  <%= if producto.marca && producto.marca != "" do %>
                    <div class="flex justify-between">
                      <span class="text-gray-400">Marca</span>
                      <span class="font-medium text-gray-700"><%= producto.marca %></span>
                    </div>
                  <% end %>
                  <%= if producto.iva && producto.iva != 0.0 do %>
                    <div class="flex justify-between">
                      <span class="text-gray-400">IVA</span>
                      <span class="font-medium text-gray-700"><%= producto.iva %>%</span>
                    </div>
                  <% end %>
                  <div class="flex justify-between">
                    <span class="text-gray-400">Mín. venta</span>
                    <span class="font-medium text-gray-700"><%= producto.pzas_min_vta %> pza</span>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      <% end %>
    </section>
    """
  end
end
