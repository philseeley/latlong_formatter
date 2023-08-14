import 'package:flutter_test/flutter_test.dart';

import 'package:latlong_formatter/latlong_formatter.dart';

void main() {
  // NOTE: the expected timezone needs to be updated to the current one.
  test('formatting', () {
    DateTime dt = DateTime.parse('2002-02-27T14:00:00');
    // String tz = '0300';

    LatLongFormatter geoFormatter = LatLongFormatter('Leading\nlines\n\n{latd\u00B0m"s\' c},{lond\u00B0m"s\' c}\n{lat+0d.d m.m s.s} {lon+0d.d m.m s.s}\n{user} {pass}\nUTC={utcyyyy-MM-dd HH:mm} Local={localyyyy-MM-dd HH:mm} TZ={tz:}\n\ntrailing\nlines');

    expect(geoFormatter.format(Location(9.99999999, 99.99999999), dateTime: dt, username: 'myUser', password: 'myPass'),
        'Leading\nlines\n\n9\u00B059"59\' N,99\u00B059"59\' E\n+10.0 60.0 60.0 +100.0 60.0 60.0\nmyUser myPass\nUTC=2002-02-27 11:00 Local=2002-02-27 14:00 TZ=+03:00\n\ntrailing\nlines');
    expect(geoFormatter.format(Location(-9.99999999, -99.99999999), dateTime: dt, username: 'myUser', password: 'myPass'),
        'Leading\nlines\n\n9\u00B059"59\' S,99\u00B059"59\' W\n-10.0 60.0 60.0 -100.0 60.0 60.0\nmyUser myPass\nUTC=2002-02-27 11:00 Local=2002-02-27 14:00 TZ=+03:00\n\ntrailing\nlines');

    geoFormatter = LatLongFormatter('{lat-d m s.sss},{lon-d m s.sss}');
    expect(geoFormatter.format(Location(9.99999999, 99.99999999)), '9 59 60.000,99 59 60.000');
    expect(geoFormatter.format(Location(-9.99999999, -99.99999999)), '-9 59 60.000,-99 59 60.000');

    geoFormatter = LatLongFormatter('{latc0d 0m 0s.sss},{lonc0d 0m 0s.sss}');
    expect(geoFormatter.format(Location(9.99999999, 99.99999999)), 'N09 59 60.000,E099 59 60.000');
    expect(geoFormatter.format(Location(-9.99999999, -99.99999999)), 'S09 59 60.000,W099 59 60.000');
    expect(geoFormatter.format(Location(-9.0, -9.0)), 'S09 00 00.000,W009 00 00.000');
    expect(geoFormatter.format(Location(-9.2, -99.2)), 'S09 11 60.000,W099 12 00.000');

    // Predict Wind format.
    geoFormatter = LatLongFormatter('{user} {lat-d.ddddd} {lon-d.ddddd} {localyyyy-MM-dd HH:mm}{tz}');
    expect(geoFormatter.format(Location(9.99999999, 99.99999999), dateTime: dt, username: 'myUser'),
        'myUser 10.00000 100.00000 2002-02-27 14:00+0300');
    expect(geoFormatter.format(Location(-9.99999999, -99.99999999), dateTime: dt, username: 'myUser'),
        'myUser -10.00000 -100.00000 2002-02-27 14:00+0300');
    expect(geoFormatter.format(Location(9.5, 99.5), dateTime: dt, username: 'myUser'),
        'myUser 9.50000 99.50000 2002-02-27 14:00+0300');
    expect(geoFormatter.format(Location(-9.5, -99.5), dateTime: dt, username: 'myUser'),
        'myUser -9.50000 -99.50000 2002-02-27 14:00+0300');

    // No Foreign Land format.
    geoFormatter = LatLongFormatter('LAT|{latd|m.mmm|c}\nLON|{lond|m.mmm|c}');
    expect(geoFormatter.format(Location(9.99999999, 99.99999999)),
        'LAT|9|60.000|N\nLON|99|60.000|E');
    expect(geoFormatter.format(Location(-9.99999999, -99.99999999)),
        'LAT|9|60.000|S\nLON|99|60.000|W');
    expect(geoFormatter.format(Location(9.5, 99.5)),
        'LAT|9|30.000|N\nLON|99|30.000|E');
    expect(geoFormatter.format(Location(-9.5, -99.5)),
        'LAT|9|30.000|S\nLON|99|30.000|W');
  });
}
