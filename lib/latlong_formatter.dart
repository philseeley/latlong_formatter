library latlong_formatter;

import 'package:intl/intl.dart';
import 'package:format/format.dart' as fmt;

class LatLongData {
  final double value;
  late final bool positive;
  late final double decDeg;
  late final int deg;
  late final double decMin;
  late final int min;
  late final double decSec;
  late final int sec;

  LatLongData(this.value) {
    positive = value < 0 ? false : true;

    decDeg = value.abs();
    deg   = decDeg.toInt();

    decMin = 60 * (decDeg - deg);
    min = decMin.toInt();

    decSec = 60 * (decMin - min);
    sec = decSec.toInt();
  }
}

class Location {
  late final LatLongData latitude;
  late final LatLongData longitude;

  Location(double lat, double lon) {
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
    if(_utc) {
      return _dateFormat.format(dt.toUtc());
    }
    return _dateFormat.format(dt);
  }
}

class _TZFormatter implements _Formatter {
  final String _sep;

  _TZFormatter(this._sep);

  @override
  String _render(LatLongFormatter parent) {
    DateTime dt = parent._dateTime?.toLocal() ?? DateTime.now();
    return fmt.format('{:+03d}$_sep{:02d}', dt.timeZoneOffset.inHours, dt.timeZoneOffset.inMinutes%60);
  }
}

class _UserFormatter implements _Formatter {
  final bool _isPassword;

  _UserFormatter(this._isPassword);

  @override
  String _render(LatLongFormatter parent) {
    return _isPassword ? parent._password : parent._username;
  }
}

enum _LatLongField {
  degrees,
  minutes,
  seconds,
  plus,
  minus,
  cardinal
}

class _LatLongFormatter implements _Formatter {
  final _LatLongField _latLongField;
  final bool _isLat;
  final bool _isDecimal;
  final bool _pad;
  final int _decLen;

  _LatLongFormatter(this._latLongField, this._isLat, this._isDecimal, this._pad, this._decLen);

  @override
  String _render(LatLongFormatter parent) {
    LatLongData loc = _isLat ? parent._location.latitude : parent._location.longitude;

    String pad = _pad ? ((!_isLat && _latLongField == _LatLongField.degrees) ? '0${3+_decLen+1}' : '0${2+_decLen+1}') : '';

    switch(_latLongField) {
      case _LatLongField.degrees:
        return _isDecimal ? fmt.format('{:$pad.${_decLen}f}', loc.decDeg) : fmt.format('{:${pad}d}', loc.deg);
      case _LatLongField.minutes:
        return _isDecimal ? fmt.format('{:$pad.${_decLen}f}', loc.decMin) : fmt.format('{:${pad}d}', loc.min);
      case _LatLongField.seconds:
        return _isDecimal ? fmt.format('{:$pad.${_decLen}f}', loc.decSec) : fmt.format('{:${pad}d}', loc.sec);
      case _LatLongField.plus:
        return loc.positive ? '+' : '-';
      case _LatLongField.minus:
        return loc.positive ? '' : '-';
      case _LatLongField.cardinal:
        if(_isLat) {
          return loc.positive ? 'N' : 'S';
        } else {
          return loc.positive ? 'E' : 'W';
        }
    }
  }
}

class LatLongFormatter {
  final String _format;
  final List<_Formatter> _formatters = [];
  late Location _location;
  DateTime? _dateTime;
  String _username = '';
  String _password = '';

  LatLongFormatter(this._format) {
    _parseFormat();
  }

  static final List<RegExp> _pats = [
    RegExp(r'^[^{]+'), // 0
    RegExp(r'^\{(lat)[^\}]*\}'), // 1
    RegExp(r'^\{(lon)[^\}]*\}'), // 2
    RegExp(r'^\{(local)[^\}]*\}'), // 3
    RegExp(r'^\{(utc)[^\}]*\}'), // 4
    RegExp(r'^\{(tz).?\}'), // 5
    RegExp(r'^\{(user)\}'), // 6
    RegExp(r'^\{(pass)\}'), // 7
  ];

  _parseFormat () {
    String todo = _format;

    do {
      bool matched = false;
      for (int i = 0; i<_pats.length; ++i) {
        RegExpMatch? match = _pats[i].firstMatch(todo);
        if (match != null) {
          int len = match[0]!.length-1;
          switch(i) {
            case 0:
              _formatters.add(_LiteralFormatter(match[0]!));
              break;
            case 1:
              _formatters.addAll(_parseLatLongFormat(match[0]!.substring(4, len), true));
              break;
            case 2:
              _formatters.addAll(_parseLatLongFormat(match[0]!.substring(4, len), false));
              break;
            case 3:
              _formatters.add(_DateTimeFormatter(match[0]!.substring(6, len), false));
              break;
            case 4:
              _formatters.add(_DateTimeFormatter(match[0]!.substring(4, len), true));
              break;
            case 5:
              _formatters.add(_TZFormatter(match[0]!.substring(3, len)));
              break;
            case 6:
              _formatters.add(_UserFormatter(false));
              break;
            case 7:
              _formatters.add(_UserFormatter(true));
              break;
          }
          matched = true;
          todo = todo.substring(match[0]!.length);
        }
      }
      if(!matched) {
        throw Exception('Bad format at "$todo"');
      }
    } while(todo.isNotEmpty);
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

  List<_Formatter> _parseLatLongFormat (String format, bool isLat) {
    List<_Formatter> formatters = [];

    do {
      bool matched = false;
      for (int i = 0; i<_latLonPats.length; ++i) {
        RegExpMatch? match = _latLonPats[i].firstMatch(format);
        if (match != null) {
          bool pad = false;
          int decPos = 1;

          if(match[0]![0] == '0'){
            pad = true;
            decPos = 2;
          }

          int decLen = match[0]!.length-1-decPos;

          switch(i) {
            case 0:
              formatters.add(_LatLongFormatter(_LatLongField.degrees, isLat, true, pad, decLen));
              break;
            case 1:
              formatters.add(_LatLongFormatter(_LatLongField.degrees, isLat, false, pad, decLen));
              break;
            case 2:
              formatters.add(_LatLongFormatter(_LatLongField.minutes, isLat, true, pad, decLen));
              break;
            case 3:
              formatters.add(_LatLongFormatter(_LatLongField.minutes, isLat, false, pad, decLen));
              break;
            case 4:
              formatters.add(_LatLongFormatter(_LatLongField.seconds, isLat, true, pad, decLen));
              break;
            case 5:
              formatters.add(_LatLongFormatter(_LatLongField.seconds, isLat, false, pad, decLen));
              break;
            case 6:
              formatters.add(_LatLongFormatter(match[0]! == '+' ? _LatLongField.plus : (match[0]! == '-' ? _LatLongField.minus : _LatLongField.cardinal), isLat, false, pad, decLen));
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
      if(!matched) {
        throw Exception('Bad format at "$format"');
      }
    } while(format.isNotEmpty);

    return formatters;
  }

  String format(Location loc, {DateTime? dateTime, String username = '', String password = ''}) {
    _location = loc;
    _dateTime = dateTime;
    _username = username;
    _password = password;

    StringBuffer result = StringBuffer();
    for(final f in _formatters) {
      result.write(f._render(this));
    }
    return result.toString();
  }
}
