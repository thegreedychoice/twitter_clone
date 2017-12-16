defmodule TwitterServer.Repo.Migrations.CreateTweet do
  use Ecto.Migration

  def change do
    create table(:tweets) do
      add :message, :string
      add :userid, :integer
      add :isRetweet, :boolean

      timestamps()
    end

    create index(:tweets, [:message])

  end
end
