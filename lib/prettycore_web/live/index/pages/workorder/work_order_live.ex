defmodule PrettycoreWeb.WorkOrderLive do
  use PrettycoreWeb, :live_view_admin

  alias Prettycore.Workorders
  alias Prettycore.WorkorderApi
  alias Prettycore.Repo
  alias Prettycore.Auth.User
  import Ecto.Query, only: [from: 2]

  ## MOUNT
  @impl true
  def mount(_params, session, socket) do
    # Get all workorders once for filter options
    all_workorders = Workorders.list_enc()

    sysudn_opts =
      all_workorders
      |> Enum.map(& &1.sysudn)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()

    usuario_opts =
      all_workorders
      |> Enum.map(&Map.get(&1, :usuario))
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.uniq()
      |> Enum.sort()

    {:ok,
     socket
     |> assign(:current_page, "workorder")
     |> assign(:show_programacion_children, false)
     |> assign(:sidebar_open, true)
     |> assign(:current_user_email, session["user_email"])
     |> assign(:sysudn_opts, sysudn_opts)
     |> assign(:usuario_opts, usuario_opts)
     |> assign(:open_key, nil)
     |> assign(:detalles, %{})
     |> assign(:filters_open, false)
     |> assign(:current_path, "/admin/workorder")}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    # Set default estado if not provided
    params =
      params
      |> Map.put_new("estado", "por_aceptar")
      |> Map.put_new("page", "1")
      |> Map.put_new("page_size", "10")

    # Use Flop to handle pagination and filtering
    case Workorders.list_enc_with_flop(params) do
      {:ok, {workorders, meta}} ->
        {:noreply,
         socket
         |> assign(:workorders, workorders)
         |> assign(:meta, meta)
         |> assign(:params, params)
         |> assign(:open_key, nil)
         |> assign(:detalles, %{})}

      {:error, meta} ->
        # If validation fails, use default params and show empty results
        {:noreply,
         socket
         |> assign(:workorders, [])
         |> assign(:meta, meta)
         |> assign(:params, params)
         |> assign(:open_key, nil)
         |> assign(:detalles, %{})}
    end
  end

  # ------------------------------------------------------------------
  # 🎯 MODELO 2: NAV CENTRALIZADA
  # ------------------------------------------------------------------
  @impl true
  def handle_event("change_page", %{"id" => id}, socket) do
    case id do
      "toggle_sidebar" ->
        {:noreply, update(socket, :sidebar_open, &(not &1))}

      "inicio" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/platform")}

      "programacion" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/programacion")}

      "programacion_sql" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/programacion/sql")}

      "workorder" ->
        # ya estás aquí
        {:noreply, socket}

      "clientes" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/clientes")}

      "config" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/configuracion")}

      _ ->
        {:noreply, socket}
    end
  end

  # ------------------------------------------------------------------
  # PAGINACIÓN - Ahora manejado por Flop Phoenix
  # ------------------------------------------------------------------

  # ------------------------------------------------------------------
  # CAMBIAR ESTADO (ACEPTAR / RECHAZAR)
  # ------------------------------------------------------------------
  def handle_event("cambiar_estado", %{"ref" => ref, "estado" => estado_str}, socket) do
    estado = String.to_integer(estado_str)
    sysusr_codigo = socket.assigns.current_user_email

    password_query =
      from(u in User,
        where: u.sysusr_codigo_k == ^sysusr_codigo,
        select: u.sysusr_password
      )

    case Repo.one(password_query) do
      nil ->
        IO.puts("No se encontró SYSUSR_PASSWORD para #{sysusr_codigo}")
        {:noreply, socket}

      password ->
        case WorkorderApi.cambiar_estado(ref, estado, password) do
          {:ok, _body} ->
            # Reload workorders with current params
            case Workorders.list_enc_with_flop(socket.assigns.params) do
              {:ok, {workorders, meta}} ->
                {:noreply,
                 socket
                 |> assign(:workorders, workorders)
                 |> assign(:meta, meta)}

              {:error, _} ->
                {:noreply, socket}
            end

          {:error, reason} ->
            IO.inspect(reason, label: "error cambiar_estado")
            {:noreply, socket}
        end
    end
  end

  # ------------------------------------------------------------------
  # FILTROS BÁSICOS (Todas / Pendientes)
  # ------------------------------------------------------------------

  # ------------------------------------------------------------------
  # Drawer de filtros
  # ------------------------------------------------------------------
  def handle_event("toggle_filters", _params, socket) do
    # When called from phx-click-away, only close if open
    # When called from button, toggle
    if socket.assigns.filters_open do
      {:noreply, assign(socket, :filters_open, false)}
    else
      {:noreply, assign(socket, :filters_open, true)}
    end
  end

  # ------------------------------------------------------------------
  # FILTROS AVANZADOS
  # ------------------------------------------------------------------
  def handle_event("set_filter", params, socket) do
    # Clean empty params and reset to page 1 when filters change
    clean_params =
      params
      |> Enum.reject(fn {_k, v} -> v in [nil, ""] end)
      |> Enum.into(%{})
      |> Enum.map(fn {k, v} ->
        # Si el valor es una lista, tomar el primer elemento
        {k, if(is_list(v), do: List.first(v), else: v)}
      end)
      |> Enum.into(%{})
      |> Map.put("page", "1")
      |> Map.put("page_size", "10")

    query = URI.encode_query(clean_params)

    {:noreply, push_patch(socket, to: "/admin/workorder?#{query}")}
  end

  # ------------------------------------------------------------------
  # ABRIR / CERRAR DETALLES
  # ------------------------------------------------------------------
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

    open_key = if socket.assigns.open_key == key, do: nil, else: key

    {:noreply,
     socket
     |> assign(:detalles, Map.put(detalles_cache, key, detalles))
     |> assign(:open_key, open_key)}
  end

  # ------------------------------------------------------------------
  # HELPERS
  # ------------------------------------------------------------------
  defp image_src(nil), do: nil

  defp image_src(url) when is_binary(url) do
    trimmed = String.trim(url)
    if trimmed == "", do: nil, else: trimmed
  end

  defp estado_label(100), do: "Pendiente"
  defp estado_label(500), do: "Atendida"
  defp estado_label(600), do: "Cancelado"
  defp estado_label(_), do: "Desconocido"

  defp estado_class(100), do: "wo-state wo-state-pendiente"
  defp estado_class(500), do: "wo-state wo-state-atendida"
  defp estado_class(600), do: "wo-state wo-state-cancelado"
  defp estado_class(_), do: "wo-state"

  # Build path for pagination preserving all filter params
  # This function is called by Flop.Phoenix.pagination with new page params
  def build_pagination_path(new_params, current_params) do
    # Convert new_params to a map if it's a keyword list
    new_params = Enum.into(new_params, %{})

    # Extract page and page_size from new_params (can be atoms or strings)
    page = new_params[:page] || new_params["page"] || 1
    page_size = new_params[:page_size] || new_params["page_size"] || 10

    # Merge current filters with new pagination params
    query_params =
      current_params
      |> Map.drop(["page", "page_size", "order_by", "order_directions"])
      |> Map.merge(%{
        "page" => to_string(page),
        "page_size" => to_string(page_size)
      })

    # Build the query string
    query_string = URI.encode_query(query_params)

    "/admin/workorder?" <> query_string
  end

  # Calcula las páginas visibles para la paginación dinámica
  # Muestra un máximo de `max_visible` páginas, desplazándose cuando sea necesario
  def get_visible_pages(current_page, total_pages, max_visible) do
    cond do
      # Si hay menos páginas que el máximo visible, mostrar todas
      total_pages <= max_visible ->
        1..total_pages |> Enum.to_list()

      # Si estamos en las primeras páginas
      current_page <= div(max_visible, 2) + 1 ->
        1..max_visible |> Enum.to_list()

      # Si estamos en las últimas páginas
      current_page >= total_pages - div(max_visible, 2) ->
        (total_pages - max_visible + 1)..total_pages |> Enum.to_list()

      # Si estamos en el medio, centrar la página actual
      true ->
        start_page = current_page - div(max_visible, 2)
        start_page..(start_page + max_visible - 1) |> Enum.to_list()
    end
  end
end
