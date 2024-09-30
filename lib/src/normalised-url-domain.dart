import 'package:supertokens_flutter/src/errors.dart';
import 'package:supertokens_flutter/src/utilities.dart';
import 'package:supertokens_flutter/src/logger.dart';

class NormalisedURLDomain {
  late String value;

  NormalisedURLDomain(String input) {
    this.value = normaliseUrlDomainOrThrowError(input);
  }

  static String normaliseUrlDomainOrThrowError(String input,
      {bool ignoreProtocal = false}) {
    String trimmedInput = input.trim();

    logDebugMessage('NormalisedURLDomain.normaliseUrlDomainOrThrowError: Normalising url domain: ${input}');
    try {
      if (!trimmedInput.startsWith("http://") &&
          !trimmedInput.startsWith("https://")) {
        logDebugMessage('NormalisedURLDomain.normaliseUrlDomainOrThrowError: Does not start with http');
        throw SuperTokensException("failable error");
      }

      Uri uri = Uri.parse(trimmedInput);
      String hostName = uri.host;
      String scheme = uri.scheme;
      // Flutter returns one of these values if the URL does not have a port
      bool hasNoPort = !Utils.doesUrlHavePort(uri);
      String hostSuffix = hasNoPort ? hostName : hostName + ":${uri.port}";
      logDebugMessage('NormalisedURLDomain.normaliseUrlDomainOrThrowError: hostName: ${hostName}');
      logDebugMessage('NormalisedURLDomain.normaliseUrlDomainOrThrowError: scheme: ${scheme}');
      logDebugMessage('NormalisedURLDomain.normaliseUrlDomainOrThrowError: hasNoPort: ${hasNoPort}');
      logDebugMessage('NormalisedURLDomain.normaliseUrlDomainOrThrowError: hostSuffix: ${hostSuffix}');

      if (ignoreProtocal) {
        logDebugMessage('NormalisedURLDomain.normaliseUrlDomainOrThrowError: Ignoring protocol');
        if (hostName.startsWith("localhost") || Utils.isIPAddress(input)) {
          trimmedInput = "https://$hostSuffix";
        } else {
          trimmedInput = "https://" + hostSuffix;
        }
      } else {
        logDebugMessage('NormalisedURLDomain.normaliseUrlDomainOrThrowError: Keeping protocol');
        trimmedInput = scheme + "://" + hostSuffix;
      }

      logDebugMessage('NormalisedURLDomain.normaliseUrlDomainOrThrowError: Normalised value: ${trimmedInput}');
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
