defmodule Prettycore.Auth.UserSession do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "user_sessions" do
    field :session_token, :string
    field :ip_address, :string
    field :user_agent, :string
    field :device_type, :string
    field :browser, :string
    field :os, :string
    field :last_seen_at, :utc_datetime
    field :logged_out_at, :utc_datetime

    belongs_to :user, Prettycore.Auth.AuthUser

    timestamps()
  end

  def changeset(session, attrs) do
    session
    |> cast(attrs, [:user_id, :session_token, :ip_address, :user_agent,
                    :device_type, :browser, :os, :last_seen_at, :logged_out_at])
    |> validate_required([:user_id, :session_token])
    |> unique_constraint(:session_token)
  end
end
