defmodule Prettycore.ClientIntelligence.CiScore do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ci_scores" do
    field :client_code, :string
    field :activity_score, :integer, default: 0
    field :view_count_30d, :integer, default: 0
    field :edit_count_30d, :integer, default: 0
    field :last_viewed_at, :utc_datetime
    field :last_edited_at, :utc_datetime
    field :computed_at, :utc_datetime

    timestamps()
  end

  def changeset(score, attrs) do
    score
    |> cast(attrs, [
      :client_code,
      :activity_score,
      :view_count_30d,
      :edit_count_30d,
      :last_viewed_at,
      :last_edited_at,
      :computed_at
    ])
    |> validate_required([:client_code])
    |> validate_number(:activity_score, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> unique_constraint(:client_code)
  end
end
