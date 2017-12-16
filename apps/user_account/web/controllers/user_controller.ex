# web/controllers/user_controller
defmodule UserAccount.UserController do
    use UserAccount.Web, :controller
    alias UserAccount.User

    def index(conn, _params) do
        users = Repo.all(User)
        json conn_with_status(conn, users), users
    end

    def show(conn, %{"id" => id}) do
        user = Repo.get(User, String.to_integer(id))
        IO.inspect user
        json conn_with_status(conn, user), user
    end

    def create(conn, params) do

        changeset = User.changeset(%User{}, params)

        case Repo.insert(changeset) do
            {:ok, user} ->
                json conn |> put_status(:created), user
            {:error, _changeset} ->
                json conn |> put_status(:bad_request), %{errors: ["unable to create user"]}
        end
    end

    def update(conn, %{"id" => id} = params) do
        user = Repo.get(User, String.to_integer(id))

        if user do
            perform_update(conn, user, params)
        else
            json conn |> put_status(:not_found), %{errors: ["user not found"]}
        end
    end

    defp perform_update(conn, user, params) do
        changeset = User.changeset(user, params)
        IO.inspect changeset
        case Repo.update(changeset) do
            {:ok, user} ->
                json conn |> put_status(:created), user
            {:error, _changeset} ->
                json conn |> put_status(:bad_request), %{errors: ["unable to create user"]}
        end        

    end


    defp conn_with_status(conn, nil) do
        conn
        |> put_status(:not_found)
    end

    defp conn_with_status(conn, _) do
        conn
        |> put_status(:ok)
    end
end