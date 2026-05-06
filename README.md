# petit-discord
TP Programmation Fonctionelle

Phase 1 

Q1. On utilise le Process.monitor pour savoir lorsque le processus en question meurt afin d'en informer les autres.
Cela est utile notament lorsque un utilisateur ce déconnecte.

Q2. Le handle_info {:DOWN} est utilisé lorsqu'un utilisateur quitte l'application. Avec la fonction
monitor, Elixir envoi un message de type :DOWN à la fonction. Ainsi on peut alors retirer le PID de 
l'utilisateur qui à quitté le chat de la liste des utilisateurs.

Q3. handle_call attend une réponse (synchrone) alors que handle_cast se contente d'envoyer le message
a tout les autres utilisateurs (asynchrone). Broadcast est un cast puisque l'utilisateur quitte notre 
chat, on n'a pas besoin de réponse, l'action est déjà faite et donc il faut informer les autres utilisateurs présents, qu'importe si le message leur parvient ou non.


Phase 2

Q4. Oui le salon redemare après le kill. En effet, si on refait un nc localhost 4040 juste après le kill, on a comme proposition le salon général, donc il a redémaré automatiquement.

Q5. Sur un one_for_one, si le process est tué, alors il redémarre automatiquement, mais pour un one_for_all, si un process est tué, alors tout les autres process sont aussi tué et redémarre tous automatiquement (y compris celui qui a été tué a la base).


TP2 Programmation Fontcionelle

Fonction Start 
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

2.3 Robustesse OTP
Elle permetrait de savoir si par exemple un client se connecte et se déconnecte en boucle (pour une attaque de déni de service par exemple), ou si un utilisateur n'arrive pas à se connecter.
En somme un suivi des processus nous aide a résoudre plusieurs problème que nous ne pourrions voir avec un redemarage automatique.

