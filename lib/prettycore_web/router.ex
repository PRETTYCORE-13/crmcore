# lib/prettycore_web/router.ex
defmodule PrettycoreWeb.Router do
  use PrettycoreWeb, :router

  ## Pipelines
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PrettycoreWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  ## Rutas de login y sesión
  scope "/", PrettycoreWeb do
    pipe_through :browser

    # Página de login (LiveView)
    live "/", LoginLive

    # Nueva ruta para cambio de contraseña (UI)
    live "/password-reset", PasswordResetLive

    # Controlador que valida usuario y crea sesión
    post "/", SessionController, :create

    # Logout (destruye sesión)
    get "/logout", SessionController, :delete
  end

  ## ÁREA PROTEGIDA: requiere sesión
  live_session :auth,
    on_mount: [] do
    scope "/admin", PrettycoreWeb do
      pipe_through :browser

      live "/platform", Inicio
      live "/programacion", Programacion
      live "/programacion/sql", HerramientaSql
      live "/workorder", WorkOrderLive
      live "/clientes", Clientes
      live "/clientes/new", ClienteFormLive
      live "/clientes/new/:tab", ClienteFormLive
      live "/configuracion", ConfiguracionLive
    end
  end

  ## Rutas para descarga de Excel (protegidas pero no LiveView)
  scope "/admin", PrettycoreWeb do
    pipe_through :browser

    get "/clientes/export/excel", ClientesExcelController, :download
  end

  ## Health simple (sin login)
  scope "/", PrettycoreWeb do
    pipe_through :api
    get "/health", HealthController, :index
  end

  ## Endpoints JSON API
  scope "/api", PrettycoreWeb do
    pipe_through :api

    get "/sys_udn", SysUdnController, :index
    get "/sys_udn/codigos", SysUdnController, :codigos
  end
end
