defmodule Tempo.Repo.Migrations.AddSampleTypeIndex do
  use Ecto.Migration

  def change do
    create index(:health_samples, [:type])
  end
end
