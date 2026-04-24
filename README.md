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
