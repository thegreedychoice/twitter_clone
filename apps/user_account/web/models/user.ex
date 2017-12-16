# web/models/user.ex
"""
This model will enforce certain constraints on our data objects
We can enable Ecto structures or define our own Elixir structures.
This model will enforce that our data object transforms into Ecto compatible structure
and only then be able to update our database
"""
defmodule UserAccount.User do
    use UserAccount.Web, :model

    #create a schema for our user model
    schema "users" do
        field :name, :string
        field :email, :string
        field :password, :string

        timestamps()
    end

    def changeset(model, params \\ :empty) do
        model
        |> cast(params, [:name, :email, :password])
        |> unique_constraint(:email)
    end
    """
    Instead of using Ecto structure for models, we can just use Elixir structures in 
    the following way

    defstruct [:id, :name, :email, :password]
    """
end