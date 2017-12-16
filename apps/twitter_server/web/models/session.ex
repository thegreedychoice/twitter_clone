defmodule TwitterServer.Session do
    alias TwitterServer.User 

    def login(email, password, repo) do
        user = repo.get_by(User, email: String.downcase(email))
        case authenticate(user, password) do
          true -> {:ok, user}
          _    -> :error
        end
    end

    def current_user(conn) do
        id = Plug.Conn.get_session(conn, :user_id)
        if id, do: TwitterServer.Repo.get(User, id)
    end

    def logged_in?(conn), do: !!current_user(conn)
    
    defp authenticate(user, password) do
        case user do
          nil -> false
          _   -> 
            case user.password == password do
                true -> true
                false -> false

            end
        end
    end
end