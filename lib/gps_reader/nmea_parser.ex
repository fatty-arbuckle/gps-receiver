defmodule GpsReader.NmeaParser do
  require Bitwise

  # https://www.gpsinformation.org/dale/nmea.htm
  # https://gpsd.gitlab.io/gpsd/NMEA.html

  def parse("$GP" <> remainder) do
    [ data | [ checksum | _ ] ] = String.split(remainder, "*")
    case checksum("GP"<>data, checksum) do
      { true, _ }  ->
        # IO.inspect(data, label: "RAW")
        parse_sentence(String.split(data, ","))
      { false, actual } ->
        IO.inspect("checksum failure had #{checksum} but expected #{actual}", label: "FAIL")
        { :bad_checksum, "$GP" <> data }
    end
  end
  def parse(ignored) do
    IO.inspect("unsupported NMEA messages: #{ignored}")
    { :not_supported, ignored }
  end

  # GSA - GPS DOP and active satellites. This sentence provides details on the nature
  # of the fix. It includes the numbers of the satellites being used in the
  # current solution and the DOP. DOP (dilution of precision) is an indication
  # of the effect of satellite geometry on the accuracy of the fix. It is a
  # unitless number where smaller is better. For 3D fixes using 4 satellites a
  # 1.0 would be considered to be a perfect number, however for overdetermined
  #  solutions it is possible to see numbers below 1.0.
  #
  # There are differences in the way the PRN's are presented which can effect
  # the ability of some programs to display this data. For example, in the
  # example shown below there are 5 satellites in the solution and the null
  # fields are scattered indicating that the almanac would show satellites in
  # the null positions that are not being used as part of this solution. Other
  # receivers might output all of the satellites used at the beginning of the
  # sentence with the null field all stacked up at the end. This difference
  # accounts for some satellite display programs not always being able to
  # display the satellites being tracked. Some units may show all satellites
  # that have ephemeris data without regard to their use as part of the solution
  # but this is non-standard.
  #
  #   $GPGSA,A,3,04,05,,09,12,,,24,,,,,2.5,1.3,2.1*39
  #
  # Where:
  #      GSA      Satellite status
  #      A        Auto selection of 2D or 3D fix (M = manual)
  #      3        3D fix - values include: 1 = no fix
  #                                        2 = 2D fix
  #                                        3 = 3D fix
  #      04,05... PRNs of satellites used for fix (space for 12)
  #      2.5      PDOP (dilution of precision)
  #      1.3      Horizontal dilution of precision (HDOP)
  #      2.1      Vertical dilution of precision (VDOP)
  #      *39      the checksum data, always begins with *
  #
  defp parse_sentence(["GSA" | fields]) do
    {
      :GSA,
      %{
        fix: {gsa_fix_to_atom(Enum.at(fields, 1)), Enum.at(fields, 0)},
        satellites: Enum.slice(fields, 2, 12),
        pdop: Enum.at(fields, 14),
        hdop: Enum.at(fields, 15),
        vdop: Enum.at(fields, 16)
      }
    }
  end

  # GSV - Satellites in View shows data about the satellites that the unit might
  # be able to find based on its viewing mask and almanac data. It also shows
  # urrent ability to track this data. Note that one GSV sentence only can
  # provide data for up to 4 satellites and thus there may need to be 3 sentences
  # for the full information. It is reasonable for the GSV sentence to contain
  # more satellites than GGA might indicate since GSV may include satellites that
  # are not used as part of the solution. It is not a requirment that the GSV
  # sentences all appear in sequence. To avoid overloading the data bandwidth some
  # receivers may place the various sentences in totally different samples since
  # each sentence identifies which one it is.
  #
  # The field called SNR (Signal to Noise Ratio) in the NMEA standard is often
  # referred to as signal strength. SNR is an indirect but more useful value that
  # raw signal strength. It can range from 0 to 99 and has units of dB according
  # to the NMEA standard, but the various manufacturers send different ranges of
  # numbers with different starting numbers so the values themselves cannot
  # necessarily be used to evaluate different units. The range of working values
  # in a given gps will usually show a difference of about 25 to 35 between the
  # lowest and highest values, however 0 is a special case and may be shown on
  # satellites that are in view but not being tracked.
  #
  #   $GPGSV,2,1,08,01,40,083,46,02,17,308,41,12,07,344,39,14,22,228,45*75
  #
  # Where:
  #       GSV          Satellites in view
  #       2            Number of sentences for full data
  #       1            sentence 1 of 2
  #       08           Number of satellites in view
  #
  #       01           Satellite PRN number
  #       40           Elevation, degrees
  #       083          Azimuth, degrees
  #       46           SNR - higher is better
  #            for up to 4 satellites per sentence
  #       *75          the checksum data, always begins with *
  defp parse_sentence(["GSV" | fields]) do
    {
      :GSV,
      %{
        sentence: { Enum.at(fields, 1), Enum.at(fields, 0) },
        in_view: Enum.at(fields, 2),
        satellites: [
          gsv_satellite_data(Enum.slice(fields,  3, 4)),
          gsv_satellite_data(Enum.slice(fields,  7, 4)),
          gsv_satellite_data(Enum.slice(fields, 11, 4)),
          gsv_satellite_data(Enum.slice(fields, 15, 4)),
        ]
      }
    }
  end

  # GGA - essential fix data which provide 3D location and accuracy data.
  #
  #  $GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47
  #
  # Where:
  #      GGA          Global Positioning System Fix Data
  #      123519       Fix taken at 12:35:19 UTC
  #      4807.038,N   Latitude 48 deg 07.038' N
  #      01131.000,E  Longitude 11 deg 31.000' E
  #      1            Fix quality: 0 = invalid
  #                                1 = GPS fix (SPS)
  #                                2 = DGPS fix
  #                                3 = PPS fix
  # 			       4 = Real Time Kinematic
  # 			       5 = Float RTK
  #                                6 = estimated (dead reckoning) (2.3 feature)
  # 			       7 = Manual input mode
  # 			       8 = Simulation mode
  #      08           Number of satellites being tracked
  #      0.9          Horizontal dilution of position
  #      545.4,M      Altitude, Meters, above mean sea level
  #      46.9,M       Height of geoid (mean sea level) above WGS84
  #                       ellipsoid
  #      (empty field) time in seconds since last DGPS update
  #      (empty field) DGPS station ID number
  #      *47          the checksum data, always begins with *
  #
  # If the height of geoid is missing then the altitude should be suspect. Some
  # non-standard implementations report altitude with respect to the ellipsoid
  # rather than geoid altitude. Some units do not report negative altitudes at
  # all. This is the only sentence that reports altitude.
  defp parse_sentence(["GGA" | fields]) do
    {
      :GGA,
      %{
        at: gga_timestamp(Enum.at(fields, 0)),
        latitude: gga_coordinate(Enum.at(fields, 1), Enum.at(fields, 2)),
        longitude: gga_coordinate(Enum.at(fields, 3), Enum.at(fields, 4)),
        quality: gga_fix_quality(Enum.at(fields, 5)),
        satellites_tracked: Enum.at(fields, 6),
        hdop: Enum.at(fields, 7),
        altitude: %{ value: Enum.at(fields, 8), units: Enum.at(fields, 9) }
      }
    }
  end

  defp parse_sentence([unsupported | fields]) do
    {
      unsupported,
      fields
    }
  end

  defp gsa_fix_to_atom(fix) when fix == "1", do: :fix_none
  defp gsa_fix_to_atom(fix) when fix == "2", do: :fix_2d
  defp gsa_fix_to_atom(fix) when fix == "3", do: :fix_3d
  defp gsa_fix_to_atom(_fix), do: :fix_unknown

  defp gsv_satellite_data([]), do: nil
  defp gsv_satellite_data([prn, elevation, azimuth, snr]) do
    %{
      prn: prn,
      elevation: elevation,
      azimuth: azimuth,
      snr: snr
    }
  end


  defp gga_timestamp(<<hours::bytes-size(2)>> <> <<minutes::bytes-size(2)>> <> seconds) do
    %{ hours: hours, minutes: minutes, seconds: seconds }
  end
  defp gga_coordinate("", ""), do: %{ hours: "???", minutes: "???", direction: "???" }
  defp gga_coordinate(<<hours::bytes-size(2)>> <> minutes, direction) do
    %{ hours: hours, minutes: minutes, direction: direction }
  end

  defp gga_fix_quality(quality) when quality == "0", do: :invalid
  defp gga_fix_quality(quality) when quality == "1", do: :gps
  defp gga_fix_quality(quality) when quality == "2", do: :dgps
  defp gga_fix_quality(quality) when quality == "3", do: :pps
  defp gga_fix_quality(quality) when quality == "4", do: :rtk
  defp gga_fix_quality(quality) when quality == "5", do: :float_rtk
  defp gga_fix_quality(quality) when quality == "6", do: :estimated
  defp gga_fix_quality(quality) when quality == "7", do: :manual
  defp gga_fix_quality(quality) when quality == "8", do: :simulation
  defp gga_fix_quality(quality), do: {:unknown, quality}

  defp checksum(data, hex) do
    chksum = Enum.reduce(to_charlist(data), fn a,b ->
      Bitwise.bxor(a, b)
    end)
    { expected, _remainder } = Integer.parse(hex, 16)
    { expected == chksum, chksum }
  end

  # defp parse_integer(s) do
  #   case Integer.parse(s) do
  #     {i, _} -> i
  #     :error -> nil
  #   end
  # end
  #
  # defp parse_float(s) do
  #   case Float.parse(s) do
  #     {f, _} -> f
  #     :error -> nil
  #   end
  # end

end
