defmodule GpsReader.Receiver do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def manual(message) do
    GenServer.cast(__MODULE__, { :manual, message })
  end

  def init(_opts) do
    {:ok, pid} = Circuits.UART.start_link
    try_connection()
    { :ok, %{ connected: false, uart: pid, devices: [], buffer: "" } }
  end

  def handle_info(
    :connect,
    %{ uart: uart } = state)
  do
    devices = Circuits.UART.enumerate
    case Enum.count(devices) do
      0 ->
        Logger.info("No UART devices")
        try_connection()
        { :ok, %{ connected: false, uart: uart, devices: devices, buffer: "" } }
      _ ->
        Logger.info("Enumerating #{Enum.count devices} UART devices")
        Enum.each(devices, fn {key, value} ->
          Logger.info(" --> device #{key}: #{value.description}")
        end)
        {name, _} = Enum.at(devices, 0)
        Logger.info("Choosing first device #{name}")
        :ok = Circuits.UART.open(uart, name, speed: 9600, active: true)
        { :ok, %{ connected: true, uart: uart, devices: devices, buffer: "" } }
    end
    { :noreply, state }
  end

  def handle_info(
    { :circuits_uart, name, {:error, error}},
    %{ uart: uart })
  do
    Logger.error("Error in serial connection to #{name}: #{error}")
    try_connection()
    {
      :noreply,
      %{
        connected: false,
        uart: uart,
        devices: [],
        buffer: ""
      }
    }
  end

  def handle_info(
    { :circuits_uart, _name, msg },
    %{ connected: connected, uart: uart, devices: devices, buffer: buffer })
  do
    updated_buffer = buffer <> msg
    GenServer.cast(__MODULE__, :process_buffer)
    {
      :noreply,
      %{
        connected: connected,
        uart: uart,
        devices: devices,
        buffer: updated_buffer
      }
    }
  end

  def handle_cast({:manual, message}, state) do
    parse([message, ""])
    {:noreply, state}
  end

  def handle_cast(
    :process_buffer,
    %{ connected: connected, uart: uart, devices: devices, buffer: buffer })
  do
    updated_buffer = case String.contains?(buffer, "\r\n") do
      true ->    # one or more full messages
        buffer
        |> String.split("\r\n")
        |> parse
      false ->    # not a full message
        buffer
    end
    {
      :noreply,
      %{
        connected: connected,
        uart: uart,
        devices: devices,
        buffer: updated_buffer
      }
    }
  end

  defp parse([]),     do: ""
  defp parse([h|[]]), do: h
  defp parse([h|t]) do
    GpsReader.NmeaParser.parse(h)
    |> GpsReader.Registry.send
    parse(t)
  end

  defp try_connection() do
    Process.send_after(self(), :connect, 10 * 1000)
  end

end
