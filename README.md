Dart Package for formatting Latitude and Longitude values.

## Features

- Flexible formatting through the use of templates.
- Includes support for Dates, Times and Time Zones.
- Supports additional information strings.

## Usage

```dart
import 'package:latlong_formatter/latlong_formatter.dart';

void main() {
  LatLong ll = LatLong(5.346, -10.784);
  LatLongFormatter llf = LatLongFormatter(
      'Hi {info2},\n\nOn {utcyyyy-MM-dd} at {utcHH:mm} UTC, {info1} is at:\n\n{lat0d 0m.mmm c}, {lon0d 0m.mmm c}\n\nCheers\n{info}');
  print(llf.format(LatLong(5.346, -10.784), info: ['Joe Blogs', 'SV Billy Do', 'Fred']));
}
```
Would output:
```
Hi Fred,

On 2023-08-20 at 07:45 UTC, SV Billy Do is at:

05 20.760 N, 010 47.040 W

Cheers
Joe Blogs
```
and:
```dart
  LatLongFormatter llf = LatLongFormatter('{latd\u00B0m"s\' c},{lond\u00B0m"s\' c}');
  print(llf.format(ll));
  llf = LatLongFormatter('{lat-d\u00B0m"s\'},{lon-d\u00B0m"s\'}');
  print(llf.format(ll));
  llf = LatLongFormatter('{lat+d\u00B0m"s\'},{lon+d\u00B0m"s\'}');
  print(llf.format(ll));
```
Would output:
```
5°20"45' N,10°47"2' W
5°20"45',-10°47"2'
+5°20"45',-10°47"2'
```
## Templates
Templates are free format with fields enclosed in '{}':
- {lat\<loc format\>} -- Latitude.
- {lon\<loc format\>} -- Longitude.
- {local\<time format\>} -- Local time.
- {utc\<time format\>} -- Time in UTC.
- {tz\[hmn\]+} -- Local Time Zone, e.g. 'h' gives "+06", 'm' gives "30" and 'n' gives "CCT".
- {info\[index\]?} -- Additional information line indexed from 0 (0 is optional).

Where **\<loc format\>** can be:
- \[0\]d -- degrees
- \[0\]d.d\[dddd\] -- decimal degrees
- \[0\]m -- minutes
- \[0\]m.m\[mmmm\] -- decimal minutes
- \[0\]s -- seconds
- \[0\]s.s\[ssss\] -- decimal seconds
- c -- cardinal direction, i.e. N,S,E or W.
- \\- -- a "-" when South or West.
- \\+ -- a "+" when North or East and "-" when South or West.

A leading "0" will pad the field to a fixed length.

**Note:** the decimal fields are internally rounded to 5 decimal places, so specifying more decimal places will not increase accuracy. This gives an accuracy of ~1m per-degree and ~2cm per-minute.

The **\<time format\>** can be anything defined for the [DataFormat](https://api.flutter.dev/flutter/intl/DateFormat-class.html) class.
