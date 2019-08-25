defmodule NmeaParserTest do
  use ExUnit.Case

  test "checksum failure" do
    assert(
        GpsReader.NmeaParser.parse(
          "$GPGSA,A,3,31,25,22,29,03,32,26,14,,,,,1.44,1.12,0.90*99"
        )
      ==
        {
          :bad_checksum,
          "$GPGSA,A,3,31,25,22,29,03,32,26,14,,,,,1.44,1.12,0.90"
        }
    )
  end

  test "unsupported messages" do
    assert(
        GpsReader.NmeaParser.parse(
          "$NOGSA,A,3,31,25,22,29,03,32,26,14,,,,,1.44,1.12,0.90*99"
        )
      ==
        {
          :not_supported,
          "$NOGSA,A,3,31,25,22,29,03,32,26,14,,,,,1.44,1.12,0.90*99"
        }
    )
  end

  test "GSA messages" do
    assert(
        GpsReader.NmeaParser.parse(
          "$GPGSA,A,3,31,25,22,29,03,32,26,14,,,,,1.44,1.12,0.90*05"
        )
      ==
        {
          :GSA,
          %{
            fix: {:fix_3d, "A"},
            hdop: "1.12",
            pdop: "1.44",
            satellites: ["31", "25", "22", "29", "03", "32", "26", "14", "", "", "", ""],
            vdop: "0.90"
          }
        }
    )
  end

  test "GSV messages" do
    assert(
        GpsReader.NmeaParser.parse(
          "$GPGSV,3,1,11,31,69,032,21,14,64,117,20,26,59,196,29,32,39,128,18*72"
        )
      ==
        {
          :GSV,
          %{
            in_view: "11",
            satellites: [
              %{azimuth: "032", elevation: "69", prn: "31", snr: "21"},
              %{azimuth: "117", elevation: "64", prn: "14", snr: "20"},
              %{azimuth: "196", elevation: "59", prn: "26", snr: "29"},
              %{azimuth: "128", elevation: "39", prn: "32", snr: "18"}
            ],
            sentence: {"1", "3"}
          }
        }
    )
    assert(
        GpsReader.NmeaParser.parse(
          "$GPGSV,3,3,11,25,23,045,27,23,13,309,26,43,,,*71"
        )
      ==
        {
          :GSV,
          %{
            in_view: "11",
            satellites: [
              %{azimuth: "045", elevation: "23", prn: "25", snr: "27"},
              %{azimuth: "309", elevation: "13", prn: "23", snr: "26"},
              %{azimuth: "", elevation: "", prn: "43", snr: ""},
              nil
            ],
            sentence: {"3", "3"}
          }
        }
    )
  end

  test "GGA messages" do
    assert(
        GpsReader.NmeaParser.parse(
          "$GPGGA,043811.000,4149.2342,N,07125.9667,W,1,08,1.13,33.1,M,-34.2,M,,*63"
        )
      ==
        {
          :GGA,
          %{
            at: %{hours: "04", minutes: "38", seconds: "11.000"},
            latitude: %{direction: "N", hours: "41", minutes: "49.2342"},
            longitude: %{direction: "W", hours: "07", minutes: "125.9667"},
            quality: :gps,
            satellites_tracked: "08",
            hdop: "1.13",
            altitude: %{ value: "33.1", units: "M" }
          }
        }
    )
  end

  test "GGA messages with missing coordinates" do
    assert(
        GpsReader.NmeaParser.parse(
          "$GPGGA,043811.000,,,,,1,08,1.13,33.1,M,-34.2,M,,*4A"
        )
      ==
        {
          :GGA,
          %{
            at: %{hours: "04", minutes: "38", seconds: "11.000"},
            latitude: %{direction: "???", hours: "???", minutes: "???"},
            longitude: %{direction: "???", hours: "???", minutes: "???"},
            quality: :gps,
            satellites_tracked: "08",
            hdop: "1.13",
            altitude: %{ value: "33.1", units: "M" }
          }
        }
    )
  end

end


# RAW: "RMC,043808.000,A,4149.2342,N,07125.9665,W,0.23,278.00,220819,,,A"
# "unsupported message type RMC"
# RAW: "VTG,278.00,T,,M,0.23,N,0.43,K,A"
# "unsupported message type VTG"
# RAW: "GGA,043809.000,4149.2342,N,07125.9666,W,1,08,1.13,33.1,M,-34.2,M,,"
# "unsupported message type GGA"
# RAW: "RMC,043809.000,A,4149.2342,N,07125.9666,W,0.16,275.65,220819,,,A"
# "unsupported message type RMC"
# RAW: "VTG,275.65,T,,M,0.16,N,0.30,K,A"
# "unsupported message type VTG"
# RAW: "GGA,043810.000,4149.2342,N,07125.9666,W,1,08,1.13,33.1,M,-34.2,M,,"
# "unsupported message type GGA"
# RAW: "RMC,043810.000,A,4149.2342,N,07125.9666,W,0.11,230.85,220819,,,A"
# "unsupported message type RMC"
# RAW: "VTG,230.85,T,,M,0.11,N,0.21,K,A"
# "unsupported message type VTG"
