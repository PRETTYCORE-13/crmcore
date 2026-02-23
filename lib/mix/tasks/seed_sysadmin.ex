defmodule Mix.Tasks.SeedSysadmin do
  use Mix.Task

  @shortdoc "Crea el usuario SYSADMIN en PostgreSQL si no existe"

  def run(_args) do
    [:postgrex, :ecto, :ecto_sql]
    |> Enum.each(&Application.ensure_all_started/1)

    Prettycore.PsqlRepo.start_link([])

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
  end
end
