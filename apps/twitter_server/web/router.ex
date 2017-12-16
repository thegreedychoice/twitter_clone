defmodule TwitterServer.Router do
  use TwitterServer.Web, :router
  import Plug.Conn

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug TwitterServer.Auth, repo: TwitterServer.Repo
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  
  scope "/", TwitterServer do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index


    #custom
    get "/register", UserController, :register
    get "/signin", UserController, :new
    post "/signin", UserController, :signin
    get "/signout", UserController, :signout


    get "/users", UserController, :index
    get "/users/:id", UserController, :show
    post "/users", UserController, :create
    put "/users/:id", UserController, :update

    #timeline apis
    get "/timeline", TimelineController, :index



    get    "/login",  SessionController, :new
    post   "/login",  SessionController, :create
    delete "/logout", SessionController, :delete

  end
  

  # Other scopes may use custom stacks.
  # scope "/api", TwitterServer do
  #   pipe_through :api
  # end

  scope "/api", TwitterServer do
    pipe_through :api


    """
    get "/users", UserController, :index
    get "/users/:id", UserController, :show
    post "/users", UserController, :create
    put "/users/:id", UserController, :update
    """

    #login/logout

    #tweets api
    get "/tweets", TweetController, :index
    get "/tweets/:id", TweetController, :show
    post "/tweets/", TweetController, :create
  end

  defp put_user_token(conn, _) do
    if current_user = conn.assigns[:current_user] do
      token = Phoenix.Token.sign(conn, "user socket", current_user.id)
      assign(conn, :user_token, token)
    else
       conn
    end
  end

end
