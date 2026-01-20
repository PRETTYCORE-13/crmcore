defmodule Prettycore.PsqlRepo do
  @moduledoc """
  Repositorio para autenticación usando PostgreSQL.
  Este repo se usa exclusivamente para el sistema de login.
  """
  use Ecto.Repo,
    otp_app: :prettycore,
    adapter: Ecto.Adapters.Postgres
end
