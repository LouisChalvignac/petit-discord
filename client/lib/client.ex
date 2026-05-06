defmodule MiniDiscord.Client do

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
      # TODO : Lire les messages du serveur avec recv_print(socket)
      recv_print(socket)
      # TODO : Envoyer le pseudo choisi par l'utilisateur avec IO.gets/1
      pseudo = IO.gets("")
      :gen_tcp.send(socket, to_charlist(pseudo))
      # TODO : Lire la suite (liste des salons)
      recv_print(socket)
      salon = IO.gets("")
      :gen_tcp.send(socket, to_charlist(salon))
      # TODO : Envoyer le nom du salon
      # TODO : Lire la confirmation
      recv_print(socket)
  end

  defp recv_print(socket) do
      case :gen_tcp.recv(socket, 0) do
        {:ok, msg} ->
          IO.write(msg)
        {:error, _} -> :ok
      end
  end

  defp receive_loop(socket) do
      # TODO : Appeler :gen_tcp.recv(socket, 0) — bloquant jusqu'à réception
      case :gen_tcp.recv(socket, 0) do
      # TODO : Si {:ok, msg} -> afficher avec IO.write/1 et rappeler receive_loop
        {:ok, msg} ->
          IO.write(msg)
          receive_loop(socket)
      # TODO : Si {:error, _} -> afficher "Déconnecté" et arrêter
        {:error, reason} ->
          IO.puts("\nDéconnecté (#{reason})")
      end
  end

  defp send_loop(socket) do
      # TODO : Lire depuis le clavier avec IO.gets("")
    message = IO.gets("")
      # TODO : Envoyer au serveur avec :gen_tcp.send/2
    :gen_tcp.send(socket, to_charlist(message))
      # TODO : Rappeler send_loop(socket)
    send_loop(socket)
  end

end
