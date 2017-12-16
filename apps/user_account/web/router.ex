defmodule UserAccount.Router do
  use UserAccount.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end
"""
  scope "/", UserAccount do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end
"""
  #Other scopes may use custom stacks.
  
  scope "/api", UserAccount do
    pipe_through :api

    get "/users", UserController, :index
    get "/users/:id", UserController, :show
    post "/users", UserController, :create
    put "/users/:id", UserController, :update
  end
end
