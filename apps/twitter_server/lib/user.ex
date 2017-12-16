defmodule User do
    use GenServer 

    def main(args) do
        num_user = args
        start_time = :os.system_time(:millisecond)
        server = "server@" <> get_ip_addr()
        client = "client@" <> get_ip_addr()
        Node.start(String.to_atom(client))
        Node.set_cookie :"srishti"
        Node.connect(String.to_atom(server))
        IO.inspect Node.list
        test_func(num_user)
        IO.puts "back from test***********@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%"
        end_time = :os.system_time(:millisecond)
        IO.puts "time taken"
        IO.inspect end_time-start_time

    end

    def test_func(args) do
        prefix = "user"
        num_users = args
        users = Enum.to_list(1..num_users)
        #IO.inspect users
        Enum.each(users, fn(i)-> username = prefix<>to_string(i)
                                  password = prefix<>to_string(i) 
                                  #IO.inspect username
                                  create_user(username,password) 
                                  IO.puts "user created: "<>username
                                end)
        IO.puts "-----------------------------"
        IO.puts "-----------------------------"
        Enum.each(users, fn(i)-> username = prefix<>to_string(i)
                                  password = prefix<>to_string(i) 
                                  #IO.inspect username
                                  go_online(username,password) 
                                  IO.puts "user online: "<>username
                                end)
        weighted_list = get_zipf_distribution(num_users)
        IO.inspect weighted_list
        Enum.each(users, fn(i)-> username = prefix<>to_string(i)
                                  password = prefix<>to_string(i) 
                                  IO.inspect username
                                  spawn fn->test_func2(username, password, weighted_list,num_users)end
                                  IO.puts "spawn test for "<>username
                                end)   

                                :timer.sleep(10000)                      
        #IO.gets ""
    end

    def get_ip_addr do 
        {:ok,lst} = :inet.getif()
        z = elem(List.last(lst),0) 
        if elem(z,0)==127 do
        x = elem(List.first(lst),0)
        addr =  to_string(elem(x,0)) <> "." <>  to_string(elem(x,1)) <> "." <>  to_string(elem(x,2)) <> "." <>  to_string(elem(x,3))
        else
        x = elem(List.last(lst),0)
        addr =  to_string(elem(x,0)) <> "." <>  to_string(elem(x,1)) <> "." <>  to_string(elem(x,2)) <> "." <>  to_string(elem(x,3))
        end
        addr  
    end

    def start_link(username,password) do
        #IO.inspect username
        #IO.puts "Client server starting for username: #{username}"
        spawn fn->GenServer.start_link(User, {username,password},name: String.to_atom(username)) end
        #IO.puts "Client server initialized for username: #{username}"
    end

    def init(args) do
        username = elem(args,0)
        password = elem(args,1)
        initial_data = %{"username" => username, "password" => password, "tweets" => [], "followers" => [], "following" => [], "dashboard" => []}
        {:ok,initial_data}
    end

    def create_user(username,password) do
        IO.puts "in create user-user"
        #access main server's user list to check if this user already exists
        user_exists = GenServer.call(String.to_atom("mainserver"),{:check_user,{username}}, :infinity)
        #IO. puts"user exists: "<> user_exists
        if user_exists == false do
            user = GenServer.call(String.to_atom("mainserver"), {:add_new_user, {username, password}},:infinity)
        end
        user
    end

    def go_online(username,password) do 
        user_state = GenServer.call(String.to_atom("mainserver"),{:get_user_state, {username}},:infinity)
        #User.go_online(user_state,username,password)
        pid = User.start_link(username,password)
        #IO.inspect pid
        IO.puts "--------"
        #IO.inspect username
        spawn fn->GenServer.call(String.to_atom(username),{:go_online, {username, password}},:infinity) end
    end

    def post_tweet(tweet, username) do
        #IO.inspect username
        #IO.inspect tweet
        IO.puts "in post tweet:user"
        spawn fn -> GenServer.call(String.to_atom(username), {:tweet, {tweet, username}},:infinity) end
        my_state = GenServer.call(String.to_atom(username), {:get_user_state,{}},:infinity)
        IO.puts "new tweet by user" <> to_string(username)
        
        follower_list = Map.get(my_state, "followers")
        tweet_list = Map.get(my_state,"tweets")
        IO.puts "printing tweet list and state"
        IO.inspect my_state
        #IO.inspect tweet_list
        new_tweet = Enum.at(tweet_list,0)
        Enum.each(follower_list, fn(follower) ->
            spawn fn ->GenServer.call(String.to_atom(follower), {:update_dashboard, {new_tweet}},:infinity) end
        end)
        #IO.puts "_______________________"
        #IO.inspect new_tweet
        if new_tweet != nil do
            parse_hashtag(new_tweet,username)
            parse_mentions(new_tweet,username)
        end
    end

    def follow(username, my_name) do
        IO.puts "in follow:user"
        followee_state = GenServer.call(String.to_atom(username),{:get_user_state,{}})
        spawn fn->GenServer.call(String.to_atom(my_name), {:follow,{username,followee_state, my_name}},:infinity) end
    end

    def go_offline(username) do
        spawn fn->GenServer.call(String.to_atom(username), {:go_offline, {username}},:infinity) end
    end

    def handle_call({:go_offline,args},_from, my_state) do
        IO.puts "in go_offline wrapper"
        username = elem(args,0)
        if pid = Process.whereis(String.to_atom(username)) != nil do
            IO.puts "pid available"
            logout = GenServer.call(String.to_atom("mainserver"), {:go_offline, {my_state, username}},:infinity)   
            pid = Process.whereis(String.to_atom(username)) 
            IO.inspect pid
        logout = GenServer.stop(pid, :normal)
            IO.puts "check"
            IO.inspect logout
            IO.puts "********ogged out user**********"
            # if logout == true do
            #     IO.puts "Successfully logged out"
            # else
            #     IO.puts "could not log out"
            # end
        else
            IO.puts "You're offline'"
        end
        {:reply, my_state, my_state}
    end

    def create_numbered_users(num_users) do
        for i <-1..num_users do
            prefix = "user"
            username = prefix<>to_string(i)
            password = prefix<>to_string(i)
            user_exists = GenServer.call(String.to_atom("mainserver"),{:check_user,{username}},:infinity)
            if user_exists == false do
                user_pid = User.start_link(username,password)
                user = GenServer.call(String.to_atom("mainserver"), {:add_new_user, {username, password}},:infinity)
                IO.puts "user created" <> username
            end
        end
        GenServer.call(String.to_atom("mainserver"), {:zipf,{num_users}},:infinity)

    end

    def handle_call({:go_online, args}, _from, my_state) do
        username = elem(args,0)
        password = elem(args,1)
        IO.puts "user online: "<> username
        user_state = GenServer.call(String.to_atom("mainserver"), {:get_user_state,{username}},:infinity)
        #IO.inspect user_state
        tweets = Map.get(user_state, "tweets")
        followers = Map.get(user_state,"followers")
        following = Map.get(user_state, "following")
        if following != nil do
            Enum.each(following, fn(user) ->
                spawn fn -> GenServer.call(String.to_atom(username),{:create_dashboard, {user}},:infinity) end
            end)
        end
        my_state = user_state
        {:reply, my_state, my_state}
    end

    def handle_call({:tweet, args},_from, my_state) do
        IO.puts "in post tweet handle call"

        tweet = elem(args,0)
        username = elem(args,1)

        tweets_list = Map.get(my_state, "tweets")
        if List.first(tweets_list) == nil do
            last_id = -1
        else
            last_id = elem(List.first(tweets_list),0)
        end
        new_tweet_id = last_id + 1
        new_tweet = {new_tweet_id, tweet,:os.system_time(:millisecond),username}
        if tweets_list == nil do 
            tweets_list = [new_tweet]
        else
            tweets_list = [new_tweet|tweets_list]
        end

        my_state = Map.put(my_state, "tweets", tweets_list)
        my_dashboard = Map.get(my_state, "dashboard")
        
        my_dashboard = Enum.concat([new_tweet],my_dashboard)
        my_state = Map.put(my_state,"dashboard",my_dashboard)

        {:reply, my_state, my_state}
    end

    def handle_call({:follow, args}, _from, my_state) do
        username = elem(args,0)
        followee_state = elem(args,1)
        my_name = elem(args,2)
        IO.puts "in user's follow"
        
        following_list = Map.get(my_state,"following") 
        if Enum.member?(following_list,username) do
            IO.puts "already following"
            false
        else
            following_list = Enum.concat([username],following_list)
            my_state = Map.put(my_state, "following", following_list)
            pid = Process.whereis(String.to_atom(username))

            if pid == nil do
                spawn fn->GenServer.call(String.to_atom("mainserver"),{:add_follower,{username, my_name}},:infinity) end
            else
                #add_follower(username, my_name)
                spawn fn->GenServer.call(String.to_atom(username),{:add_to_follower,{username, my_name}},:infinity) end
            end
            
            #update my dashboard with user's tweets'
            my_dashboard = Map.get(my_state, "dashboard")
            #IO.inspect Map.get(my_state,"username")
            #followee_state = GenServer.call(String.to_atom(username),{:get_user_state,{}},1000)
            #followee_state = get_state(username)
            #followee_tweets = ""
            followee_tweets = Map.get(followee_state,"tweets")
            #IO.inspect followee_tweets
            #IO.puts "****"
            my_dashboard = Enum.concat(my_dashboard,followee_tweets)

            my_state = Map.put(my_state, "dashboard", my_dashboard)
            #IO.puts "my state after following a user: "
            IO.inspect my_state
        end
        
        {:reply, my_state, my_state}
    end

    def add_follower(username, my_name) do
        spawn fn-> GenServer.call(String.to_atom(username),{:add_to_follower,{username,my_name}},:infinity) end
    end

    def handle_call({:add_to_follower, args}, _from ,my_state) do
        IO.puts "in add follower handle"
        username = elem(args,0)
        my_name = elem(args,1)

        follower_list = Map.get(my_state,"followers")
        if List.first(follower_list) == nil do
            follower_list = [my_name]
        else
            follower_list = [my_name|follower_list]    
        end
        my_state = Map.put(my_state, "followers", follower_list) 
        IO.puts "check follower's list after adding follower'"
        IO.inspect my_state
        
        {:reply,my_state, my_state}   
    end

    def handle_call({:create_dashboard, args}, _from, my_state) do
        username = elem(args,0)
        my_dashboard = Map.get(my_state, "dashboard")
    
        tweets = GenServer.call(String.to_atom(username),{:get_tweets, {username}},:infinity)
        my_dashboard = Enum.concat(my_dashboard,tweets)
        IO.puts "dashboard bulk update"
        #IO.inspect my_dashboard
        my_state = Map.put(my_state, "dashboard", my_dashboard)
        IO.inspect my_state
        {:reply, my_state, my_state}
    end

    def update_dashboard(follower, new_tweet) do
        spawn fn -> GenServer.call(String.to_atom(follower), {:update_dashboard, {new_tweet}},:infinity) end
    end

    def handle_call({:update_dashboard, args}, _from, my_state) do
        #IO.puts "in new update call"
        tweet = [elem(args,0)]
        my_dashboard = Map.get(my_state, "dashboard")
        my_dashboard = Enum.concat(my_dashboard,tweet)
        #IO.puts "dashboard single tweet update"
        #IO.inspect my_dashboard
        my_state = Map.put(my_state, "dashboard", my_dashboard)
        IO.inspect my_state
        {:reply, my_state, my_state}
    end

    def get_tweets(username) do
        #IO.puts "hereeee"
        #IO.inspect username
        tweets = GenServer.call(String.to_atom(username),{:get_tweets, {}},:infinity)
        #IO.inspect tweets 
        tweets
    end

    def handle_call({:get_tweets ,args}, _from, user_state) do
        #IO.puts "in get tweets list"
        if user_state != nil do
            tweets = Map.get(user_state, "tweets")
        end
        {:reply, tweets, user_state}
    end

    def retweet(tweet_id, username, my_name) do
        IO.puts "Retweet 1"
        my_state = GenServer.call(String.to_atom(my_name),{:retweet,{tweet_id, username, my_name}},:infinity)
        tweet_list = Map.get(my_state,"tweets")
        new_tweet = Enum.at(tweet_list,0)
        follower_list = Map.get(my_state, "followers")
            Enum.each(follower_list, fn(follower) ->
                #GenServer.call(String.to_atom(follower), {:update_dashboard, {new_tweet}},10000)
                update_dashboard(follower, new_tweet)
            end)
        parse_hashtag(new_tweet,username)
        parse_mentions(new_tweet,username)
    end

    def handle_call({:retweet, args}, _from, my_state) do
        IO.puts "in retweet handle call"
        username = elem(args,1)
        tweet_id = elem(args,0)
        my_name = elem(args,2)
        tweet_list = Map.get(my_state,"tweets")
        if List.first(tweet_list) == nil do
            last_tweet_id = -1 
        else
            last_tweet_id = elem(List.first(tweet_list),0)
        end
        new_tweet_id = last_tweet_id + 1
        user_state = GenServer.call(String.to_atom(username),{:get_user_state, {}},:infinity)
        tweets = GenServer.call(String.to_atom(username), {:get_tweets, {user_state}},:infinity)
        tweet = elem(Enum.at(Enum.reverse(tweets), tweet_id),1)
        #IO.puts "printing tweet string before retweeting"
        #IO.inspect tweet
        if tweet != nil do
            new_tweet = {new_tweet_id, tweet,:os.system_time(:millisecond),my_name, username}
            tweet_list = Enum.concat([new_tweet],tweet_list)
            my_state = Map.put(my_state, "tweets", tweet_list)

            #update my dashboard
            my_dashboard = Map.get(my_state, "dashboard")
            my_dashboard = Enum.concat([new_tweet],my_dashboard)
            my_state = Map.put(my_state,"dashboard",my_dashboard)

            #update dashboards of my followers
            IO.inspect "updating dashboard for every follower"
            follower_list = Map.get(my_state, "followers")
            # Enum.each(follower_list, fn(follower) ->
            #     #GenServer.call(String.to_atom(follower), {:update_dashboard, {new_tweet}},10000)
            #     update_dashboard(follower, new_tweet)
            # end)
        end
        #parse_hashtag(new_tweet,username)
        #parse_mentions(new_tweet,username)
        IO.inspect my_state

        {:reply, my_state, my_state}

    end

    def parse_hashtag(new_tweet, username) do
        #IO.puts "in parse"
        IO.puts "New tweet"
        IO.inspect new_tweet
        tweet = elem(new_tweet,1)
        IO.puts "Parsed tweet"
        IO.inspect tweet
        #tweet
        words = String.split(tweet, " ", trim: true)
        Enum.each(words, fn(word) ->
            if String.at(word,0) == "#" do
                spawn fn->GenServer.call(String.to_atom("mainserver"), {:add_hashtag, {username, new_tweet, word}},:infinity) end
            end
        end)
    end

    def parse_mentions(new_tweet, username) do
        #IO.puts "wwwwwwwwwwwwwwwwwwwwwwwwwwww"
        tweet = elem(new_tweet,1)
        words = String.split(tweet, " ", trim: true)
        Enum.each(words, fn(word) ->
            if String.at(word,0) == "@" do
                #IO.puts "mention found"
                spawn fn ->GenServer.call(String.to_atom("mainserver"), {:add_mentions, {username, tweet, word}},:infinity) end
            end
        end)
    end

    def get_state(username) do
        my_state = GenServer.call(String.to_atom(username),{:get_user_state, username},:infinity)
        my_state
    end

    def handle_call({:get_user_state ,args},_from,my_state) do          
        {:reply,my_state,my_state}
    end

    def retweet(tweet_id,username, my_name) do
        pid = Process.whereis(String.to_atom(my_name))
        if pid != nil do
            spawn fn->GenServer.call(pid, {:retweet, {username, tweet_id, my_name}},:infinity) end
        else
            false
        end
    end  

    def handle_call({:zipf, args}, _from, my_state) do
        num_users = elem(args,0)
        #IO.puts "in zipf handle call"

        users_map = Map.get(my_state,"users")
        #IO.inspect users_map
        distribution_list = []
        usernames = Map.keys(users_map)
        #IO.inspect usernames
        #num_users = 10
        weighted_list = get_zipf_distribution(num_users)
        
        #IO.puts "printing weighted list"
        #IO.inspect weighted_list
        
        {:reply, weighted_list, my_state}
    end

    def get_zipf_distribution(numberofClients) do
        distList=[]
        s=1
        c=getConstantValue(numberofClients,s)
        distList=Enum.map(1..numberofClients,fn(x)->
            :math.ceil((c*numberofClients)/:math.pow(x,s)) 
            end)
        distList
    end

    def getConstantValue(numberofClients,s) do
        k=Enum.reduce(1..numberofClients,0,fn(x,acc)->
            :math.pow(1/x,s)+acc 
            end )
        k=1/k
        k
    end  

    def test_func2(username,password,weighted_list,num_users) do
        #tweet random stuff
        #IO.puts "----------$$$----------"
        #IO.inspect username
        #IO.inspect num_users
        #IO.inspect weighted_list
        tweet_common_string = "my tweet number: "
        #num_followers = 2
        num_tweets = 2
        hashtags = ["#first", "#hello", "#elixir", "mytweet"]
        mentions = ["@sri", "@karan", "@abhi", "@keyur"]
        #IO.inspect random_followers
        #tweet
        for i<-1..num_users do
            freq = round(Enum.at(weighted_list,i-1))
            IO.puts "-----------------------------------------------------------------"
            IO.inspect freq
            random_followers = choose_random_users_to_follow(username, num_users, freq)
            for 1<- 1..freq do
                Enum.each(random_followers, fn(follower) ->
                    follower = "user"<>to_string(follower)
                    follow(username,follower)
                end)
            end
        end

        query_hashtag()
        query_mention()
        
        for i<-1..num_users do
            freq = round(Enum.at(weighted_list,i-1))
            #IO.puts "printing freq $$$%%%%%%%$$$$$$"<> to_string(freq)
            #IO.inspect freq
            random_followers = choose_random_users_to_follow(username, num_users, freq)
            for 1<- 0..freq do
                hashtag = Enum.random(hashtags)
                mention = Enum.random(mentions)
                tweet_pattern1 = username <> tweet_common_string <> to_string(i) <> " "<> hashtag
                tweet_patter2 = username <> tweet_common_string <> to_string(i) <> " " <>mention
                tweet_pattern3 = username <> tweet_common_string <> to_string(i)
                post_tweet(tweet_pattern1,username) 
                post_tweet(tweet_patter2,username)
            end
        end

        

        

        #retweet random tweets
        # for i<-1..num_users do
        #     freq = round(Enum.at(weighted_list,i-1))
        #     for 1<- 1..round(Float.ceil(freq/2,2)) do
        # #freq = round(Float.ceil(freq/2,2))
        #         user_state = GenServer.call(String.to_atom(username),{:get_user_state, {}},10000)
        #         followers_list = Map.get(user_state,"followers")
        #         retweet(0,username,Enum.random(followers_list))
        #     end
        # end
        test_offline(num_users)
        #IO.gets ""
    end


    def choose_random_users_to_follow(username, num_users, num_followers) do
        #IO.puts "in random follower"
        #IO.puts "----------$$$----------"
        #IO.inspect username
        #IO.inspect num_users
        prefix = "user"
        users = Enum.to_list(1..num_users)
        #IO.inspect users
        user_number = String.to_integer(Enum.at(String.split(username,"user"),1))

        #IO.inspect user_number
        users = List.delete(users, user_number)
        #IO.inspect users
        random_followers = Enum.take_random(users,num_followers)
        #IO.inspect random_followers
        
        random_followers
    end

    def test_offline(num_users) do
        user_list = Enum.to_list(1..num_users)
        offline_list = Enum.take_random(user_list,round(num_users*0.05))
        Enum.each(offline_list, fn(user) ->
            user = "user"<>to_string(user)
            go_offline(user)
            go_online(user,user)
            end)
    end

    def query_hashtag() do
        #IO.puts "8888888 query hashtag"
        hashtags = ["#first", "#hello", "#elixir", "mytweet"]
        hashtag = Enum.random(hashtags)
        hashtag = "#first"
        spawn fn-> GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())}, {:query_hashtag,{hashtag}},10000) end
        
    end

    def query_hashtag(tag) do
        #IO.puts "8888888 query hashtag"
        #hashtags = ["#first", "#hello", "#elixir", "mytweet"]
        hashtag = tag
        GenServer.call(String.to_atom("mainserver"), {:query_hashtag,{hashtag}},10000) 
        
    end

    def query_mention() do
        #IO.puts "check metions queryyyyy"
        mentions = ["@sri", "@karan", "@abhi", "@keyur"]
        mention = Enum.random(mentions)
        mention = "@sri"
        spawn fn->  GenServer.call({String.to_atom("mainserver"),String.to_atom("server@"<>get_ip_addr())}, {:query_mention, {mention}},10000) end

    end
end


#users = [{"sri","mis"},{"abhi","mis"},{"karan","mis"},{"keyur","mis"},{"aru","mis"}]
        #Enum.each(users, fn user-> username = elem(user,0) 
        #                       password = elem(user,1) 
        #end)
        #check to register an existing username, should prompt user exists
        # create_user("keyur", "mis")

        # #login
        # go_online("sri","mis")
        # go_online("abhi","mis")
        # go_online("karan","mis")
        # go_online("keyur","mis")
        # go_online("aru","mis")

        #user goes offline
        #go_offline("keyur")
        #user goes online/login

        # follow("sri", "karan")
        # follow("sri", "keyur")
        # post_tweet("hello, this is my second tweet", "sri")
        # post_tweet("hello, Karan's #first tweet", "karan")
        # post_tweet("hello, Karan's #second tweet", "karan")
        # post_tweet("hello, Karan's 3rd tweet", "karan")

        # post_tweet("hello, keyur's first tweet", "keyur")
        # post_tweet("hello, @abhi's first tweet", "abhi")

        # #follow other users
        # follow("karan", "keyur")

        # #retweet one from your dashboard
        # retweet(0, "karan", "sri")

        #query on a hasgtag
        
        #go offline
        #go_offline("sri")
        #follow("sri","keyur")