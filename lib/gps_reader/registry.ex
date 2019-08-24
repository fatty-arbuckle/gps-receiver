defmodule GpsReader.Registry do
  use GenServer
  require Logger

  def start_link(name) do
    GenServer.start_link(__MODULE__, {}, name: name)
  end

  def show(registry) do
    GenServer.call(registry, :show)
  end

  def add(registry, id, pid) do
    GenServer.cast(registry, { :add, id, pid })
  end

  def remove(registry, id, pid) do
    GenServer.cast(registry, { :remove, id, pid })
  end

  def send({ id, data }) do
    GenServer.cast(__MODULE__, { :send, id, data })
  end

  def send(registry, { id, data }) do
    GenServer.cast(registry, { :send, id, data })
  end

  def init(_opts) do
    { :ok, %{ all: [] } }
  end

  def handle_call(:show, _from, state) do
    { :reply, state, state }
  end

  def handle_cast({:add, id, pid }, state) do
    { :noreply, Map.put(state, id, insert(state[id], pid)) }
  end

  def handle_cast({:remove, id, pid }, state) do
    { :noreply, Map.put(state, id, delete(state[id], pid)) }
  end

  def handle_cast({:send, id, data }, state) do
    broadcast(Enum.uniq(combine(state[:all], state[id])), {id, data})
    { :noreply, state }
  end

  defp combine(nil, nil), do: []
  defp combine(a, nil),   do: a
  defp combine(nil, b),   do: b
  defp combine(a, b),     do: a++b

  defp insert(nil, item),    do: [item]
  defp insert(current, item) do
    case (item in current) do
      true  -> current
      false -> current ++ [item]
    end
  end

  defp delete(nil, _item),    do: nil
  defp delete(current, item) do
    case (item in current) do
      true  -> List.delete(current, item)
      false -> current
    end
  end

  defp broadcast(nil, _data), do: nil
  defp broadcast(pids, data) when is_list(pids) do
    Enum.each(pids, fn (pid) ->
      broadcast(pid, data)
    end)
  end
  defp broadcast(pid, data) when is_pid(pid) do
    Process.send(pid, data, [])
  end
  defp broadcast(pid, _data) do
    Logger.warn("invalid process #{pid} registered")
  end

end
