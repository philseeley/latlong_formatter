import 'package:flutter_test/flutter_test.dart';

import 'package:latlong_formatter/latlong_formatter.dart';
import 'package:format/format.dart' as fmt;

void main() {
  test('formatting', () {
    DateTime dt = DateTime.parse('2002-02-27T14:00:00');
    String tzh = fmt.format('{:+03d}', dt.timeZoneOffset.inHours);
    String tzm = fmt.format('{:02d}', dt.timeZoneOffset.inMinutes%60);
    String tzn = dt.timeZoneName;

    LatLongFormatter geoFormatter = LatLongFormatter('Leading\nlines\n\n{latd\u00B0m"s\' c},{lond\u00B0m"s\' c}\n{lat+0d.d m.m s.s} {lon+0d.d m.m s.s}\n{info} {info1}\nUTC={utcyyyy-MM-dd HH:mm} Local={localyyyy-MM-dd HH:mm} TZ={tzh}:{tzm} {tzn}\n\ntrailing\nlines');

    expect(geoFormatter.format(LatLong(9.99999999, 99.99999999), dateTime: dt, info: ['myUser', 'myPass']),
        'Leading\nlines\n\n10\u00B00"0\' N,100\u00B00"0\' E\n+10.0 0.0 0.0 +100.0 0.0 0.0\nmyUser myPass\nUTC=2002-02-27 11:00 Local=2002-02-27 14:00 TZ=$tzh:$tzm $tzn\n\ntrailing\nlines');
    expect(geoFormatter.format(LatLong(-9.99999999, -99.99999999), dateTime: dt, info: ['myUser', 'myPass']),
        'Leading\nlines\n\n10\u00B00"0\' S,100\u00B00"0\' W\n-10.0 0.0 0.0 -100.0 0.0 0.0\nmyUser myPass\nUTC=2002-02-27 11:00 Local=2002-02-27 14:00 TZ=$tzh:$tzm $tzn\n\ntrailing\nlines');

    geoFormatter = LatLongFormatter('{lat-d m s.sss},{lon-d m s.sss}');
    expect(geoFormatter.format(LatLong(9.99999999, 99.99999999)), '10 0 0.000,100 0 0.000');
    expect(geoFormatter.format(LatLong(-9.99999999, -99.99999999)), '-10 0 0.000,-100 0 0.000');

    geoFormatter = LatLongFormatter('{latc0d 0m 0s.sss},{lonc0d 0m 0s.sss}');
    expect(geoFormatter.format(LatLong(9.99999999, 99.99999999)), 'N10 00 00.000,E100 00 00.000');
    expect(geoFormatter.format(LatLong(-9.99999999, -99.99999999)), 'S10 00 00.000,W100 00 00.000');
    expect(geoFormatter.format(LatLong(-9.0, -9.0)), 'S09 00 00.000,W009 00 00.000');
    expect(geoFormatter.format(LatLong(-9.2, -99.2)), 'S09 12 00.000,W099 12 00.000');

    // Predict Wind format.
    geoFormatter = LatLongFormatter('{info} {lat-d.ddddd} {lon-d.ddddd} {localyyyy-MM-dd HH:mm}{tzh}{tzm}');
    expect(geoFormatter.format(LatLong(9.99999999, 99.99999999), dateTime: dt, info: ['myUser']),
        'myUser 10.00000 100.00000 2002-02-27 14:00$tzh$tzm');
    expect(geoFormatter.format(LatLong(-9.99999999, -99.99999999), dateTime: dt, info: ['myUser']),
        'myUser -10.00000 -100.00000 2002-02-27 14:00$tzh$tzm');
    expect(geoFormatter.format(LatLong(9.5, 99.5), dateTime: dt, info: ['myUser']),
        'myUser 9.50000 99.50000 2002-02-27 14:00$tzh$tzm');
    expect(geoFormatter.format(LatLong(-9.5, -99.5), dateTime: dt, info: ['myUser']),
        'myUser -9.50000 -99.50000 2002-02-27 14:00$tzh$tzm');

    // No Foreign Land format.
    geoFormatter = LatLongFormatter('LAT|{latd|m.mmm|c}\nLON|{lond|m.mmm|c}');
    expect(geoFormatter.format(LatLong(9.99999999, 99.99999999)),
        'LAT|10|0.000|N\nLON|100|0.000|E');
    expect(geoFormatter.format(LatLong(-9.99999999, -99.99999999)),
        'LAT|10|0.000|S\nLON|100|0.000|W');
    expect(geoFormatter.format(LatLong(9.5, 99.5)),
        'LAT|9|30.000|N\nLON|99|30.000|E');
    expect(geoFormatter.format(LatLong(-9.5, -99.5)),
        'LAT|9|30.000|S\nLON|99|30.000|W');
  });
}
