defmodule GpsReaderTest do
  use ExUnit.Case

  test "basic test" do
    GpsReader.register([:GGA], self())
    GpsReader.Receiver.manual("$GPGGA,043811.000,4149.2342,N,07125.9667,W,1,08,1.13,33.1,M,-34.2,M,,*63")
    assert_receive {
      :GGA,
      %{
        altitude: %{units: "M", value: "33.1"},
        at: %{hours: "04", minutes: "38", seconds: "11.000"},
        hdop: "1.13",
        latitude: %{direction: "N", hours: "41", minutes: "49.2342"},
        longitude: %{direction: "W", hours: "07", minutes: "125.9667"},
        quality: :gps,
        satellites_tracked: "08"
      }
    }
    GpsReader.unregister([:GGA], self())
  end
end
