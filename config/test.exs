import Config

# Configure the database for testing
# Note: Using integration tests with the production database
# SQL Sandbox is not fully supported with SQL Server (TDS)
config :prettycore, :tds,
  hostname: System.get_env("DB_HOSTNAME", "localhost"),
  port: String.to_integer(System.get_env("DB_PORT", "1433")),
  username: System.get_env("DB_USERNAME"),
  password: System.get_env("DB_PASSWORD"),
  database: System.get_env("DB_DATABASE"),
  pool_size: String.to_integer(System.get_env("DB_POOL_SIZE", "10")),
  # Encryption settings (use true for Azure/SSL)
  encrypt: System.get_env("DB_ENCRYPT", "false") == "true",
  trust_server_certificate: System.get_env("DB_TRUST_SERVER_CERTIFICATE", "true") == "true",
  timeout: 15_000,
  idle_timeout: 5_000,
  show_sensitive_data_on_connection_error: true

  config :prettycore, PrettyCore.PsqlRepo,
  username: "postgres",
  password: "PRETTYCORE13",
  hostname: "localhost",
  database: "prettycore_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :prettycore, PrettycoreWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Wor86DGb4L3o5N2CTZm2Fw5CCURD0t2jZx5gZnbVKMPVbnP/hgompzwoBsDCI6FG",
  server: false

# In test we don't send emails
config :prettycore, Prettycore.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
