import 'package:supertokens_flutter/src/errors.dart';
import 'package:supertokens_flutter/src/utilities.dart';

class NormalisedURLDomain {
  late String value;

  NormalisedURLDomain(String input) {
    this.value = normaliseUrlDomainOrThrowError(input);
  }

  static String normaliseUrlDomainOrThrowError(String input,
      {bool ignoreProtocal = false}) {
    String trimmedInput = input.trim();

    try {
      if (!trimmedInput.startsWith("http://") &&
          !trimmedInput.startsWith("https://")) {
        throw SuperTokensException("failable error");
      }

      Uri uri = Uri.parse(trimmedInput);
      String hostName = uri.host;
      String scheme = uri.scheme;
      // Flutter returns one of these values if the URL does not have a port
      bool hasNoPort = !Utils.doesUrlHavePort(uri);
      String hostSuffix = hasNoPort ? hostName : hostName + ":${uri.port}";

      if (ignoreProtocal) {
        if (hostName.startsWith("localhost") || Utils.isIPAddress(input)) {
          trimmedInput = "https://$hostSuffix";
        } else {
          trimmedInput = "https://" + hostSuffix;
        }
      } else {
        trimmedInput = scheme + "://" + hostSuffix;
      }

      return trimmedInput;
    } catch (e) {}

    if (trimmedInput.startsWith("/")) {
      throw SuperTokensException("Please provide a valid domain name");
    }

    if (trimmedInput.indexOf(".") == 0) {
      trimmedInput = trimmedInput.substring(1);
    }

    if ((trimmedInput.indexOf('.') != -1 ||
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

    throw SuperTokensException("Please provide a valid domain name");
  }
}
