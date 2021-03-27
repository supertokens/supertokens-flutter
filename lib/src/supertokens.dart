import 'package:supertokens/src/id-refresh-token.dart';

/// Primary class for the supertokens package
/// Use [SuperTokens.initialise] to initialise the package, do this before making any network calls
class SuperTokens {
  static int sessionExpiryStatusCode = 401;
  static bool isInitCalled = false;
  static String? refreshTokenEndpoint;
  static Map<String, dynamic>? refreshAPICustomHeaders;

  /// Initialises the SuperTokens SDK
  /// Uses the [refreshTokenEndpoint] to make a call to refresh the session when needed,
  /// the [sessionExpiryStatusCode] is used to determine unauthorised access API errors.
  /// [refreshAPICustomHeaders] are always sent when calling the refresh endpoint.
  /// Throws a [FormatException] if an invalid URL is provided for [refreshTokenEndpoint].
  static void initialise({
    required String refreshTokenEndpoint,
    int sessionExpiryStatusCode = 401,
    Map<String, dynamic> refreshAPICustomHeaders = const {},
  }) {
    if (SuperTokens.isInitCalled) {
      return;
    }

    SuperTokens.refreshAPICustomHeaders = refreshAPICustomHeaders;
    SuperTokens.sessionExpiryStatusCode = sessionExpiryStatusCode;
    SuperTokens.refreshTokenEndpoint =
        _transformRefreshTokenEndpoint(refreshTokenEndpoint);
    SuperTokens.isInitCalled = true;
  }

  /// Verifies the validity of the URL and appends the refresh path if needed.
  /// Returns `String` URL to be used as a the refresh endpoint URL.
  static String _transformRefreshTokenEndpoint(String refreshTokenEndpoint) {
    if (!refreshTokenEndpoint.startsWith("http") ||
        !refreshTokenEndpoint.startsWith("https")) {
      throw FormatException("URL must start with either http or https");
    }

    try {
      String urlStringToReturn = refreshTokenEndpoint;
      Uri uri = Uri.parse(urlStringToReturn);
      if (uri.path.isEmpty) {
        urlStringToReturn += "/session/refresh";
      } else if (uri.path == "/") {
        urlStringToReturn += "session/refresh";
      }

      Uri.parse(
          urlStringToReturn); // Checking for valid URL after modifications

      return urlStringToReturn;
    } on FormatException catch (e) {
      // Throw the error like this to maintain the original error message for format exceptions
      throw e;
    } catch (e) {
      // Throw with a generic message for any other exceptions
      throw FormatException("Invalid URL provided");
    }
  }

  /// Use this function to verify if a users session is valid
  static Future<bool> doesSessionExist() async {
    String? idRefreshToken = await IdRefreshToken.getToken();
    return idRefreshToken != null;
  }
}
