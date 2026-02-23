defmodule PrettycoreWeb.SysAdmin.ConfiguracionLive do
  use PrettycoreWeb, :live_view

  import PrettycoreWeb.SysAdminLayout

  alias Prettycore.SysAdmin
  alias Prettycore.Auth

  @impl true
  def mount(_params, _session, socket) do
    config = SysAdmin.get_config()

    {:ok,
     socket
     |> assign(:current_page, "configuracion")
     |> assign(:usuario, config.usuario || "")
     |> assign(:instancia, config.instancia || "")
     |> assign(:token, config.token || "")
     |> assign(:url, config.url || "")
     |> assign(:foto, config.foto || "")
     |> assign(:saved, false)
     |> assign(:error, nil)}
  end

  @impl true
  def handle_event("nav", %{"id" => "configuracion"}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("guardar", params, socket) do
    usuario   = String.trim(params["usuario"]   || "")
    instancia = String.trim(params["instancia"] || "")
    token     = String.trim(params["token"]     || "")
    url       = String.trim(params["url"]       || "")
    foto      = String.trim(params["foto"]      || "")
    password  = String.trim(params["password"]  || "")

    if instancia == "" or token == "" do
      {:noreply, assign(socket, :error, "Instancia y Token son obligatorios.")}
    else
      attrs = %{usuario: usuario, instancia: instancia, token: token, url: url, foto: foto}

      case SysAdmin.save_config(attrs) do
        {:ok, _config} ->
          password_result =
            if password != "" do
              case Auth.get_user_by_username("SYSADMIN") do
                nil  -> {:error, "Usuario SYSADMIN no encontrado"}
                user -> Auth.change_password(user, password)
              end
            else
              :ok
            end

          case password_result do
            res when res in [:ok] or (is_tuple(res) and elem(res, 0) == :ok) ->
              {:noreply,
               socket
               |> assign(:usuario, usuario)
               |> assign(:instancia, instancia)
               |> assign(:token, token)
               |> assign(:url, url)
               |> assign(:foto, foto)
               |> assign(:saved, true)
               |> assign(:error, nil)}

            {:error, reason} ->
              {:noreply,
               assign(socket, :error, "Config guardada, pero error al cambiar contraseña: #{inspect(reason)}")}
          end

        {:error, changeset} ->
          errors =
            Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
            |> Enum.map(fn {k, v} -> "#{k}: #{Enum.join(v, ", ")}" end)
            |> Enum.join("; ")

          {:noreply, assign(socket, :error, "Error al guardar: #{errors}")}
      end
    end
  end

  @impl true
  def handle_event("dismiss_saved", _, socket) do
    {:noreply, assign(socket, :saved, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.sidebar current_page={@current_page} current_user_name={@current_user_name}>
      <div class="p-8 max-w-2xl">
        <div class="mb-8">
          <h1 class="text-2xl font-bold text-gray-900">Configuración del sistema</h1>
          <p class="text-sm text-gray-500 mt-1">Ajusta los parámetros de conexión y cuenta.</p>
        </div>

        <%= if @saved do %>
          <div class="mb-6 flex items-center gap-3 bg-emerald-50 border border-emerald-200 text-emerald-800 rounded-xl px-4 py-3 text-sm">
            <svg class="w-4 h-4 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            Configuración guardada correctamente.
            <button type="button" phx-click="dismiss_saved" class="ml-auto text-emerald-600 hover:text-emerald-900">✕</button>
          </div>
        <% end %>

        <%= if @error do %>
          <div class="mb-6 bg-red-50 border border-red-200 text-red-700 rounded-xl px-4 py-3 text-sm">
            {@error}
          </div>
        <% end %>

        <form phx-submit="guardar" class="bg-white rounded-2xl border border-gray-200 shadow-sm divide-y divide-gray-100">

          <div class="p-5">
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1.5">Usuario</label>
            <input type="text" name="usuario" value={@usuario} placeholder="Usuario de la API"
              class="w-full text-sm rounded-lg border border-gray-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent transition" />
            <p class="mt-1 text-xs text-gray-400">Usuario para autenticación en la API.</p>
          </div>

          <div class="p-5">
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1.5">Instancia</label>
            <input type="text" name="instancia" value={@instancia} placeholder="https://api.ejemplo.com:1950/SP/EN_RESTHELPER"
              class="w-full text-sm rounded-lg border border-gray-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent transition" />
            <p class="mt-1 text-xs text-gray-400">URL base de la API REST.</p>
          </div>

          <div class="p-5">
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1.5">Token</label>
            <input type="text" name="token" value={@token} placeholder="Bearer token de servicio"
              class="w-full text-sm font-mono rounded-lg border border-gray-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent transition" />
            <p class="mt-1 text-xs text-gray-400">Token de autenticación para las llamadas a la API.</p>
          </div>

          <div class="p-5">
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1.5">URL</label>
            <input type="text" name="url" value={@url} placeholder="https://ejemplo.com"
              class="w-full text-sm rounded-lg border border-gray-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent transition" />
            <p class="mt-1 text-xs text-gray-400">URL pública de la aplicación.</p>
          </div>

          <div class="p-5">
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1.5">Foto / Logo (URL)</label>
            <input type="text" name="foto" value={@foto} placeholder="https://ejemplo.com/logo.png"
              class="w-full text-sm rounded-lg border border-gray-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent transition" />
            <p class="mt-1 text-xs text-gray-400">URL del logotipo de la empresa.</p>
          </div>

          <div class="p-5">
            <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1.5">Contraseña</label>
            <input type="password" name="password" value="" placeholder="Dejar vacío para no cambiar"
              class="w-full text-sm rounded-lg border border-gray-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-gray-900 focus:border-transparent transition" />
            <p class="mt-1 text-xs text-gray-400">Nueva contraseña del administrador.</p>
          </div>

          <div class="p-5 bg-gray-50 rounded-b-2xl flex justify-end">
            <button type="submit"
              class="px-6 py-2 bg-gray-900 text-white text-sm font-semibold rounded-xl hover:bg-black transition-colors">
              Guardar
            </button>
          </div>
        </form>
      </div>
    </.sidebar>
    """
  end
end
