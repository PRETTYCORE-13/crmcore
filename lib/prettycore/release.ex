defmodule Prettycore.Release do
  @moduledoc """
  Tasks for running migrations in production releases.
  """

  @app :prettycore

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, fn repo ->
        Ecto.Migrator.run(repo, :up, all: true)
        seed_sysadmin(repo)
      end)
    end
  end

  defp seed_sysadmin(repo) do
    alias Prettycore.Auth.AuthUser

    case repo.get_by(AuthUser, username: "SYSADMIN") do
      nil ->
        changeset = AuthUser.changeset(%AuthUser{}, %{
          username: "SYSADMIN",
          password: "PRETTYCORE13",
          role: "sysadmin",
          active: true
        })
        case repo.insert(changeset) do
          {:ok, user} -> IO.puts("✓ Usuario SYSADMIN creado con ID: #{user.id}")
          {:error, cs} -> IO.puts("✗ Error al crear SYSADMIN: #{inspect(cs.errors)}")
        end

      _user ->
        IO.puts("→ Usuario SYSADMIN ya existe, no se modifica.")
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    [Prettycore.PsqlRepo]
  end

  defp load_app do
    Application.load(@app)
  end
end
