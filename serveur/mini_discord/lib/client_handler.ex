defmodule MiniDiscord.ClientHandler do
  require Logger

  def start(socket) do
    :gen_tcp.send(socket, "Bienvenue sur MiniDiscord!\r\n")
    pseudo = choisir_pseudo(socket)
    :gen_tcp.send(socket, "Salons disponibles : #{salons_dispo()}\r\n")
    :gen_tcp.send(socket, "Rejoins un salon (ex: general) : ")
    {:ok, salon} = :gen_tcp.recv(socket, 0)
    salon = String.trim(salon)
    rejoindre_salon(socket, pseudo, salon)
  end

  defp choisir_pseudo(socket) do
    :gen_tcp.send(socket, "Entre ton pseudo : ")
    {:ok, pseudo} = :gen_tcp.recv(socket, 0)
    pseudo = String.trim(pseudo)
    # TODO : Si pseudo_disponible?(pseudo) -> reserver_pseudo(pseudo) et retourner pseudo
    # TODO : Sinon -> envoyer un message d'erreur et rappeler choisir_pseudo(socket)
    if pseudo_disponible?(pseudo) do
      reserver_pseudo(pseudo)
      pseudo
    else
      :gen_tcp.send(socket, "Ce pseudo est déjà pris!\r\n")
      choisir_pseudo(socket)
    end
  end

  defp rejoindre_salon(socket, pseudo, salon) do
    case Registry.lookup(MiniDiscord.Registry, salon) do
      [] ->
        DynamicSupervisor.start_child(
          MiniDiscord.SalonSupervisor,
          {MiniDiscord.Salon, salon})
      _ -> :ok
    end

    MiniDiscord.Salon.rejoindre(salon, self())
    MiniDiscord.Salon.broadcast(salon, "📢 #{pseudo} a rejoint ##{salon}\r\n")
    :gen_tcp.send(socket, "Tu es dans ##{salon} — écris tes messages !\r\n")

    loop(socket, pseudo, salon)
  end

  defp loop(socket, pseudo, salon) do
    receive do
      {:message, msg} ->
        :gen_tcp.send(socket, msg)
    after 0 -> :ok
    end

    case :gen_tcp.recv(socket, 0, 100) do
      {:ok, msg} ->
        msg = String.trim(msg)
        # TODO : Si msg commence par "/" -> gérer_commande(socket, pseudo, salon, msg)
        # TODO : Sinon -> broadcast normal
        if String.starts_with?(msg, "/") do
          gerer_commande(socket, pseudo, salon, msg)
          loop(socket, pseudo, salon)
        else
          MiniDiscord.Salon.broadcast(salon, "[#{pseudo}] #{msg}\r\n")
          loop(socket, pseudo, salon)
        end

      {:error, :timeout} ->
        loop(socket, pseudo, salon)

      {:error, reason} ->
        Logger.info("Client déconnecté : #{inspect(reason)}")
        MiniDiscord.Salon.broadcast(salon, "👋 #{pseudo} a quitté ##{salon}\r\n")
        MiniDiscord.Salon.quitter(salon, self())
        liberer_pseudo(pseudo)
    end
  end

  defp gerer_commande(socket, pseudo, salon, commande) do
    # TODO : "/list" -> envoyer la liste des salons avec MiniDiscord.Salon.lister()
    # TODO : "/join <nom>" -> quitter le salon actuel et rejoindre le nouveau
    # TODO : "/quit" -> déconnecter proprement le client
    # TODO : _ -> envoyer "Commande inconnue"
    case String.split(commande) do
      ["/list"] ->
        salons = MiniDiscord.Salon.lister()
        message = "Salons disponibles : #{Enum.join(salons, ", ")}\r\n"
        :gen_tcp.send(socket, message)

      ["/join", nouveau_salon] ->
        MiniDiscord.Salon.quitter(salon, self())
        MiniDiscord.Salon.broadcast(salon, "👋 #{pseudo} a quitté ##{salon}\r\n")

        case Registry.lookup(MiniDiscord.Registry, nouveau_salon) do
          [] ->
            DynamicSupervisor.start_child(
              MiniDiscord.SalonSupervisor,
              {MiniDiscord.Salon, nouveau_salon})
          _ -> :ok
        end

        MiniDiscord.Salon.rejoindre(nouveau_salon, self())
        MiniDiscord.Salon.broadcast(nouveau_salon, "📢 #{pseudo} a rejoint ##{nouveau_salon}\r\n")
        :gen_tcp.send(socket, "Tu es maintenant dans ##{nouveau_salon}\r\n")

      ["/quit"] ->
        MiniDiscord.Salon.broadcast(salon, "👋 #{pseudo} a quitté ##{salon}\r\n")
        MiniDiscord.Salon.quitter(salon, self())
        liberer_pseudo(pseudo)
        :gen_tcp.send(socket, "À bientôt!\r\n")
        :gen_tcp.close(socket)

      _ ->
        :gen_tcp.send(socket, "Commande inconnue\r\n")
    end
  end

  defp salons_dispo do
    case MiniDiscord.Salon.lister() do
      [] -> "aucun (tu seras le premier !)"
      salons -> Enum.join(salons, ", ")
    end
  end

  defp pseudo_disponible?(pseudo) do
    # TODO : Vérifier avec :ets.lookup(:pseudos, pseudo) si le pseudo est déjà pris
    # TODO : Retourner true si disponible, false sinon
    :ets.lookup(:pseudos, pseudo) == []
  end

  defp reserver_pseudo(pseudo) do
    # TODO : Insérer dans :ets avec :ets.insert(:pseudos, {pseudo, self()})
    :ets.insert(:pseudos, {pseudo, self()})
  end

  defp liberer_pseudo(pseudo) do
    # TODO : Supprimer de :ets avec :ets.delete(:pseudos, pseudo)
    :ets.delete(:pseudos, pseudo)
  end
end
