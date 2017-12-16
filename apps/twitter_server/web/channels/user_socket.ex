defmodule TwitterServer.UserSocket do
  use Phoenix.Socket

  alias AuthToken, as: Token

  alias TwitterServer.{Repo, User}

  ## Channels
  # channel "room:*", TwitterServer.RoomChannel
  channel "timeline:feed", TwitterServer.TimelineChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket
  # transport :longpoll, Phoenix.Transports.LongPoll

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  """
  def connect(_params, socket) do
    {:ok, socket}
  end
  """
  
 
"""
  def connect(%{"user" => user}, socket) do
    # 1 day = 86400 seconds

    IO.puts "Connect Socket!!!!!"
    IO.inspect user
    #IO.puts token

    case Phoenix.Token.verify(socket, "user", token, max_age: 86400) do
      {:ok, user_id} ->
        IO.puts "Socket Verifies User!"
        socket = assign(socket, :current_user, Repo.get!(User, user_id))
        {:ok, socket}
      {:error, _} ->
        :error
    end


    {:ok, assign(socket, :user, user)}

 
  end


"""
def connect(%{"user" => user}, socket) do
  
  # 1 day = 86400 seconds

  IO.puts "Connect Socket"
  IO.inspect user
  if user == "Guest" do
    name = "Guest"
  else
    #IO.puts "TToken"
    token = Map.get(user, "token")
    #IO.inspect token

    case Token.verify(socket, "user", token, max_age: 1) do
      {:ok, user_id} ->

        IO.puts ""
        IO.puts "Socket Verifies User!"
        IO.puts ""
        socket = assign(socket, :current_user, Repo.get!(User, user_id))
        

        {:ok, socket}
      {:error, _} ->
        IO.puts ""
        IO.puts "Socket Couldn't Verify User!"
        IO.puts ""
        :error
    end

    name = Map.get(user, "name")
  end
 

  {:ok, assign(socket, :user, name)}
end


  
  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "users_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     TwitterServer.Endpoint.broadcast("users_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil
end
