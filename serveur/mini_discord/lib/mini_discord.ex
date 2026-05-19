defmodule MiniDiscord do
  use Application

  # Clé partagée commune pour le chiffrement AES-256-CTR (32 bytes)
  # À synchroniser entre client et serveur
  @cle <<"mini_discord_secret_key_32byte!!"::binary>>

  def get_cle, do: @cle

  def start(_type, _args) do
    :ets.new(:pseudos, [:named_table, :public, :set])

    children = [
      {Registry, keys: :unique, name: MiniDiscord.Registry},
      {DynamicSupervisor, strategy: :one_for_one, name: MiniDiscord.SalonSupervisor},
      MiniDiscord.ChatServer,
      {Task.Supervisor, name: MiniDiscord.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: MiniDiscord.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
