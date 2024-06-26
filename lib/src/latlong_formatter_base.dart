import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:format/format.dart' as fmt;

/// Breaks out a Latitude of Longitude value into its Degrees, Minutes and Seconds.
///
/// The decimal values are rounded to 5 decimal places to avoid unexpected rounding errors.
/// e.g. 9 degrees and 60 minutes (bad), rather then 10 degrees and 0 minutes (good).
class LatLongData {
  /// Lat/Long value.
  final double value;

  /// Whether the [value] is positive, i.e. N or E.
  late final bool positive;

  /// Decimal Degrees.
  late final double decDeg;

  /// Degrees.
  late final int deg;

  /// Decimal Minutes.
  late final double decMin;

  /// Minutes.
  late final int min;

  /// Decimal Seconds.
  late final double decSec;

  /// Seconds.
  late final int sec;

  LatLongData(this.value) {
    positive = value < 0 ? false : true;

    // Dart doesn't have a function for rounding to a fixed decimal other than
    // formatting to a string and back to a double.
    decDeg = double.parse(value.abs().toStringAsFixed(5));
    deg = decDeg.toInt();

    decMin = 60 * double.parse((decDeg - deg).toStringAsFixed(5));
    min = decMin.toInt();

    decSec = 60 * double.parse((decMin - min).toStringAsFixed(5));
    sec = decSec.toInt();
  }
}

/// Holds a Lat/Long pair in their [LatLongData] expanded form.
class LatLong {
  late final LatLongData latitude;
  late final LatLongData longitude;

  LatLong(double lat, double lon) {
    latitude = LatLongData(lat);
    longitude = LatLongData(lon);
  }
}

abstract class _Formatter {
  String _render(LatLongFormatter parent);
}

class _LiteralFormatter implements _Formatter {
  final String _text;

  _LiteralFormatter(this._text);

  @override
  String _render(LatLongFormatter parent) {
    return _text;
  }
}

class _DateTimeFormatter implements _Formatter {
  final bool _utc;
  late final DateFormat _dateFormat;

  _DateTimeFormatter(String format, this._utc) {
    _dateFormat = DateFormat(format);
  }

  @override
  String _render(LatLongFormatter parent) {
    DateTime dt = parent._dateTime ?? DateTime.now();
    if (_utc) {
      return _dateFormat.format(dt.toUtc());
    }
    return _dateFormat.format(dt);
  }
}

class _TZFormatter implements _Formatter {
  final String _field;

  _TZFormatter(this._field);

  @override
  String _render(LatLongFormatter parent) {
    DateTime dt = parent._dateTime?.toLocal() ?? DateTime.now();
    switch (_field) {
      case 'h':
        return fmt.format('{:+03d}', dt.timeZoneOffset.inHours);
      case 'm':
        return fmt.format('{:02d}', dt.timeZoneOffset.inMinutes % 60);
      default: // Must be TZ name.
        return dt.timeZoneName;
    }
  }
}

class _InfoFormatter implements _Formatter {
  final int _num;

  _InfoFormatter(this._num);

  @override
  String _render(LatLongFormatter parent) {
    return parent._info.elementAtOrNull(_num) ?? '';
  }
}

enum _LatLongField { degrees, minutes, seconds, plus, minus, cardinal }

class _LatLongFormatter implements _Formatter {
  final _LatLongField _latLongField;
  final bool _isLat;
  final bool _isDecimal;
  final bool _pad;
  final int _decLen;

  _LatLongFormatter(this._latLongField, this._isLat, this._isDecimal, this._pad,
      this._decLen);

  @override
  String _render(LatLongFormatter parent) {
    LatLongData loc =
        _isLat ? parent._location.latitude : parent._location.longitude;

    String pad = _pad
        ? ((!_isLat && _latLongField == _LatLongField.degrees)
            ? '0${3 + _decLen + 1}'
            : '0${2 + _decLen + 1}')
        : '';

    switch (_latLongField) {
      case _LatLongField.degrees:
        return _isDecimal
            ? fmt.format('{:$pad.${_decLen}f}', loc.decDeg)
            : fmt.format('{:${pad}d}', loc.deg);
      case _LatLongField.minutes:
        return _isDecimal
            ? fmt.format('{:$pad.${_decLen}f}', loc.decMin)
            : fmt.format('{:${pad}d}', loc.min);
      case _LatLongField.seconds:
        return _isDecimal
            ? fmt.format('{:$pad.${_decLen}f}', loc.decSec)
            : fmt.format('{:${pad}d}', loc.sec);
      case _LatLongField.plus:
        return loc.positive ? '+' : '-';
      case _LatLongField.minus:
        return loc.positive ? '' : '-';
      case _LatLongField.cardinal:
        if (_isLat) {
          return loc.positive ? 'N' : 'S';
        } else {
          return loc.positive ? 'E' : 'W';
        }
    }
  }
}

/// Formats Latitude and Longitude values to a given template.
class LatLongFormatter {
  final String _format;
  final List<_Formatter> _formatters = [];
  late LatLong _location;
  DateTime? _dateTime;
  List<String> _info = [];

  LatLongFormatter(this._format) {
    _parseFormat();
  }

  static final List<RegExp> _pats = [
    RegExp(r'^[^{]+'), // 0
    RegExp(r'^\{(lat)[^\}]*\}'), // 1
    RegExp(r'^\{(lon)[^\}]*\}'), // 2
    RegExp(r'^\{(local)[^\}]*\}'), // 3
    RegExp(r'^\{(utc)[^\}]*\}'), // 4
    RegExp(r'^\{(tz)[hmn]\}'), // 5
    RegExp(r'^\{(info\d*)\}'), // 6
  ];

  _parseFormat() {
    String todo = _format;

    while (todo.isNotEmpty) {
      bool matched = false;
      for (int i = 0; i < _pats.length; ++i) {
        RegExpMatch? match = _pats[i].firstMatch(todo);
        if (match != null) {
          int len = match[0]!.length - 1;
          switch (i) {
            case 0:
              _formatters.add(_LiteralFormatter(match[0]!));
              break;
            case 1:
              _formatters.addAll(
                  _parseLatLongFormat(match[0]!.substring(4, len), true));
              break;
            case 2:
              _formatters.addAll(
                  _parseLatLongFormat(match[0]!.substring(4, len), false));
              break;
            case 3:
              _formatters
                  .add(_DateTimeFormatter(match[0]!.substring(6, len), false));
              break;
            case 4:
              _formatters
                  .add(_DateTimeFormatter(match[0]!.substring(4, len), true));
              break;
            case 5:
              _formatters.add(_TZFormatter(match[0]!.substring(3, len)));
              break;
            case 6:
              _formatters.add(_InfoFormatter(
                  int.tryParse(match[0]!.substring(5, len)) ?? 0));
              break;
          }
          matched = true;
          todo = todo.substring(match[0]!.length);
          break;
        }
      }
      if (!matched) {
        throw Exception('Bad format at "$todo"');
      }
    }
  }

  static final List<RegExp> _latLonPats = [
    RegExp(r'^0?d\.d+'), // 0
    RegExp(r'^0?d'), // 1
    RegExp(r'^0?m\.m+'), // 2
    RegExp(r'^0?m'), // 3
    RegExp(r'^0?s\.s+'), // 4
    RegExp(r'^0?s'), // 5
    RegExp(r'^[c+-]'), // 6
    RegExp(r'^[^dms0c+-]+'), // 7
  ];

  List<_Formatter> _parseLatLongFormat(String format, bool isLat) {
    List<_Formatter> formatters = [];

    while (format.isNotEmpty) {
      bool matched = false;
      for (int i = 0; i < _latLonPats.length; ++i) {
        RegExpMatch? match = _latLonPats[i].firstMatch(format);
        if (match != null) {
          bool pad = false;
          int decPos = 1;

          if (match[0]![0] == '0') {
            pad = true;
            decPos = 2;
          }

          int decLen = match[0]!.length - 1 - decPos;

          switch (i) {
            case 0:
              formatters.add(_LatLongFormatter(
                  _LatLongField.degrees, isLat, true, pad, decLen));
              break;
            case 1:
              formatters.add(_LatLongFormatter(
                  _LatLongField.degrees, isLat, false, pad, decLen));
              break;
            case 2:
              formatters.add(_LatLongFormatter(
                  _LatLongField.minutes, isLat, true, pad, decLen));
              break;
            case 3:
              formatters.add(_LatLongFormatter(
                  _LatLongField.minutes, isLat, false, pad, decLen));
              break;
            case 4:
              formatters.add(_LatLongFormatter(
                  _LatLongField.seconds, isLat, true, pad, decLen));
              break;
            case 5:
              formatters.add(_LatLongFormatter(
                  _LatLongField.seconds, isLat, false, pad, decLen));
              break;
            case 6:
              formatters.add(_LatLongFormatter(
                  match[0]! == '+'
                      ? _LatLongField.plus
                      : (match[0]! == '-'
                          ? _LatLongField.minus
                          : _LatLongField.cardinal),
                  isLat,
                  false,
                  pad,
                  decLen));
              break;
            case 7:
              formatters.add(_LiteralFormatter(match[0]!));
              break;
          }
          matched = true;
          format = format.substring(match[0]!.length);
          break;
        }
      }
      if (!matched) {
        throw Exception('Bad format at "$format"');
      }
    }

    return formatters;
  }

  /// If [dateTime] is not given, [DateTime.now()] is used.
  String format(LatLong loc,
      {DateTime? dateTime, List<String> info = const []}) {
    _location = loc;
    _dateTime = dateTime;
    _info = info;

    StringBuffer result = StringBuffer();
    for (final f in _formatters) {
      result.write(f._render(this));
    }
    return result.toString();
  }
}
