defmodule TwitterServer.PageController do
  use TwitterServer.Web, :controller

  def index(conn, _params) do
    #IO.inspect conn.assigns
    IO.puts "Back in Page!"
    render conn, "index.html"
  end
end
