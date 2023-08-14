import 'package:flutter_test/flutter_test.dart';

import 'package:geo_formatter/latlong_formatter.dart';

void main() {
  // NOTE: the expected timezone needs to be updated to the current one.
  test('formatting', () {
    DateTime dt = DateTime.parse('2002-02-27T14:00:00');

    LatLongFormatter geoFormatter = LatLongFormatter('Leading\nlines\n\n{latd\u00B0m"s.s\' c},{lond\u00B0m"s.s\' c}\n{lat+0d.d m.m s.s} {lon+0d.d m.m s.s}\n{user} {pass}\nUTC={utcyyyy-MM-dd HH:mm} Local={localyyyy-MM-dd HH:mm} TZ={tz:}\n\ntrailing\nlines');

    expect(geoFormatter.format(Location(9.99999999, 99.99999999), dateTime: dt, username: 'myUser', password: 'myPass'),
        'Leading\nlines\n\n9\u00B059"59.999964\' N,99\u00B059"59.999964\' E\n+10.000000 59.999999 59.999964 +100.000000 59.999999 59.999964\nmyUser myPass\nUTC=2002-02-27 11:00 Local=2002-02-27 14:00 TZ=+03:00\n\ntrailing\nlines');
    expect(geoFormatter.format(Location(-9.99999999, -99.99999999), dateTime: dt, username: 'myUser', password: 'myPass'),
        'Leading\nlines\n\n9\u00B059"59.999964\' S,99\u00B059"59.999964\' W\n-10.000000 59.999999 59.999964 -100.000000 59.999999 59.999964\nmyUser myPass\nUTC=2002-02-27 11:00 Local=2002-02-27 14:00 TZ=+03:00\n\ntrailing\nlines');

    geoFormatter = LatLongFormatter('{lat-d m s.s},{lon-d m s.s}');
    expect(geoFormatter.format(Location(9.99999999, 99.99999999)), '9 59 59.999964,99 59 59.999964');
    expect(geoFormatter.format(Location(-9.99999999, -99.99999999)), '-9 59 59.999964,-99 59 59.999964');
  });
}
