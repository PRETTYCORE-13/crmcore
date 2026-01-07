defmodule PrettycoreWeb.SysUdnController do
  use PrettycoreWeb, :controller
  alias Prettycore.SysUdn

  def index(conn, _params) do
    json(conn, %{data: SysUdn.listar_todo()})
  end

  def codigos(conn, _params) do
    json(conn, %{data: SysUdn.listar_codigos()})
  end
end
