# GpsReader

**TODO: Add description**

Run,

```
iex -S mix
```

Then,

```
iex(2)> GpsReader.register [:all], self
:ok
iex(3)> flush
{:GGA,
 %{
   altitude: %{units: "M", value: ""},
   at: %{hours: "04", minutes: "08", seconds: "33.087"},
   hdop: "",
   latitude: %{direction: "???", hours: "???", minutes: "???"},
   longitude: %{direction: "???", hours: "???", minutes: "???"},
   quality: :invalid,
   satellites_tracked: "00"
 }}
{:GSA,
 %{
   fix: {:fix_none, "A"},
   hdop: "",
   pdop: "",
   satellites: ["", "", "", "", "", "", "", "", "", "", "", ""],
   vdop: ""
 }}
{:GSV,
 %{
   in_view: "02",
   satellites: [
     %{azimuth: "", elevation: "", prn: "25", snr: "20"},
     %{azimuth: "", elevation: "", prn: "26", snr: "29"},
     nil,
     nil
   ],
   sentence: {"1", "1"}
 }}
{"RMC",
 ["040833.087", "V", "", "", "", "", "0.00", "0.00", "240819", "", "", "N"]}
{"VTG", ["0.00", "T", "", "M", "0.00", "N", "0.00", "K", "N"]}
{:GGA,
 %{
   altitude: %{units: "M", value: ""},
   at: %{hours: "04", minutes: "08", seconds: "34.087"},
   hdop: "",
   latitude: %{direction: "???", hours: "???", minutes: "???"},
   longitude: %{direction: "???", hours: "???", minutes: "???"},
   quality: :invalid,
   satellites_tracked: "00"
 }}
{:GSA,
 %{
   fix: {:fix_none, "A"},
   hdop: "",
   pdop: "",
   satellites: ["", "", "", "", "", "", "", "", "", "", "", ""],
   vdop: ""
 }}
{"RMC",
 ["040834.087", "V", "", "", "", "", "0.00", "0.00", "240819", "", "", "N"]}
{"VTG", ["0.00", "T", "", "M", "0.00", "N", "0.00", "K", "N"]}
:ok
```
