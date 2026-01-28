defmodule PrettycoreWeb.Users.UsersCreateLive do
  use PrettycoreWeb, :live_view

  alias Prettycore.Auth
  alias Prettycore.Auth.AuthUser

  @impl true
  def mount(_params, _session, socket) do
    changeset = AuthUser.changeset(%AuthUser{}, %{})

    {:ok,
     socket
     |> assign(:page_title, "Crear Usuario")
     |> assign(:changeset, changeset)
     |> assign(:form, to_form(changeset))
     |> assign(:users, Auth.list_users())
     |> assign(:show_password, false)}
  end

  @impl true
  def handle_event("validate", %{"auth_user" => params}, socket) do
    changeset =
      %AuthUser{}
      |> AuthUser.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"auth_user" => params}, socket) do
    case Auth.create_user(params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Usuario creado exitosamente")
         |> assign(:form, to_form(AuthUser.changeset(%AuthUser{}, %{})))
         |> assign(:users, Auth.list_users())}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("toggle_password", _, socket) do
    {:noreply, assign(socket, show_password: !socket.assigns.show_password)}
  end

  @impl true
  def handle_event("toggle_active", %{"id" => id}, socket) do
    user = Auth.get_user(id)

    if user do
      case Auth.update_user(user, %{active: !user.active}) do
        {:ok, _} ->
          {:noreply,
           socket
           |> put_flash(:info, "Estado actualizado")
           |> assign(:users, Auth.list_users())}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Error al actualizar")}
      end
    else
      {:noreply, put_flash(socket, :error, "Usuario no encontrado")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-black py-10">
      <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
        <!-- Header -->
        <div class="mb-10 text-center">
          <div class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-zinc-900 border border-zinc-800 mb-4">
            <svg class="w-8 h-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
            </svg>
          </div>
          <h1 class="text-3xl font-bold text-white">Administrar Usuarios</h1>
          <p class="mt-2 text-zinc-500">Crear y gestionar usuarios del sistema</p>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <!-- Formulario de Crear Usuario -->
          <div class="bg-zinc-950 border border-zinc-800 rounded-2xl p-8 shadow-2xl">
            <div class="flex items-center space-x-3 mb-8">
              <div class="w-10 h-10 rounded-xl bg-zinc-900 border border-zinc-800 flex items-center justify-center">
                <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
                </svg>
              </div>
              <h2 class="text-xl font-semibold text-white">Crear Nuevo Usuario</h2>
            </div>

            <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-6">
              <!-- Username -->
              <div>
                <label for="username" class="block text-sm font-medium text-zinc-300 mb-2">
                  Usuario <span class="text-purple-500">*</span>
                </label>
                <div class="relative">
                  <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <svg class="h-5 w-5 text-zinc-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                  </div>
                  <input
                    type="text"
                    name="auth_user[username]"
                    id="username"
                    value={@form[:username].value}
                    class={"block w-full pl-10 pr-4 py-3 bg-black border rounded-xl text-white placeholder-zinc-600 focus:ring-2 focus:ring-purple-600 focus:border-transparent transition-all #{if @form[:username].errors != [], do: "border-red-500", else: "border-zinc-800"}"}
                    placeholder="nombre_usuario"
                    autocomplete="off"
                  />
                </div>
                <%= if @form[:username].errors != [] do %>
                  <p class="mt-2 text-sm text-red-400 flex items-center">
                    <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                      <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                    </svg>
                    <%= translate_error(hd(@form[:username].errors)) %>
                  </p>
                <% end %>
              </div>

              <!-- Usuario FROG -->
              <div>
                <label for="usuario_frog" class="block text-sm font-medium text-zinc-300 mb-2">
                  Usuario FROG
                </label>
                <div class="relative">
                  <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <svg class="h-5 w-5 text-zinc-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                  </div>
                  <input
                    type="text"
                    name="auth_user[usuario_frog]"
                    id="usuario_frog"
                    value={@form[:usuario_frog].value}
                    class="block w-full pl-10 pr-4 py-3 bg-black border border-zinc-800 rounded-xl text-white placeholder-zinc-600 focus:ring-2 focus:ring-purple-600 focus:border-transparent transition-all"
                    placeholder="Usuario FROG"
                    autocomplete="off"
                  />
                </div>
              </div>

              <!-- Email -->
              <div>
                <label for="email" class="block text-sm font-medium text-zinc-300 mb-2">
                  Email
                </label>
                <div class="relative">
                  <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <svg class="h-5 w-5 text-zinc-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                    </svg>
                  </div>
                  <input
                    type="email"
                    name="auth_user[email]"
                    id="email"
                    value={@form[:email].value}
                    class={"block w-full pl-10 pr-4 py-3 bg-black border rounded-xl text-white placeholder-zinc-600 focus:ring-2 focus:ring-purple-600 focus:border-transparent transition-all #{if @form[:email].errors != [], do: "border-red-500", else: "border-zinc-800"}"}
                    placeholder="usuario@ejemplo.com"
                    autocomplete="off"
                  />
                </div>
                <%= if @form[:email].errors != [] do %>
                  <p class="mt-2 text-sm text-red-400 flex items-center">
                    <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                      <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                    </svg>
                    <%= translate_error(hd(@form[:email].errors)) %>
                  </p>
                <% end %>
              </div>

              <!-- Password -->
              <div>
                <label for="password" class="block text-sm font-medium text-zinc-300 mb-2">
                  Contrasena <span class="text-purple-500">*</span>
                </label>
                <div class="relative">
                  <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <svg class="h-5 w-5 text-zinc-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                    </svg>
                  </div>
                  <input
                    type={if @show_password, do: "text", else: "password"}
                    name="auth_user[password]"
                    id="password"
                    value={@form[:password].value}
                    class={"block w-full pl-10 pr-12 py-3 bg-black border rounded-xl text-white placeholder-zinc-600 focus:ring-2 focus:ring-purple-600 focus:border-transparent transition-all #{if @form[:password].errors != [], do: "border-red-500", else: "border-zinc-800"}"}
                    placeholder="Minimo 6 caracteres"
                    autocomplete="new-password"
                  />
                  <button
                    type="button"
                    phx-click="toggle_password"
                    class="absolute inset-y-0 right-0 flex items-center pr-3 text-zinc-500 hover:text-white transition-colors"
                  >
                    <%= if @show_password do %>
                      <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                      </svg>
                    <% else %>
                      <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                      </svg>
                    <% end %>
                  </button>
                </div>
                <%= if @form[:password].errors != [] do %>
                  <p class="mt-2 text-sm text-red-400 flex items-center">
                    <svg class="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                      <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
                    </svg>
                    <%= translate_error(hd(@form[:password].errors)) %>
                  </p>
                <% end %>
              </div>

              <!-- Role -->
              <div>
                <label for="role" class="block text-sm font-medium text-zinc-300 mb-2">
                  Rol
                </label>
                <div class="relative">
                  <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <svg class="h-5 w-5 text-zinc-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                    </svg>
                  </div>
                  <select
                    name="auth_user[role]"
                    id="role"
                    class="block w-full pl-10 pr-4 py-3 bg-black border border-zinc-800 rounded-xl text-white focus:ring-2 focus:ring-purple-600 focus:border-transparent transition-all appearance-none cursor-pointer"
                  >
                    <option value="user" selected={@form[:role].value == "user"} class="bg-black">Usuario</option>
                    <option value="admin" selected={@form[:role].value == "admin"} class="bg-black">Administrador</option>
                  </select>
                  <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
                    <svg class="h-5 w-5 text-zinc-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                    </svg>
                  </div>
                </div>
              </div>

              <!-- Active -->
              <div class="flex items-center p-4 bg-zinc-900/50 rounded-xl border border-zinc-800">
                <input
                  type="checkbox"
                  name="auth_user[active]"
                  id="active"
                  value="true"
                  checked={@form[:active].value != false}
                  class="h-5 w-5 rounded border-zinc-700 bg-black text-purple-600 focus:ring-purple-600 focus:ring-offset-black cursor-pointer"
                />
                <label for="active" class="ml-3 block text-sm text-zinc-300 cursor-pointer">
                  Usuario activo
                </label>
                <span class="ml-auto">
                  <span class={"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{if @form[:active].value != false, do: "bg-green-500/10 text-green-400 border border-green-500/20", else: "bg-zinc-800 text-zinc-500 border border-zinc-700"}"}>
                    <%= if @form[:active].value != false, do: "Activo", else: "Inactivo" %>
                  </span>
                </span>
              </div>

              <!-- Submit Button -->
              <div class="pt-4">
                <button
                  type="submit"
                  class="w-full flex justify-center items-center py-3.5 px-4 border border-transparent rounded-xl text-sm font-semibold text-white bg-purple-600 hover:bg-purple-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-600 focus:ring-offset-black transition-all duration-200"
                >
                  <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                  </svg>
                  Crear Usuario
                </button>
              </div>
            </.form>
          </div>

          <!-- Lista de Usuarios -->
          <div class="bg-zinc-950 border border-zinc-800 rounded-2xl p-8 shadow-2xl">
            <div class="flex items-center justify-between mb-8">
              <div class="flex items-center space-x-3">
                <div class="w-10 h-10 rounded-xl bg-zinc-900 border border-zinc-800 flex items-center justify-center">
                  <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                  </svg>
                </div>
                <h2 class="text-xl font-semibold text-white">Usuarios Registrados</h2>
              </div>
              <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-zinc-900 text-zinc-400 border border-zinc-800">
                <%= length(@users) %> usuarios
              </span>
            </div>

            <%= if Enum.empty?(@users) do %>
              <div class="text-center py-12">
                <div class="w-16 h-16 rounded-full bg-zinc-900 border border-zinc-800 flex items-center justify-center mx-auto mb-4">
                  <svg class="w-8 h-8 text-zinc-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
                  </svg>
                </div>
                <p class="text-zinc-400">No hay usuarios registrados</p>
                <p class="text-zinc-600 text-sm mt-1">Crea el primer usuario usando el formulario</p>
              </div>
            <% else %>
              <div class="space-y-3 max-h-[500px] overflow-y-auto pr-2 custom-scrollbar">
                <%= for user <- @users do %>
                  <div class="group flex items-center justify-between p-4 bg-zinc-900/50 hover:bg-zinc-900 rounded-xl border border-zinc-800 hover:border-zinc-700 transition-all duration-200">
                    <div class="flex items-center space-x-4">
                      <div class={"w-12 h-12 rounded-xl flex items-center justify-center text-white font-bold text-lg #{if user.active, do: "bg-purple-600", else: "bg-zinc-700"}"}>
                        <%= String.first(user.username) |> String.upcase() %>
                      </div>
                      <div>
                        <p class="text-sm font-semibold text-white"><%= user.username %></p>
                        <p class="text-xs text-zinc-500 mt-0.5"><%= user.email || "Sin email" %></p>
                      </div>
                    </div>
                    <div class="flex items-center space-x-3">
                      <span class={"inline-flex items-center px-2.5 py-1 rounded-lg text-xs font-medium #{if user.role == "admin", do: "bg-purple-600/10 text-purple-400 border border-purple-600/20", else: "bg-zinc-800 text-zinc-500 border border-zinc-700"}"}>
                        <%= if user.role == "admin" do %>
                          <svg class="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M2.166 4.999A11.954 11.954 0 0010 1.944 11.954 11.954 0 0017.834 5c.11.65.166 1.32.166 2.001 0 5.225-3.34 9.67-8 11.317C5.34 16.67 2 12.225 2 7c0-.682.057-1.35.166-2.001zm11.541 3.708a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                          </svg>
                        <% end %>
                        <%= user.role %>
                      </span>
                      <button
                        type="button"
                        phx-click="toggle_active"
                        phx-value-id={user.id}
                        class={"relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-300 ease-in-out focus:outline-none focus:ring-2 focus:ring-purple-600 focus:ring-offset-2 focus:ring-offset-black #{if user.active, do: "bg-purple-600", else: "bg-zinc-700"}"}
                        title={if user.active, do: "Desactivar usuario", else: "Activar usuario"}
                      >
                        <span class={"pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow-lg ring-0 transition duration-300 ease-in-out #{if user.active, do: "translate-x-5", else: "translate-x-0"}"}></span>
                      </button>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>

        <!-- Footer -->
        <div class="mt-8 text-center">
          <p class="text-zinc-600 text-sm">
            Sistema de gestion de usuarios - PostgreSQL
          </p>
        </div>
      </div>
    </div>

    <style>
      .custom-scrollbar::-webkit-scrollbar {
        width: 6px;
      }
      .custom-scrollbar::-webkit-scrollbar-track {
        background: rgba(39, 39, 42, 0.3);
        border-radius: 3px;
      }
      .custom-scrollbar::-webkit-scrollbar-thumb {
        background: rgba(63, 63, 70, 0.8);
        border-radius: 3px;
      }
      .custom-scrollbar::-webkit-scrollbar-thumb:hover {
        background: rgba(82, 82, 91, 1);
      }
    </style>
    """
  end
end
