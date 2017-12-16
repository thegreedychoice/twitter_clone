defmodule Twitter do
  #use Application
  #use GenServer

  def start(_type, _args) do
    start_main_server()
  end

  def main(args) do
    args |> parse_args
    #pid = start_main_server()
    #create_numbered_users(10)
    #create users 
    
  end


  def parse_args([]) do
      IO.puts "No arguments given" 
  end    

  def parse_args(args) do
      {_, input, _} = OptionParser.parse(args)
      start_time = :os.system_time(:millisecond)
      
      if(Enum.at(input,0)=="server") do
          start_main_server()
      end

      if(Enum.at(input,0)=="client") do
          num_users = String.to_integer(Enum.at(input,1))
          User.main(num_users)  
      end
      end_time = :os.system_time(:millisecond)
      IO.puts "time take is"
      IO.inspect end_time-start_time
      #IO.puts " Wrong input " 
  end

  def start_main_server() do
    pid = MainServer.start_link()
    IO.puts "Created Mainserevr with PID" 
    IO.inspect pid
    pid
  end

end
