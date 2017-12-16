defmodule UserAccount.PageController do
  use UserAccount.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
