defmodule Mix.Tasks.SeedSysadmin do
  use Mix.Task

  @shortdoc "Crea el usuario SYSADMIN en PostgreSQL si no existe"

  def run(_args) do
    # Force-configure the repo from DATABASE_URL in case runtime.exs wasn't evaluated
    case System.get_env("DATABASE_URL") do
      nil ->
        :ok

      database_url ->
        db_uri = URI.parse(database_url)
        [db_username, db_password] = String.split(db_uri.userinfo || "postgres:postgres", ":", parts: 2)
        db_name = String.trim_leading(db_uri.path || "/prettycore", "/")
        hostname = db_uri.host || "localhost"
        port = db_uri.port || 5432

        Application.put_env(:prettycore, Prettycore.PsqlRepo,
          ssl: [verify: :verify_none],
          hostname: hostname,
          port: port,
          username: db_username,
          password: db_password,
          database: db_name,
          pool_size: String.to_integer(System.get_env("POOL_SIZE") || "2"),
          parameters: [client_encoding: "UTF8"]
        )
    end

    {:ok, _, _} = Ecto.Migrator.with_repo(Prettycore.PsqlRepo, fn _repo ->
      alias Prettycore.Auth

      case Auth.get_user_by_username("SYSADMIN") do
        nil ->
          case Auth.create_user(%{
                 username: "SYSADMIN",
                 password: "PRETTYCORE13",
                 role: "sysadmin",
                 active: true
               }) do
            {:ok, user} ->
              Mix.shell().info("✓ Usuario SYSADMIN creado con ID: #{user.id}")

            {:error, changeset} ->
              Mix.shell().error("✗ Error: #{inspect(changeset.errors)}")
          end

        _user ->
          Mix.shell().info("→ El usuario SYSADMIN ya existe, no se modifica.")
      end
    end)
  end
end
