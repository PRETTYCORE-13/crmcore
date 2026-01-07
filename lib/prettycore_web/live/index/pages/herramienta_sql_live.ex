defmodule PrettycoreWeb.HerramientaSql do
  use PrettycoreWeb, :live_view_admin

  import PrettycoreWeb.MenuLayout
  alias Prettycore.TdsClient
  alias Decimal

  # Ruta: /admin/programacion/sql/:email
  @impl true
  def mount(_params, session, socket) do
    {:ok,
     socket
     |> assign(:current_page, "programacion_sql")
     |> assign(:show_programacion_children, true)
     |> assign(:sidebar_open, true)
     |> assign(:current_user_email, session["user_email"])
     |> assign(:current_path, "/admin/programacion/sql")
     |> assign(:sql_query, "SELECT * FROM SYS_UDN;")
     |> assign(:columns, [])
     |> assign(:rows, [])
     |> assign(:error, nil)}
  end

  # -----------------------------------------------------
  # NAV CENTRALIZADA (MODELO 2)
  # -----------------------------------------------------
  @impl true
  def handle_event("change_page", %{"id" => id}, socket) do
    email = socket.assigns.current_user_email

    case id do
      "toggle_sidebar" ->
        {:noreply, update(socket, :sidebar_open, &(not &1))}

      "inicio" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/platform")}

      "programacion" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/programacion")}

      "programacion_sql" ->
        # ya estás aquí
        {:noreply, socket}

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

  # -----------------------------------------------------
  # EJECUCIÓN DE SQL
  # -----------------------------------------------------
  @impl true
  def handle_event("run_sql", %{"sql_query" => query}, socket) do
    sql =
      query
      |> String.trim()
      |> String.replace(~r/\"([^"]*)\"/, "'\\1'")

    cond do
      sql == "" ->
        {:noreply, assign(socket, :error, "Escribe una consulta.")}

      not allowed_sql?(sql) ->
        {:noreply,
         assign(
           socket,
           :error,
           "Solo se permiten SELECT, UPDATE, INSERT, DELETE, " <>
             "CREATE TABLE, CREATE VIEW, CREATE OR ALTER VIEW, ALTER TABLE o WITH (CTE)."
         )}

      true ->
        case TdsClient.query(sql, []) do
          {:ok, %Tds.Result{columns: cols, rows: rows} = res} ->
            if is_list(cols) and cols != [] do
              columns = Enum.map(cols, &to_string/1)

              rows_norm =
                Enum.map(rows || [], fn row ->
                  Enum.map(row, &norm/1)
                end)

              {:noreply,
               socket
               |> assign(:sql_query, query)
               |> assign(:error, nil)
               |> assign(:columns, columns)
               |> assign(:rows, rows_norm)}
            else
              {:noreply,
               socket
               |> assign(:sql_query, query)
               |> assign(:error, nil)
               |> assign(:columns, ["Resultado"])
               |> assign(:rows, [
                 [
                   "Comando ejecutado con éxito (#{res.num_rows || 0} filas afectadas)"
                 ]
               ])}
            end

          {:error, reason} ->
            {:noreply,
             socket
             |> assign(:sql_query, query)
             |> assign(:error, "Error al ejecutar: #{inspect(reason)}")
             |> assign(:columns, [])
             |> assign(:rows, [])}
        end
    end
  end

  # -----------------------------------------------------
  # RENDER
  # -----------------------------------------------------
  @impl true
  def render(assigns) do
    ~H"""
    <section>
      <header class="pc-page-header">
        <h1>Programación · Herramienta SQL</h1>

        <p>Ejecuta consultas SELECT, UPDATE, INSERT, DELETE,
          CREATE TABLE, CREATE VIEW, CREATE OR ALTER VIEW, ALTER TABLE
          o WITH (CTE) directamente contra tu base SQL Server.</p>

        <p class="pc-small-muted">
          Correo actual: {@current_user_email} <br /> URL actual: {@current_path}
        </p>
      </header>

      <div class="pc-page-card mt-3">
        <form phx-submit="run_sql">
          <label class="block text-xs font-medium text-gray-600 mb-1.5">Consulta SQL</label>
          <textarea
            name="sql_query"
            class="w-full font-mono text-xs leading-snug rounded-lg border border-gray-300 px-3 py-2.5 resize-y min-h-[120px] outline-none bg-gray-50 focus:border-indigo-600 focus:shadow-[0_0_0_1px_rgba(79,70,229,0.35)] focus:bg-white transition-all"
            rows="6"
          ><%= @sql_query %></textarea>
          <div class="mt-2 flex items-center gap-2.5">
            <button
              type="submit"
              class="border-none rounded-full px-3.5 py-1.5 text-xs font-medium cursor-pointer bg-gray-900 text-gray-50 inline-flex items-center gap-1.5 hover:bg-gray-950 transition-colors"
            >
              Ejecutar consulta
            </button>
            <span class="text-[11px] text-gray-400">
              Se permiten SELECT, UPDATE, INSERT, DELETE, CREATE TABLE, CREATE VIEW, CREATE OR ALTER VIEW, ALTER TABLE y WITH (CTE).
            </span>
          </div>
        </form>

        <%= if @error do %>
          <div class="mt-2.5 text-xs text-red-700 bg-red-50 rounded-lg border border-red-200 px-2.5 py-2">
            {@error}
          </div>
        <% end %>
      </div>

      <%= if @columns != [] do %>
        <div class="pc-page-card mt-4">
          <div class="flex justify-between items-center text-xs mb-2 text-gray-600">
            <span>Resultados</span>
            <span class="text-gray-400">{length(@rows)} filas</span>
          </div>

          <div class="max-h-[360px] overflow-auto rounded-lg border border-gray-200">
            <table class="w-full border-collapse text-xs">
              <thead class="bg-gray-100 sticky top-0">
                <tr>
                  <%= for col <- @columns do %>
                    <th class="px-2 py-1.5 border-b border-gray-200 text-left font-medium text-gray-600 whitespace-nowrap">
                      {col}
                    </th>
                  <% end %>
                </tr>
              </thead>

              <tbody>
                <%= for row <- @rows do %>
                  <tr class="odd:bg-gray-50/50">
                    <%= for cell <- row do %>
                      <td class="px-2 py-1.5 border-b border-gray-200 whitespace-nowrap">{cell}</td>
                    <% end %>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      <% end %>
    </section>
    """
  end

  ## Helpers de validación SQL
  defp allowed_sql?(sql) do
    up =
      sql
      |> String.trim_leading()
      |> drop_leading_semicolons()
      |> String.upcase()

    cond do
      String.starts_with?(up, "SELECT") -> true
      String.starts_with?(up, "UPDATE") -> true
      String.starts_with?(up, "INSERT") -> true
      String.starts_with?(up, "DELETE") -> true
      String.starts_with?(up, "CREATE TABLE") -> true
      String.starts_with?(up, "CREATE OR ALTER VIEW") -> true
      String.starts_with?(up, "CREATE VIEW") -> true
      String.starts_with?(up, "ALTER TABLE") -> true
      String.starts_with?(up, "WITH") -> true
      true -> false
    end
  end

  defp drop_leading_semicolons(str), do: do_drop_semis(str)
  defp do_drop_semis(<<";", rest::binary>>), do: do_drop_semis(rest)
  defp do_drop_semis(str), do: str

  ## Normalización SQL
  defp norm(v) when is_binary(v),
    do: :unicode.characters_to_binary(v, :latin1, :utf8)

  defp norm({{y, m, d}, {hh, mm, ss, ms}}),
    do:
      NaiveDateTime.new!(y, m, d, hh, mm, ss, {ms, 3})
      |> NaiveDateTime.to_iso8601()

  defp norm({{y, m, d}, {hh, mm, ss}}),
    do:
      NaiveDateTime.new!(y, m, d, hh, mm, ss, 0)
      |> NaiveDateTime.to_iso8601()

  defp norm({y, m, d}),
    do: Date.new!(y, m, d) |> Date.to_iso8601()

  defp norm(%Decimal{} = d),
    do: Decimal.to_string(d)

  defp norm(nil), do: ""
  defp norm(v), do: v
end
