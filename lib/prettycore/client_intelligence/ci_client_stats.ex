defmodule Prettycore.ClientIntelligence.CiClientStats do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "ci_client_stats" do
    field :client_code, :string
    field :dir_code, :string
    field :client_name, :string
    field :total_venta_anual, :float, default: 0.0
    field :cartera_vigente, :float, default: 0.0
    field :cartera_vencida, :float, default: 0.0
    field :enfriadores, :integer, default: 0
    field :clasificacion, :string
    field :ultimo_pedido_fecha, :string
    field :fetched_at, :utc_datetime

    timestamps()
  end

  def changeset(stats, attrs) do
    stats
    |> cast(attrs, [
      :client_code, :dir_code, :client_name,
      :total_venta_anual, :cartera_vigente, :cartera_vencida,
      :enfriadores, :clasificacion, :ultimo_pedido_fecha, :fetched_at
    ])
    |> validate_required([:client_code, :dir_code, :fetched_at])
    |> unique_constraint([:client_code, :dir_code])
  end
end
