defmodule Prettycore.Repo do
  use Ecto.Repo,
    otp_app: :prettycore,
    adapter: Ecto.Adapters.Tds
end
