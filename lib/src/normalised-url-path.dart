import 'package:supertokens_flutter/src/errors.dart';
import 'package:supertokens_flutter/src/logger.dart';

class NormalisedURLPath {
  late String value;

  NormalisedURLPath(String input) {
    this.value = normaliseIRLPathOrThrowError(input);
  }

  static String normaliseIRLPathOrThrowError(String input) {
    logDebugMessage('Normalising URL path: ${input}');
    String trimmedInput = input.trim();

    try {
      if (!trimmedInput.startsWith('http'))
        throw SuperTokensException('Invalid protocol');

      Uri url = Uri.parse(trimmedInput);
      trimmedInput = url.path;

      if (trimmedInput.endsWith('/')) {
        return trimmedInput.substring(0, trimmedInput.length - 1);
      }

      logDebugMessage('Normalised value: ${trimmedInput}');
      return trimmedInput;
    } catch (e) {}

    // not a valid URL
    // If the input contains a . it means they have given a domain name.
    // So we try assuming that they have given a domain name + path
    if ((isDomainGiven(trimmedInput) || trimmedInput.startsWith("localhost")) &&
        !trimmedInput.startsWith('http://') &&
        !trimmedInput.startsWith('https://')) {
      trimmedInput = 'https://' + trimmedInput;
      return normaliseIRLPathOrThrowError(trimmedInput);
    }

    if (trimmedInput.contains('.') && !trimmedInput.contains('?')) {
      return normaliseIRLPathOrThrowError('http://' + trimmedInput);
    }

    if (trimmedInput.indexOf('/') != 0) {
      trimmedInput = '/' + trimmedInput;
    }

    try {
      Uri url = Uri.parse('http://example.com' + trimmedInput);
      return normaliseIRLPathOrThrowError('http://example.com' + trimmedInput);
    } catch (e) {
      if (e is FormatException) {
        throw SuperTokensException("Please provide a valid URL path");
      } else {
        throw e;
      }
    }
  }

  static bool isDomainGiven(String input) {
    if (input.indexOf('.') == -1 || input.startsWith('/')) {
      return false;
    }
    try {
      Uri uri = Uri.parse(input);
      String hostname = uri.host;

      if (hostname.length == input.length || hostname.length == 0)
        throw SuperTokensException('Breakdown');

      return hostname.indexOf('.') != -1;
    } catch (e) {}
    try {
      Uri uri = Uri.parse("http://" + input);
      String hostname = uri.host;

      return hostname.indexOf('.') != -1;
    } catch (e) {}

    return false;
  }
}
