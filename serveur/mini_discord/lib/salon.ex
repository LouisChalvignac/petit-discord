defmodule MiniDiscord.Salon do
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, %{name: name, clients: [], historique: []},
      name: via(name))
  end

  def rejoindre(salon, pid), do: GenServer.call(via(salon), {:rejoindre, pid})
  def quitter(salon, pid),   do: GenServer.call(via(salon), {:quitter, pid})
  def broadcast(salon, msg), do: GenServer.cast(via(salon), {:broadcast, msg})
  def lister do
    Registry.select(MiniDiscord.Registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  def init(state), do: {:ok, state}

  def handle_call({:rejoindre, pid}, _from, state) do
    Process.monitor(pid)
    # Send message history to the new client
    for msg <- Enum.reverse(state.historique) do
      send(pid, {:message, msg})
    end
# TODO : Monitorer le pid avec Process.monitor/1
# TODO : Retourner {:reply, :ok, nouvel_état} avec pid ajouté à state.clients
    {:reply, :ok, %{state | clients: [pid | state.clients]}}
  end

  def handle_call({:quitter, pid}, _from, state) do
# TODO : Retourner {:reply, :ok, nouvel_état} avec pid retiré de state.clients
    {:reply, :ok, %{state | clients: List.delete(state.clients, pid)}}
  end

  def handle_cast({:broadcast, msg}, state) do
    for pid <- state.clients do
      send(pid, {:message, msg})
    end
    # Add message to history, keeping only the last 10
    new_historique = [msg | state.historique] |> Enum.take(10)
# TODO : Envoyer {:message, msg} à chaque pid dans state.clients
# TODO : Retourner {:noreply, state}
    {:noreply, %{state | historique: new_historique}}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
# TODO : Retirer pid de state.clients (il s'est déconnecté)
    {:noreply, %{state | clients: List.delete(state.clients, pid)}}
# TODO : Retourner {:noreply, nouvel_état}
  end

  defp via(name), do: {:via, Registry, {MiniDiscord.Registry, name}}



end
