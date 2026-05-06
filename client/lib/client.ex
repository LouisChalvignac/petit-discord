defmodule MiniDiscord.Client do

  @doc """
  Point d'entrée principal du client.
  host : nom type 'xxxbore.pub'
  port : entier ex: 4040
  """
  def start(host, port) do
      # TODO : Connecter la socket avec :gen_tcp.connect/3
      # TODO : Options : [:binary, packet: :line, active: false]
      case :gen_tcp.connect(to_charlist(host), port, [:binary, packet: :line, active: false]) do
        {:ok, socket} ->
          # TODO : Appeler la fonction rencontre(socket) pour le pseudo et le salon
          rencontre(socket)
          # TODO : Lancer le receiver dans un Task.async : fn -> receive_loop(socket) end
          receive_task = Task.async(fn -> receive_loop(socket) end)
          # TODO : Lancer le sender dans un Task.async : fn -> send_loop(socket) end
          send_task = Task.async(fn -> send_loop(socket) end)
          # TODO : Attendre les deux tasks avec Task.await/2 (timeout: :infinity)
          Task.await(receive_task, :infinity)
          Task.await(send_task, :infinity)
        {:error, reason} ->
          IO.puts("Erreur de connexion : #{reason}")
      end
  end

  defp rencontre(socket) do
      # TODO : Lire les messages du serveur avec recv_print(socket)
      recv_print(socket)
      # TODO : Envoyer le pseudo choisi par l'utilisateur avec IO.gets/1
      pseudo = IO.gets("Entrez le pseudo : ")
      :gen_tcp.send(socket, String.to_charlist(pseudo))
      # TODO : Lire la suite (liste des salons)
      recv_print(socket)
      salon = IO.gets("Entrez le nom du salon : ")
      :gen_tcp.send(socket, String.to_charlist(salon))
      # TODO : Envoyer le nom du salon
      # TODO : Lire la confirmation
      recv_print(socket)

  end

  defp recv_print(socket) do
      case :gen_tcp.recv(socket, 0) do
        {:ok, msg} -> IO.write(msg)
        {:error, _} -> IO.puts("Déconnecté")
      end
  end

  defp receive_loop(socket) do
      # TODO : Appeler :gen_tcp.recv(socket, 0) — bloquant jusqu'à réception
      case :gen_tcp.recv(socket, 0) do
      # TODO : Si {:ok, msg} -> afficher avec IO.write/1 et rappeler receive_loop
        {:ok, msg} -> IO.write(msg)
      # TODO : Si {:error, _} -> afficher "Déconnecté" et arrêter
        {:error, _} -> IO.puts("Déconnecté")
      end
      receive_loop(socket)
  end

  defp send_loop(socket) do
      # TODO : Lire depuis le clavier avec IO.gets("")
    message = IO.gets("")
      # TODO : Envoyer au serveur avec :gen_tcp.send/2
    :gen_tcp.send(socket, String.to_charlist(message))
      # TODO : Rappeler send_loop(socket)
    send_loop(socket)
  end

end
