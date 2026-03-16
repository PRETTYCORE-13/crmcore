defmodule PrettycoreWeb.SysAdmin.SchedulerLive do
  use PrettycoreWeb, :live_view

  import PrettycoreWeb.SysAdminLayout

  alias Prettycore.Scheduler
  alias Prettycore.Scheduler.{TaskScheduler, DynamicScheduler}

  @impl true
  def mount(_params, _session, socket) do
    tasks = Scheduler.list_tasks()
    logs  = Scheduler.list_recent_logs(50)

    {:ok,
     socket
     |> assign(:current_page, "scheduler")
     |> assign(:tasks, tasks)
     |> assign(:logs, logs)
     |> assign(:view, :tasks)
     |> assign(:selected_task, nil)
     |> assign(:form, nil)
     |> assign(:form_mode, nil)
     |> assign(:flash_msg, nil)}
  end

  # ── Navegación ────────────────────────────────────────────────

  @impl true
  def handle_event("set_view", %{"view" => "tasks"}, socket) do
    {:noreply, socket |> assign(:view, :tasks) |> assign(:selected_task, nil) |> assign(:form, nil)}
  end

  def handle_event("set_view", %{"view" => "logs"}, socket) do
    logs = Scheduler.list_recent_logs(100)
    {:noreply, socket |> assign(:view, :logs) |> assign(:logs, logs) |> assign(:form, nil)}
  end

  # ── CRUD ──────────────────────────────────────────────────────

  def handle_event("new_task", _, socket) do
    changeset = Scheduler.change_task(%TaskScheduler{})
    {:noreply, socket |> assign(:form, to_form(changeset)) |> assign(:form_mode, :new) |> assign(:selected_task, nil)}
  end

  def handle_event("edit_task", %{"id" => id}, socket) do
    task = Scheduler.get_task!(id)
    changeset = Scheduler.change_task(task)
    {:noreply, socket |> assign(:form, to_form(changeset)) |> assign(:form_mode, :edit) |> assign(:selected_task, task)}
  end

  def handle_event("cancel_form", _, socket) do
    {:noreply, socket |> assign(:form, nil) |> assign(:form_mode, nil) |> assign(:selected_task, nil)}
  end

  def handle_event("save_task", %{"task_scheduler" => params}, socket) do
    result =
      case socket.assigns.form_mode do
        :new  -> Scheduler.create_task(params)
        :edit -> Scheduler.update_task(socket.assigns.selected_task, params)
      end

    case result do
      {:ok, _task} ->
        DynamicScheduler.reload_tasks()
        tasks = Scheduler.list_tasks()

        {:noreply,
         socket
         |> assign(:tasks, tasks)
         |> assign(:form, nil)
         |> assign(:form_mode, nil)
         |> assign(:selected_task, nil)
         |> assign(:flash_msg, {:ok, "Tarea guardada correctamente"})}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("delete_task", %{"id" => id}, socket) do
    task = Scheduler.get_task!(id)
    Scheduler.delete_task(task)
    DynamicScheduler.reload_tasks()
    tasks = Scheduler.list_tasks()

    {:noreply,
     socket
     |> assign(:tasks, tasks)
     |> assign(:flash_msg, {:ok, "Tarea eliminada"})}
  end

  def handle_event("toggle_enabled", %{"id" => id}, socket) do
    task = Scheduler.get_task!(id)
    {:ok, _} = Scheduler.update_task(task, %{enabled: !task.enabled})
    DynamicScheduler.reload_tasks()
    tasks = Scheduler.list_tasks()
    {:noreply, assign(socket, :tasks, tasks)}
  end

  def handle_event("run_now", %{"id" => id}, socket) do
    Task.start(fn -> Prettycore.Scheduler.Worker.run(id) end)
    {:noreply, assign(socket, :flash_msg, {:info, "Tarea ejecutada manualmente"})}
  end

  def handle_event("view_logs", %{"id" => id}, socket) do
    task = Scheduler.get_task!(id)
    logs = Scheduler.list_logs_for_task(id, 50)
    {:noreply, socket |> assign(:view, :task_logs) |> assign(:selected_task, task) |> assign(:logs, logs)}
  end

  def handle_event("dismiss_flash", _, socket) do
    {:noreply, assign(socket, :flash_msg, nil)}
  end

  # ── Render ────────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    ~H"""
    <.sidebar current_page={@current_page} current_user_name={@current_user_name}>
      <div class="p-8 max-w-6xl">

        <!-- Header -->
        <div class="mb-6 flex items-start justify-between gap-4 flex-wrap">
          <div>
            <h1 class="text-2xl font-bold text-gray-900">Scheduler / Extractor</h1>
            <p class="text-sm text-gray-500 mt-1">Tareas programadas de extracción de datos via HTTP.</p>
          </div>
          <%= if @view == :tasks and is_nil(@form) do %>
            <button
              type="button"
              phx-click="new_task"
              class="flex items-center gap-2 px-4 py-2 bg-gray-900 text-white text-sm font-semibold rounded-xl hover:bg-gray-700 transition-colors"
            >
              + Nueva tarea
            </button>
          <% end %>
        </div>

        <!-- Flash -->
        <%= if @flash_msg do %>
          <% {kind, msg} = @flash_msg %>
          <div class={"mb-4 flex items-center justify-between px-4 py-3 rounded-xl text-sm font-medium border " <>
            if kind == :ok, do: "bg-emerald-50 text-emerald-700 border-emerald-200",
                            else: "bg-blue-50 text-blue-700 border-blue-200"}>
            <span><%= msg %></span>
            <button type="button" phx-click="dismiss_flash" class="ml-4 text-current opacity-50 hover:opacity-100">✕</button>
          </div>
        <% end %>

        <!-- Tabs -->
        <div class="flex gap-2 mb-6 border-b border-gray-200">
          <%= for {label, view} <- [{"Tareas", "tasks"}, {"Logs recientes", "logs"}] do %>
            <button
              type="button"
              phx-click="set_view"
              phx-value-view={view}
              class={"pb-3 px-1 text-sm font-semibold border-b-2 transition-colors " <>
                if to_string(@view) == view or (@view == :task_logs and view == "tasks"),
                  do: "border-gray-900 text-gray-900",
                  else: "border-transparent text-gray-400 hover:text-gray-700"}
            >
              <%= label %>
            </button>
          <% end %>
        </div>

        <!-- Vista: formulario -->
        <%= if @form do %>
          <div class="bg-white border border-gray-200 rounded-2xl shadow-sm p-6 max-w-2xl">
            <h2 class="text-lg font-bold text-gray-900 mb-5">
              <%= if @form_mode == :new, do: "Nueva tarea", else: "Editar tarea" %>
            </h2>
            <.form for={@form} phx-submit="save_task" class="space-y-4">
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div class="sm:col-span-2">
                  <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Nombre *</label>
                  <.input field={@form[:name]} type="text" placeholder="Ej: Ventas diarias" class="w-full" />
                </div>
                <div class="sm:col-span-2">
                  <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Descripción</label>
                  <.input field={@form[:description]} type="text" placeholder="Descripción opcional" class="w-full" />
                </div>
                <div>
                  <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Expresión Cron *</label>
                  <.input field={@form[:cron_expression]} type="text" placeholder="* * * * *" class="w-full font-mono" />
                  <p class="text-xs text-gray-400 mt-1">min hora día mes dow  —  Ej: <code>0 6 * * *</code> = cada día a las 6am</p>
                </div>
                <div>
                  <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Tabla destino *</label>
                  <.input field={@form[:target_table]} type="text" placeholder="ext_ventas" class="w-full font-mono" />
                  <p class="text-xs text-gray-400 mt-1">Solo letras minúsculas, números y _</p>
                </div>
                <div class="sm:col-span-2">
                  <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">URL *</label>
                  <.input field={@form[:url]} type="text" placeholder="https://api.ejemplo.com/datos" class="w-full" />
                </div>
                <div>
                  <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Método HTTP</label>
                  <.input field={@form[:method]} type="select" options={["GET", "POST", "PUT"]} class="w-full" />
                </div>
                <div>
                  <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Habilitada</label>
                  <.input field={@form[:enabled]} type="checkbox" />
                </div>
                <div class="sm:col-span-2">
                  <label class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Body (JSON opcional)</label>
                  <.input field={@form[:body]} type="textarea" placeholder='{"key": "value"}' rows="3" class="w-full font-mono text-xs" />
                </div>
              </div>
              <div class="flex gap-3 pt-2">
                <button type="submit"
                  class="px-5 py-2 bg-gray-900 text-white text-sm font-semibold rounded-xl hover:bg-gray-700 transition-colors">
                  Guardar
                </button>
                <button type="button" phx-click="cancel_form"
                  class="px-5 py-2 bg-gray-100 text-gray-700 text-sm font-semibold rounded-xl hover:bg-gray-200 transition-colors">
                  Cancelar
                </button>
              </div>
            </.form>
          </div>

        <!-- Vista: lista de tareas -->
        <% else %>
          <%= if @view in [:tasks] do %>
            <%= if @tasks == [] do %>
              <div class="py-20 text-center text-gray-400 text-sm">
                No hay tareas configuradas. Crea la primera con el botón de arriba.
              </div>
            <% else %>
              <div class="space-y-3">
                <%= for task <- @tasks do %>
                  <div class="bg-white border border-gray-200 rounded-2xl shadow-sm p-5 flex flex-col sm:flex-row sm:items-center gap-4">
                    <!-- Info principal -->
                    <div class="flex-1 min-w-0">
                      <div class="flex items-center gap-2 flex-wrap">
                        <span class="font-bold text-gray-900"><%= task.name %></span>
                        <code class="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded font-mono"><%= task.cron_expression %></code>
                        <%= if task.enabled do %>
                          <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-700 border border-emerald-200">
                            <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span> Activa
                          </span>
                        <% else %>
                          <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold bg-gray-100 text-gray-500 border border-gray-200">
                            Inactiva
                          </span>
                        <% end %>
                        <%= if task.last_status == "error" do %>
                          <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold bg-red-100 text-red-700 border border-red-200">
                            Último: error
                          </span>
                        <% end %>
                      </div>
                      <%= if task.description do %>
                        <p class="text-sm text-gray-500 mt-1 truncate"><%= task.description %></p>
                      <% end %>
                      <p class="text-xs text-gray-400 mt-1">
                        <code class="font-mono"><%= task.method %></code> → <span class="truncate"><%= task.url %></span>
                        &nbsp;|&nbsp; tabla: <code class="font-mono"><%= task.target_table %></code>
                        <%= if task.last_run_at do %>
                          &nbsp;|&nbsp; última ejecución: <%= format_dt(task.last_run_at) %>
                        <% end %>
                      </p>
                    </div>
                    <!-- Acciones -->
                    <div class="flex items-center gap-2 flex-shrink-0 flex-wrap">
                      <button type="button" phx-click="run_now" phx-value-id={task.id}
                        class="px-3 py-1.5 text-xs font-semibold rounded-lg border border-blue-200 text-blue-600 bg-white hover:bg-blue-50 transition-colors">
                        ▶ Ejecutar
                      </button>
                      <button type="button" phx-click="view_logs" phx-value-id={task.id}
                        class="px-3 py-1.5 text-xs font-semibold rounded-lg border border-gray-200 text-gray-600 bg-white hover:bg-gray-50 transition-colors">
                        Logs
                      </button>
                      <button type="button" phx-click="toggle_enabled" phx-value-id={task.id}
                        class="px-3 py-1.5 text-xs font-semibold rounded-lg border border-gray-200 text-gray-600 bg-white hover:bg-gray-50 transition-colors">
                        <%= if task.enabled, do: "Deshabilitar", else: "Habilitar" %>
                      </button>
                      <button type="button" phx-click="edit_task" phx-value-id={task.id}
                        class="px-3 py-1.5 text-xs font-semibold rounded-lg border border-gray-200 text-gray-600 bg-white hover:bg-gray-50 transition-colors">
                        Editar
                      </button>
                      <button type="button" phx-click="delete_task" phx-value-id={task.id}
                        data-confirm={"¿Eliminar la tarea \"#{task.name}\"? Se borrarán también todos sus logs."}
                        class="px-3 py-1.5 text-xs font-semibold rounded-lg border border-red-200 text-red-600 bg-white hover:bg-red-50 transition-colors">
                        Eliminar
                      </button>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>

          <!-- Vista: logs de tarea específica -->
          <% else %>
            <div class="mb-4 flex items-center gap-3">
              <button type="button" phx-click="set_view" phx-value-view="tasks"
                class="text-sm text-gray-500 hover:text-gray-900 flex items-center gap-1">
                ← Volver a tareas
              </button>
              <span class="text-gray-300">|</span>
              <span class="text-sm font-semibold text-gray-700">
                Logs: <%= @selected_task && @selected_task.name %>
              </span>
            </div>
            <.logs_table logs={@logs} />
          <% end %>

          <!-- Vista: logs recientes globales -->
          <%= if @view == :logs do %>
            <.logs_table logs={@logs} show_task={true} />
          <% end %>
        <% end %>

      </div>
    </.sidebar>
    """
  end

  # ── Componente tabla de logs ──────────────────────────────────

  defp logs_table(assigns) do
    ~H"""
    <%= if @logs == [] do %>
      <div class="py-16 text-center text-gray-400 text-sm">No hay logs para mostrar.</div>
    <% else %>
      <div class="bg-white border border-gray-200 rounded-2xl shadow-sm overflow-hidden">
        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr class="border-b border-gray-100 bg-gray-50">
                <%= if Map.get(assigns, :show_task) do %>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">Tarea</th>
                <% end %>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">Estado</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">Registros</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">HTTP</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">Duración</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">Ejecutado</th>
                <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">Error</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-50">
              <%= for log <- @logs do %>
                <tr class="hover:bg-gray-50 transition-colors">
                  <%= if Map.get(assigns, :show_task) do %>
                    <td class="px-4 py-3 text-gray-700 text-xs font-medium">
                      <%= log.task_scheduler && log.task_scheduler.name %>
                    </td>
                  <% end %>
                  <td class="px-4 py-3">
                    <%= if log.status == "ok" do %>
                      <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-700 border border-emerald-200">
                        <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span> OK
                      </span>
                    <% else %>
                      <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold bg-red-100 text-red-700 border border-red-200">
                        <span class="w-1.5 h-1.5 rounded-full bg-red-500"></span> Error
                      </span>
                    <% end %>
                  </td>
                  <td class="px-4 py-3 text-gray-700 font-mono text-xs"><%= log.records_inserted || 0 %></td>
                  <td class="px-4 py-3">
                    <code class={"text-xs px-1.5 py-0.5 rounded font-mono " <>
                      if log.response_code && log.response_code in 200..299,
                        do: "bg-emerald-100 text-emerald-700",
                        else: "bg-red-100 text-red-700"}>
                      <%= log.response_code || "—" %>
                    </code>
                  </td>
                  <td class="px-4 py-3 text-gray-500 text-xs font-mono">
                    <%= if log.duration_ms, do: "#{log.duration_ms}ms", else: "—" %>
                  </td>
                  <td class="px-4 py-3 text-gray-500 text-xs whitespace-nowrap"><%= format_dt(log.executed_at) %></td>
                  <td class="px-4 py-3 text-xs text-red-500 max-w-xs truncate" title={log.error_message}>
                    <%= log.error_message || "" %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    <% end %>
    """
  end

  # ── Helpers ───────────────────────────────────────────────────

  defp format_dt(nil), do: "—"
  defp format_dt(%DateTime{} = dt) do
    dt
    |> DateTime.shift_zone!("America/Mexico_City")
    |> Calendar.strftime("%d/%m/%y %H:%M")
  rescue
    _ -> Calendar.strftime(dt, "%d/%m/%y %H:%M")
  end
  defp format_dt(%NaiveDateTime{} = ndt) do
    format_dt(DateTime.from_naive!(ndt, "Etc/UTC"))
  end
end
