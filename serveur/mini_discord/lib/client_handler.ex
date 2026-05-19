defmodule MiniDiscord.ClientHandler do
  require Logger

  def chiffrer_message(msg) when is_binary(msg) do
    cle = MiniDiscord.get_cle()
    iv = :crypto.strong_rand_bytes(16)
    msg_chiffre = :crypto.crypto_one_time(:aes_256_ctr, cle, iv, msg, true)
    iv <> msg_chiffre
  end

  def dechiffrer_message(msg_recu) when is_binary(msg_recu) do
    cle = MiniDiscord.get_cle()
    <<iv::binary-size(16), msg_chiffre::binary>> = msg_recu
    :crypto.crypto_one_time(:aes_256_ctr, cle, iv, msg_chiffre, false)
  end

  def start(socket) do
    msg_chiffre = chiffrer_message("Bienvenue sur MiniDiscord!\r\n")
    :gen_tcp.send(socket, msg_chiffre)
    pseudo = choisir_pseudo(socket)
    msg_chiffre = chiffrer_message("Salons disponibles : #{salons_dispo()}\r\n")
    :gen_tcp.send(socket, msg_chiffre)
    msg_chiffre = chiffrer_message("Rejoins un salon (ex: general) : ")
    :gen_tcp.send(socket, msg_chiffre)
    {:ok, salon_recu} = :gen_tcp.recv(socket, 0)
    try do
      salon = dechiffrer_message(salon_recu)
      salon = String.trim(salon)
      rejoindre_salon(socket, pseudo, salon)
    rescue
      _ ->
        msg_chiffre = chiffrer_message("Erreur lors de la réception du salon\r\n")
        :gen_tcp.send(socket, msg_chiffre)
    end
  end

  defp choisir_pseudo(socket) do
    msg_chiffre = chiffrer_message("Entre ton pseudo : ")
    :gen_tcp.send(socket, msg_chiffre)
    {:ok, pseudo_recu} = :gen_tcp.recv(socket, 0)
    try do
      pseudo = dechiffrer_message(pseudo_recu)
      pseudo = String.trim(pseudo)
      if pseudo_disponible?(pseudo) do
        reserver_pseudo(pseudo)
        pseudo
      else
        msg_chiffre = chiffrer_message("Ce pseudo est déjà pris!\r\n")
        :gen_tcp.send(socket, msg_chiffre)
        choisir_pseudo(socket)
      end
    rescue
      _ ->
        msg_chiffre = chiffrer_message("Erreur lors de la réception du pseudo\r\n")
        :gen_tcp.send(socket, msg_chiffre)
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
    msg_chiffre = chiffrer_message("📢 #{pseudo} a rejoint ##{salon}\r\n")
    MiniDiscord.Salon.broadcast(salon, msg_chiffre)
    msg_chiffre = chiffrer_message("Tu es dans ##{salon} — écris tes messages !\r\n")
    :gen_tcp.send(socket, msg_chiffre)

    loop(socket, pseudo, salon)
  end

  defp loop(socket, pseudo, salon) do
    receive do
      {:message, msg} ->
        :gen_tcp.send(socket, msg)
    after 0 -> :ok
    end

    case :gen_tcp.recv(socket, 0, 100) do
      {:ok, msg_recu} ->
        try do
          msg = dechiffrer_message(msg_recu)
          msg = String.trim(msg)
          if String.starts_with?(msg, "/") do
            gerer_commande(socket, pseudo, salon, msg)
            loop(socket, pseudo, salon)
          else
            msg_chiffre = chiffrer_message("[#{pseudo}] #{msg}\r\n")
            MiniDiscord.Salon.broadcast(salon, msg_chiffre)
            loop(socket, pseudo, salon)
          end
        rescue
          _ ->
            Logger.error("Erreur lors du déchiffrement du message")
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
    case String.split(commande) do
      ["/list"] ->
        salons = MiniDiscord.Salon.lister()
        message = "Salons disponibles : #{Enum.join(salons, ", ")}\r\n"
        msg_chiffre = chiffrer_message(message)
        :gen_tcp.send(socket, msg_chiffre)

      ["/join", nouveau_salon] ->
        MiniDiscord.Salon.quitter(salon, self())
        msg_chiffre = chiffrer_message("👋 #{pseudo} a quitté ##{salon}\r\n")
        MiniDiscord.Salon.broadcast(salon, msg_chiffre)

        case Registry.lookup(MiniDiscord.Registry, nouveau_salon) do
          [] ->
            DynamicSupervisor.start_child(
              MiniDiscord.SalonSupervisor,
              {MiniDiscord.Salon, nouveau_salon})
          _ -> :ok
        end

        MiniDiscord.Salon.rejoindre(nouveau_salon, self())
        msg_chiffre = chiffrer_message("📢 #{pseudo} a rejoint ##{nouveau_salon}\r\n")
        MiniDiscord.Salon.broadcast(nouveau_salon, msg_chiffre)
        msg_chiffre = chiffrer_message("Tu es maintenant dans ##{nouveau_salon}\r\n")
        :gen_tcp.send(socket, msg_chiffre)

      ["/quit"] ->
        msg_chiffre = chiffrer_message("👋 #{pseudo} a quitté ##{salon}\r\n")
        MiniDiscord.Salon.broadcast(salon, msg_chiffre)
        MiniDiscord.Salon.quitter(salon, self())
        liberer_pseudo(pseudo)
        msg_chiffre = chiffrer_message("À bientôt!\r\n")
        :gen_tcp.send(socket, msg_chiffre)
        :gen_tcp.close(socket)

      _ ->
        msg_chiffre = chiffrer_message("Commande inconnue\r\n")
        :gen_tcp.send(socket, msg_chiffre)
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
