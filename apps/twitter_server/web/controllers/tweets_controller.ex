# Tweets Api Controller


defmodule TwitterServer.TweetController do
    use TwitterServer.Web, :controller
      
      alias TwitterServer.Tweet
  
      def index(conn, _params) do
          tweets = Repo.all(Tweet)
          json conn_with_status(conn, tweets), tweets
      end
  
      def show(conn, %{"id" => id}) do
          tweet = Repo.get(Tweet, String.to_integer(id))
          #IO.inspect user
          json conn_with_status(conn, tweet), tweet
      end
  
      def create(conn, params) do

          IO.puts "params post"
          IO.inspect params
  
          
          changeset = Tweet.changeset(%Tweet{}, params)
  
          case Repo.insert(changeset) do
              {:ok, tweet} ->
                  json conn |> put_status(:created), tweet
              {:error, _changeset} ->
                  json conn |> put_status(:bad_request), %{errors: ["unable to create tweet"]}
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
  
      def push_to_timeline() do
      end

      def retweet() do
      end
    
  end
  