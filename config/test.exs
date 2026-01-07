import Config

# Configure the database for testing
# Note: Using integration tests with the production database
# SQL Sandbox is not fully supported with SQL Server (TDS)
config :prettycore, Prettycore.Repo,
  hostname: "ecore.ath.cx",
  port: 1433,
  username: "sa",
  password: "N0vacore",
  database: "ECOREDES2",
  pool_size: 2,
  encrypt: false,
  trust_server_certificate: true,
  timeout: 15_000,
  idle_timeout: 5_000

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
