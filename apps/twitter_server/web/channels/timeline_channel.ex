defmodule TwitterServer.TimelineChannel do
    use TwitterServer.Web, :channel
  
    def join("timeline:feed", _payload, socket) do
      IO.puts "Joined Timeline Channel!"

      send self(), :after_join

      {:ok, socket}
    end

	def handle_info(:after_join, socket) do
        IO.puts "After join!"  

		{:noreply, socket}
	end

    def handle_in("tweet", user, socket) do
        IO.puts "Register in Channel!"
        IO.inspect user



        """
		broadcast! socket, "message:new", %{
			user: socket.assigns.user,
			body: message,
			timestamp: :os.system_time(:milli_seconds)
        }
        """
		{:noreply, socket}
    end  
    
    #when a new message arrives, broadcast to the timeline
    def handle_in("tweet:new", message, socket) do

        IO.puts "Whast"
        create_tweet(message, socket.assigns.user, false, nil)

        followers_list = get_followers(socket.assigns.user)
        followers_list = [socket.assigns.user | followers_list]

        broadcast! socket, "tweet:new", %{
            user: socket.assigns.user,
            body: message,
            timestamp: :os.system_time(:milli_seconds),
            followers: followers_list
        }
        
        #get Client state from CLient genserver
        #IO.inspect User.get_state(socket.assigns.user)

        {:noreply, socket}
      end
  
      #handle a retweet
      def handle_in("tweet:re", retweet, socket) do

        followers_list = get_followers(socket.assigns.user)
        followers_list = [socket.assigns.user | followers_list]

        full_message = Map.get(retweet, "full_message")
        original_user = Map.get(retweet, "original_user")
        current_user = Map.get(retweet, "name")
        tweet = Map.get(retweet, "tweet")

        #IO.puts "Retweet Map"
        #IO.inspect retweet

        #Post the retweet to the server!
        create_tweet(tweet, current_user, true, original_user)

         broadcast! socket, "tweet:re", %{
          user: socket.assigns.user,
          body: full_message,
          timestamp: :os.system_time(:milli_seconds),
          followers: followers_list
         }
         {:noreply, socket} 
      end

      def handle_in("follow", follow, socket) do
        
        my_name = Map.get(follow, "current_username")
        to_follow = Map.get(follow, "to_follow_username")

        add_follower(my_name, to_follow)
        
        """
        broadcast! socket, "follow:update", %{
            user: socket.assigns.user,
            body: "",
            timestamp: :os.system_time(:milli_seconds)
        }
        """
        {:noreply, socket}      
        end
      
        def handle_in("followers:get", user, socket) do
            

            #followers_list = get_followers(socket.assigns.user)

            #IO.puts "List of followers!"
            #IO.inspect followers_list

            followers_list = get_followers(socket.assigns.user)
            followers_list = [socket.assigns.user | followers_list]

            broadcast! socket, "followers:update", %{
                followers: followers_list
            }
            
            {:noreply, socket}      
        end

        def handle_in("hashtags:get", h, socket) do
            
            IO.puts "Enter hashtag handle"

            hashtag = Map.get(h, "hashtag")
            hashtagTweets = get_hashtags(hashtag)
            

            IO.puts "The real hashtag tweets!"
            IO.inspect hashtagTweets
            
            push socket, "hashtags:update", %{
                tags: hashtagTweets
            }
            
            
            {:noreply, socket}      
        end
    

      #Apis to call the Server

      def get_state(username) do
        User.get_state(username)
      end

      def create_tweet(tweet, name, isRetweet, original_user) do
        if isRetweet do
            IO.puts "Inside retweet"
            #User.retweet(tweet, original_user, name)
        else
            #add tweet to client genserver
            User.post_tweet(tweet, name)

            #add hashtags to main server

            IO.puts "List of hashtags : "
            IO.inspect find_hashtags(tweet)

            hashtags = find_hashtags(tweet)
            Enum.map(hashtags, fn(tag) -> MainServer.add_hashtag(name, tweet, tag) end)
            #MainServer.add_hashtag(name, tweet, "trump")
            


            #IO.puts "Main Server State!"
            #IO.inspect MainServer.get_state()
        end
      end

    def find_hashtags(tweet) do
        ~r/#[^\s]+/ 
        |> Regex.scan(tweet) 
        |> Enum.map(&hd/1)
    end

      def add_follower(my_name, to_follow) do
        #IO.puts "Inside Follow"
        #IO.puts "My name: #{my_name}"
        #IO.puts "To follow name: #{to_follow}"
        User.add_follower(to_follow, my_name)

        #IO.puts "Show current state:"
        #followers = get_followers(my_name)
      end

      def get_followers(my_name) do
        #IO.inspect get_state(my_name)
        Map.get(get_state(my_name), "followers")        
      end

      def get_hashtags(hashtag) do
        #s = User.query_hashtag(hashtag)


        #IO.puts "Main Server State!"
        #IO.inspect MainServer.get_state()

        hashtagTweets = MainServer.get_state()
        #["This is demo tweet"]

        IO.puts "List of Hashtag Tweet!"
        IO.inspect hashtagTweets
        
        
        IO.puts "The real hashtag"
        IO.puts hashtag

        IO.puts "First List"
        fl = Map.get(hashtagTweets, "hashtags")
        IO.inspect fl
        
        IO.puts "Second list"
        list  = Map.get(fl, hashtag)
        IO.inspect list

        
        tw_list = Enum.filter(list, fn(tweet) ->
            is_binary(tweet) == true 
        end)
        
        #tw_list = list
        tw_list
      end
  end