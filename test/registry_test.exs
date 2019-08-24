defmodule RegistryTest do
  use ExUnit.Case

  test "add to registry" do
    {:ok, pid} = GpsReader.Registry.start_link(:whatever)
    assert %{ all: [] } == GpsReader.Registry.show(pid)
    GpsReader.Registry.add(pid, :id_foo, :pid_a)
    GpsReader.Registry.add(pid, :id_bar, :pid_a)
    GpsReader.Registry.add(pid, :id_foo, :pid_b)
    GpsReader.Registry.add(pid, :id_cat, :pid_b)
    GpsReader.Registry.add(pid, :id_foo, self())
    assert %{ id_foo: [:pid_a, :pid_b, self()], id_bar: [:pid_a], id_cat: [:pid_b], all: [] } == GpsReader.Registry.show(pid)
    GpsReader.Registry.remove(pid, :id_foo, :pid_a)
    GpsReader.Registry.remove(pid, :id_bar, :pid_a)
    GpsReader.Registry.remove(pid, :id_cat, :pid_a)
    GpsReader.Registry.remove(pid, :id_nop, :pid_a)
    assert %{ id_foo: [:pid_b, self()], id_bar: [], id_cat: [:pid_b], id_nop: nil, all: [] } == GpsReader.Registry.show(pid)
    GpsReader.Registry.send(pid, {:id_foo, :this_is_some_data})
    assert_receive { :id_foo, :this_is_some_data }
  end

end
