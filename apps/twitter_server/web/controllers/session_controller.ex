defmodule TwitterServer.SessionController do
    use TwitterServer.Web, :controller
    import Plug.Conn

    def new(conn, _params) do
        render conn, "new.html"
    end

    def create(conn, %{"session" => %{"email" => email, "password" => password}}) do
        #IO.inspect email
        #IO.inspect password

        case TwitterServer.Session.login(email, password, TwitterServer.Repo) do
            {:ok, user} ->
                #IO.puts "User valid"
                token = Phoenix.Token.sign(conn, "user salt", user.id)
                IO.inspect token
                
                conn = assign(conn, :user_token, token)
                
                IO.inspect conn
                conn
                |> put_session(:current_user, user.id)
                |> put_flash(:info, "Logged in")
                |> redirect(to: page_path(conn, :index))
            :error ->
                #IO.puts "User Invalid"
                conn
                |> put_flash(:info, "Wrong email or password")
                |> render("new.html")
        end
    end

    def delete(conn, _) do
        conn
        |> delete_session(:current_user)
        |> put_flash(:info, "Logged Out!")
        |> redirect(to: "/")
    end
end