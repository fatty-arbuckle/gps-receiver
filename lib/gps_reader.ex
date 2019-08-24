defmodule GpsReader do
  @moduledoc """
  Documentation for GpsReader.
  """

  def register(ids, pid) do
    Enum.each(ids, fn (id) ->
      GpsReader.Registry.add(GpsReader.Registry, id, pid)
    end)
  end

  def unregister(ids, pid) do
    Enum.each(ids, fn (id) ->
      GpsReader.Registry.remove(GpsReader.Registry, id, pid)
    end)
  end

end
