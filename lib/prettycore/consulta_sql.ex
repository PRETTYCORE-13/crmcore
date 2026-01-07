defmodule Prettycore.TdsClient do
  @moduledoc false
  alias Tds, as: TDS

  # Debe regresar KEYWORD LIST, no map
  defp opts do
    cfg = Application.get_env(:prettycore, :tds, %{})

    host = System.get_env("SQLSERVER_HOST") || cfg[:hostname] || "ecore.ath.cx"
    port = System.get_env("SQLSERVER_PORT") || "#{cfg[:port] || 1433}"
    user = System.get_env("SQLSERVER_USER") || cfg[:username] || "sa"
    pass = System.get_env("SQLSERVER_PASS") || cfg[:password] || "N0vacore"
    db = System.get_env("SQLSERVER_DB") || cfg[:database] || "ECOREDES2"

    [
      hostname: host,
      port: String.to_integer(port),
      username: user,
      password: pass,
      database: db,
      encrypt: cfg[:encrypt] || false,
      trust_server_certificate: cfg[:trust_server_certificate] || true,
      timeout: cfg[:timeout] || 15_000,
      idle_timeout: cfg[:idle_timeout] || 5_000
    ]
  end

  def query(sql, params \\ []) when is_binary(sql) and is_list(params) do
    {:ok, conn} = TDS.start_link(opts())

    try do
      TDS.query(conn, sql, params, timeout: 15_000)
    after
      Process.exit(conn, :normal)
    end
  end

  def query!(sql, params \\ []) do
    {:ok, %TDS.Result{rows: rows}} = query(sql, params)
    rows
  end
end
