import 'dart:developer';

import 'package:supertokens/src/errors.dart';
import 'package:supertokens/src/utilities.dart';

class NormalisedURLDomain {
  late String value;

  NormalisedURLDomain(String input) {
    this.value = normaliseUrlDomainOrThrowError(input);
  }

  static String normaliseUrlDomainOrThrowError(String input,
      {bool ignoreProtocal = false}) {
    String trimmedInput = input.trim();

    if (trimmedInput.length == 0) return trimmedInput;

    if (trimmedInput.startsWith("/")) {
      throw SuperTokensException("Please provide valid domain name");
    }

    if (trimmedInput.indexOf(".") == 0) {
      trimmedInput = trimmedInput.substring(1);
    }

    if ((trimmedInput.indexOf('.') == -1 ||
            trimmedInput.startsWith("localhost")) &&
        !trimmedInput.startsWith('https') &&
        !trimmedInput.startsWith('http')) {
      trimmedInput = "https://" + trimmedInput;
      try {
        Uri uri = Uri.parse(trimmedInput);
        return normaliseUrlDomainOrThrowError(trimmedInput,
            ignoreProtocal: true);
      } catch (e) {}
    }

    String hostname;
    String scheme;
    String hostSuffix;

    try {
      Uri uri = Uri.parse(trimmedInput);
      hostname = uri.host;
      if (hostname.length == 0 && trimmedInput.contains('localhost')) {
        return trimmedInput;
      }
      scheme = uri.scheme;
      hostSuffix = [80, 443, 0].contains(uri.port)
          ? trimmedInput.contains(uri.port.toString())
              ? hostname + ":${uri.port}"
              : hostname
          : hostname + ":${uri.port}";

      if (ignoreProtocal) {
        if (hostname.startsWith("localhost") || Utils.isIPAddress(input)) {
          trimmedInput = "https://$hostSuffix";
        } else {
          trimmedInput = scheme + "://" + hostSuffix;
        }
      } else {
        trimmedInput = scheme + "://" + hostSuffix;
      }
      return trimmedInput;
    } catch (e) {
      throw SuperTokensException('Url error');
    }
  }
}
