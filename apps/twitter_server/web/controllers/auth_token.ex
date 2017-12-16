defmodule AuthToken do
    alias Plug.Crypto.MessageVerifier, as: Verifier

    require Logger

    alias Plug.Crypto.KeyGenerator, as: Generator
    
    # get the secret key
    defp fetch_secret(value_secret_key_base, k_salt, opts) do
        k_iterations = Keyword.get(opts, :key_iterations, 1000)

        k_length = Keyword.get(opts, :key_length, 32)

        k_digest = Keyword.get(opts, :key_digest, :sha256)

        key_opts = [iterations: k_iterations,
                    length: k_length,
                    digest: k_digest,
                    cache: Plug.Keys]
        Generator.generate(value_secret_key_base, k_salt, key_opts)
      end    


    #this method encodes data and signs with the key
    def sign(scope, k_salt, k_data, opts \\ []) when is_binary(k_salt) do
      {signed_at_seconds, key_opts} = Keyword.pop(opts, :signed_at)

      signed_at_ms = if signed_at_seconds, do: trunc(signed_at_seconds * 1000), else: now_ms()
      
      #generate the key
      k_secret = fetch_base_key(scope) 
                 |> fetch_secret(k_salt, key_opts)
        
      #verify the sign in
      %{data: k_data, signed: signed_at_ms}
      |> :erlang.term_to_binary()
      |> Verifier.sign(k_secret)

    end
    

    #this method verifies the data by decoding with the signed key
    def verify(scope, k_salt, k_token, opts \\ [])

    def verify(_scope, k_salt, nil, _opts) when is_binary(k_salt) do
        
              {:error, :missing}
              
            end
  
    def verify(scope, k_salt, k_token, opts) when is_binary(k_salt) and is_binary(k_token) do
      k_secret = scope 
                |> fetch_base_key() 
                |> fetch_secret(k_salt, opts)
  
      max_age_ms =
        if max_age_secs = opts[:max_age] do
          trunc(max_age_secs * 1000)
        else
          Logger.warn ":max_age not set in the key token!"
          nil
        end
  
      case Verifier.verify(k_token, k_secret) do
        {:ok, message} ->

          %{data: data, signed: signed} = Plug.Crypto.safe_binary_to_term(message)
  
          if max_age_ms && (signed + max_age_ms) < now_ms() do

            {:error, :expired}

          else

            {:ok, data}

          end
        :error ->
          {:error, :invalid}
      end
    end
  


    defp fetch_base_key(endpoint) when is_atom(endpoint),
    do: fetch_endpoint_base(endpoint)    

    defp fetch_base_key(string) when is_binary(string) and byte_size(string) >= 20,
    do: string    
    
    defp fetch_base_key(%Plug.Conn{} = conn),
      do: conn 
          |> Phoenix.Controller.endpoint_module() 
          |> fetch_endpoint_base()

    defp fetch_base_key(%Phoenix.Socket{} = socket),
      do: fetch_endpoint_base(socket.endpoint)


    defp now_ms, do: System.system_time(:milliseconds)

  
    defp fetch_endpoint_base(endpoint) do
      endpoint.config(:secret_key_base) || raise """
      no :secret_key_base is not set up.

      """
    end
  

  
    
  end