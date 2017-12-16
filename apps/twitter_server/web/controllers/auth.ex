defmodule TwitterServer.Auth do
    alias TwitterServer.User

    alias AuthToken, as: Token

    import Plug.Conn

    @behaviour Plug
    def init(opts) do
		Keyword.fetch!(opts, :repo)
	end

    def login(conn, user) do

        conn
        |> assign(:current_user, user)
        |> put_session(:user_id, user.id)
        |> configure_session(renew: true)

    end



    def call(conn, repo) do	
        IO.puts "Inside Auth"
        user_id = get_session(conn, :user_id)
        IO.inspect user_id
    
        if user = user_id && repo.get(User, user_id) do
            IO.puts "User"
            IO.inspect user
            put_current_user(conn, user)
        else
            assign(conn, :current_user, nil)	
        end
    end

    def logout(conn, _) do

        conn
        |> delete_session(:user_id)
        
    end
    
    defp put_current_user(conn, user) do

        token = Token.sign(conn, "user", user.id)
    
        conn
        |> assign(:current_user, user)
        |> assign(:user_token, token)
    end
end