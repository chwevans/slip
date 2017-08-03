defmodule Slip.Limiter do
  use GenServer
  require Lager

  @name __MODULE__

  def start_link, do: :gen_server.start_link({:local, @name}, __MODULE__, [], [])

  def init(_args) do
    tid = :ets.new(@name, [])
    {:ok, tid}
  end

  def state(), do: :gen_server.call(@name, :state)
  def handle_call(:state, _from, tid) do
    reply = :ets.tab2list(tid)
    {:reply, reply, tid}
  end

  def log(uid, name), do: :gen_server.cast(@name, {:log, uid, name})
  def handle_cast({:log, uid, name}, tid) do
    key = {uid, name}
    case :ets.member(tid, key) do
      true -> :ets.update_counter(tid, key, {2, 1})
      false ->
        :ets.insert(tid, {key, 1})
        0
    end

    {:noreply, tid}
  end
end
