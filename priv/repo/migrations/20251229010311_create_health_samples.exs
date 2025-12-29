defmodule Tempo.Repo.Migrations.CreateHealthSamples do
  use Ecto.Migration

  def change do
    create table(:health_samples, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :type, :string, null: false
      add :quantity, :float, null: false
      add :start_date, :utc_datetime, null: false
      add :end_date, :utc_datetime, null: false

      timestamps()
    end

    create index(:health_samples, [:type, :start_date])
    create index(:health_samples, [:start_date])
  end
end
