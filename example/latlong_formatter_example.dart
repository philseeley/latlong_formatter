import 'package:latlong_formatter/latlong_formatter.dart';

void main() {
  LatLong ll = LatLong(5.346, -10.784);

  LatLongFormatter llf = LatLongFormatter(
      'Hi {info2},\n\nOn {utcyyyy-MM-dd} at {utcHH:mm} UTC, {info1} is at:\n\n{lat0d 0m.mmm c}, {lon0d 0m.mmm c}\n\nCheers\n{info}');
  print(llf.format(ll, info: ['Joe Blogs', 'SV Billy Do', 'Fred']));

  llf = LatLongFormatter('{latd\u00B0m"s\' c},{lond\u00B0m"s\' c}');
  print(llf.format(ll));

  llf = LatLongFormatter('{latd\u00B0m"s\' c},{lond\u00B0m"s\' c}');
  print(llf.format(ll));

  llf = LatLongFormatter('{lat-d\u00B0m"s\'},{lon-d\u00B0m"s\'}');
  print(llf.format(ll));

  llf = LatLongFormatter('{lat+d\u00B0m"s\'},{lon+d\u00B0m"s\'}');
  print(llf.format(ll));
}