defmodule Tempo.HealthData.Sample do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:uuid, :binary_id, autogenerate: false}
  schema "health_samples" do
    field :type, :string
    field :quantity, :float
    field :start_date, :utc_datetime
    field :end_date, :utc_datetime

    timestamps()
  end

  def changeset(sample, attrs) do
    sample
    |> cast(attrs, [:uuid, :type, :quantity, :start_date, :end_date])
    |> validate_required([:uuid, :type, :quantity, :start_date, :end_date])
  end
end
