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
    on_mount: [{PrettycoreWeb.AuthOnMount, :ensure_authenticated}] do
    scope "/admin", PrettycoreWeb do
      pipe_through :browser

      live "/platform", Inicio
  #    live "/programacion", Programacion
  #    live "/programacion/sql", HerramientaSql
      live "/workorder", WorkOrderLive
      live "/clientes", Clientes
      live "/clientes/new", ClienteFormNewLive
      live "/clientes/new/:tab", ClienteFormNewLive
      live "/clientes/edit/:id", ClienteFormEditLive
      live "/clientes/edit/:id/:tab", ClienteFormEditLive
  #    live "/configuracion", ConfiguracionLive
    end
  end

  ## Rutas para descarga de Excel (protegidas pero no LiveView)
  scope "/admin", PrettycoreWeb do
    pipe_through :browser
    live "/users", Users.UsersCreateLive

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

  # Development-only routes for debugging and monitoring.
  # Only available when dev_routes configuration is enabled.
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: EecWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
