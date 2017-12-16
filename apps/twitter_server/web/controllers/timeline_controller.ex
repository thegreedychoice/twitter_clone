# Tweets Api Controller


defmodule TwitterServer.TimelineController do
    use TwitterServer.Web, :controller
    
    def index(conn, _params) do
        render conn, "index.html"
    end
end
  