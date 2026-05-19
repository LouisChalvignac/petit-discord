defmodule MiniDiscord.Client do
  # Clé partagée commune pour le chiffrement AES-256-CTR (32 bytes)
  # À synchroniser entre client et serveur
  @cle <<"mini_discord_secret_key_32byte!!"::binary>>

  @doc """
  Point d'entrée principal du client.
  host : nom type 'xxxbore.pub'
  port : entier ex: 4040
  """
def start(host, port) do
  connect_with_retry(host, port, 1)
end

defp connect_with_retry(host, port, attempt) do
  # TODO : Tenter :gen_tcp.connect avec les bonnes options
  # TODO : Si {:ok, socket} -> handshake(socket) puis lancer les deux loops
   # TODO : Si {:error, reason} ->
  # TODO :   Afficher "Tentative #{attempt} échouée : #{reason}"
  # TODO :   Attendre 2 secondes avec :timer.sleep(2000)
  # TODO :   Rappeler connect_with_retry(host, port, attempt + 1)
  case :gen_tcp.connect(to_charlist(host), port, [:binary, active: false]) do
    {:ok, socket} ->
      rencontre(socket)
      receive_task = Task.async(fn -> receive_loop(socket) end)
      send_task = Task.async(fn -> send_loop(socket) end)
      Task.await(receive_task, :infinity)
      Task.await(send_task, :infinity)
    {:error, reason} ->
      IO.puts("Tentative #{attempt} échouée : #{reason}")
      :timer.sleep(2000)
      connect_with_retry(host, port, attempt + 1)
  end
end

  defp rencontre(socket) do
      # Recevoir et déchiffrer le message de bienvenue
      case :gen_tcp.recv(socket, 0) do
        {:ok, msg_recu} ->
          try do
            msg = dechiffrer_message(msg_recu)
            IO.write(msg)
          rescue
            _ -> IO.write(msg_recu)
          end
        {:error, _} -> :ok
      end

      # Envoyer le pseudo chiffré
      pseudo = IO.gets("")
      msg_chiffre = chiffrer_message(pseudo)
      :gen_tcp.send(socket, msg_chiffre)

      # Recevoir et déchiffrer la liste des salons
      case :gen_tcp.recv(socket, 0) do
        {:ok, msg_recu} ->
          try do
            msg = dechiffrer_message(msg_recu)
            IO.write(msg)
          rescue
            _ -> IO.write(msg_recu)
          end
        {:error, _} -> :ok
      end

      # Envoyer le salon choisi chiffré
      salon = IO.gets("")
      msg_chiffre = chiffrer_message(salon)
      :gen_tcp.send(socket, msg_chiffre)

      # Recevoir et déchiffrer la confirmation
      case :gen_tcp.recv(socket, 0) do
        {:ok, msg_recu} ->
          try do
            msg = dechiffrer_message(msg_recu)
            IO.write(msg)
          rescue
            _ -> IO.write(msg_recu)
          end
        {:error, _} -> :ok
      end
  end

  defp recv_print(socket) do
      case :gen_tcp.recv(socket, 0) do
        {:ok, msg_recu} ->
          try do
            msg = dechiffrer_message(msg_recu)
            IO.write(msg)
          rescue
            _ -> IO.write(msg_recu)
          end
        {:error, _} -> :ok
      end
  end

  defp receive_loop(socket) do
      case :gen_tcp.recv(socket, 0) do
        {:ok, msg} ->
          try do
            msg_dechiffre = dechiffrer_message(msg)
            IO.write(msg_dechiffre)
          rescue
            _ -> IO.write(msg)
          end
          receive_loop(socket)
        {:error, reason} ->
          IO.puts("\nDéconnecté (#{reason})")
      end
  end

  defp send_loop(socket) do
    case IO.gets("") do
      nil ->
        :ok
      message ->
        msg_chiffre = chiffrer_message(message)
        :gen_tcp.send(socket, msg_chiffre)
        send_loop(socket)
    end
  end

  @doc """
  Chiffre un message avec AES-256-CTR.
  Retourne IV (16 bytes) concaténé au message chiffré.
  """
  defp chiffrer_message(msg) when is_binary(msg) do
    iv = :crypto.strong_rand_bytes(16)
    msg_chiffre = :crypto.crypto_one_time(:aes_256_ctr, @cle, iv, msg, true)
    iv <> msg_chiffre
  end

  @doc """
  Déchiffre un message chiffré avec AES-256-CTR.
  Extrait l'IV (16 premiers bytes) et déchiffre le reste.
  """
  defp dechiffrer_message(msg_recu) when is_binary(msg_recu) do
    <<iv::binary-size(16), msg_chiffre::binary>> = msg_recu
    :crypto.crypto_one_time(:aes_256_ctr, @cle, iv, msg_chiffre, false)
  end

end
