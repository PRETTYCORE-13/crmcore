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

    existing = repo.get_by(AuthUser, username: "SYSADMIN")

    {changeset, action} =
      case existing do
        nil ->
          cs = AuthUser.changeset(%AuthUser{}, %{
            username: "SYSADMIN",
            password: "PRETTYCORE13",
            role: "sysadmin",
            active: true
          })
          {cs, :insert}

        user ->
          cs = user
               |> AuthUser.password_changeset(%{password: "PRETTYCORE13"})
               |> Ecto.Changeset.put_change(:active, true)
               |> Ecto.Changeset.put_change(:role, "sysadmin")
          {cs, :update}
      end

    result = if action == :insert, do: repo.insert(changeset), else: repo.update(changeset)

    case result do
      {:ok, user} -> IO.puts("✓ SYSADMIN #{action} OK — ID: #{user.id}")
      {:error, cs} -> IO.puts("✗ SYSADMIN #{action} ERROR: #{inspect(cs.errors)}")
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
