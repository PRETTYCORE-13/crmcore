defmodule Prettycore.SysAdmin.Config do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}

  schema "system_config" do
    field :usuario, :string
    field :instancia, :string
    field :token, :string
    field :url, :string
    field :foto, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(config, attrs) do
    config
    |> cast(attrs, [:usuario, :instancia, :token, :url, :foto])
    |> validate_required([:instancia, :token], message: "es obligatorio")
  end
end
