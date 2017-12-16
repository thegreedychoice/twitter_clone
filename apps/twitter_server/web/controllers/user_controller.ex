# User Api Controller


defmodule TwitterServer.UserController do
  use TwitterServer.Web, :controller
  alias User
	
    #alias TwitterServer.User
    alias TwitterServer.SessionController

    def index(conn, _params) do
        users = Repo.all(TwitterServer.User)
        json conn_with_status(conn, users), users
    end

    def show(conn, %{"id" => id}) do
        user = Repo.get(TwitterServer.User, String.to_integer(id))
        IO.inspect user
        json conn_with_status(conn, user), user
    end

    def create(conn, params) do

        #IO.inspect params["user"]

        
        changeset = TwitterServer.User.changeset(%TwitterServer.User{}, params["user"])

        case Repo.insert(changeset) do
            {:ok, user} ->
                #IO.inspect conn
                #SessionController.create(conn, %{"session" => %{"email" => user.email, "password" => user.password}})
                
                User.create_user(user.name, user.password)
                IO.puts "User Created in Main Server!"

                #start client GenServer
                start_client_genserver(user.name, user.password)
                
                conn
                |> TwitterServer.Auth.login(user)
                |> redirect(to: "/timeline")
                
                #json conn |> put_status(:created) |> redirect(to: "/"), user

            {:error, _changeset} ->
                #json conn |> put_status(:bad_request), %{errors: ["unable to create user"]}
                conn 
                |> redirect(to: "/signin")
        end

        
    end

    def update(conn, %{"id" => id} = params) do
        user = Repo.get(TwitterServer.User, String.to_integer(id))

        if user do
            perform_update(conn, user, params)
        else
            json conn |> put_status(:not_found), %{errors: ["user not found"]}
        end
    end

    defp perform_update(conn, user, params) do
        changeset = TwitterServer.User.changeset(user, params)
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


    #Client Functions

    def register(conn, _params) do
        changeset = TwitterServer.User.changeset(%TwitterServer.User{})
        render(conn, "register.html", changeset: changeset)
    end

    def new(conn, _params) do
        render conn, "signin.html"
    end

    def signin(conn, %{"session" => %{"email" => email, "password" => password}}) do

        case TwitterServer.Session.login(email, password, TwitterServer.Repo) do
            {:ok, user} ->
                IO.puts "Valid Sign In!"
                
                #start client genserver
                start_client_genserver(user.name, password)

                conn
                |> TwitterServer.Auth.login(user)
                |> redirect(to: "/timeline")
                
            :error ->
                IO.puts "Invalid Sign In!"
                conn
                |> put_flash(:info, "Wrong email or password")
                |> render("signin.html")
        end
    end

    def signout(conn, _params) do
        #User.stop_client_genserver(conn.)
        #IO.puts "Inside Signout"
        
        #Stop the client Genserver
        user = conn.assigns[:current_user]
        name = Map.get(user, :name)
        stop_client_genserver(name)

        conn
        |> TwitterServer.Auth.logout(_params)
        |> put_flash(:info, "Logged Out!")
        |> redirect(to: "/signin")
    end

    def start_client_genserver(username, password) do
        User.start_link(username, password)
    end

    def stop_client_genserver(username) do
        User.go_offline(username)
    end
  
end
