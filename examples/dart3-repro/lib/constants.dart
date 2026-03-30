import 'dart:io';

const _overrideApiDomain = String.fromEnvironment('ST_API_DOMAIN');

String get apiDomain {
  if (_overrideApiDomain.isNotEmpty) {
    return _overrideApiDomain;
  }

  if (Platform.isAndroid) {
    return 'http://10.0.2.2:3567';
  }

  return 'http://127.0.0.1:3567';
}
