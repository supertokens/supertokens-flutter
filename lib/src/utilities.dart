import 'package:http/http.dart' as http;

class SuperTokensUtils {
  /// Returns the domain of the provided url if valid
  ///
  /// Throws [FormatException] if the url is invalid or does not have a http/https scheme
  static String getApiDomain(String url) {
    if (url.startsWith("http://") || url.startsWith("https://")) {
      List<String> splitArray = url.split("/");
      List<String> apiDomainArray = [];
      for (int i = 0; i <= 2; i++) {
        try {
          apiDomainArray.add(splitArray[i]);
        } catch (e) {
          throw new FormatException(
              "Invalid URL provided for refresh token endpoint");
        }
      }
      return apiDomainArray.join("/");
    } else {
      throw new FormatException(
          "Refresh token endpoint must start with http or https");
    }
  }

  /// Returns a copy of the provided request object as a [http.BaseRequest]
  ///
  /// Does not support [StreamedRequest], throws [Exception] if request type is not [http.Request] or [http.MultipartRequest]
  static http.BaseRequest copyRequest(http.BaseRequest request) {
    http.BaseRequest requestCopy;

    if (request is http.Request) {
      requestCopy = http.Request(request.method, request.url)
        ..encoding = request.encoding
        ..bodyBytes = request.bodyBytes;
    } else if (request is http.MultipartRequest) {
      requestCopy = http.MultipartRequest(request.method, request.url)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
    } else if (request is http.StreamedRequest) {
      throw Exception('copying streamed requests is not supported');
    } else {
      throw Exception('request type is unknown, cannot copy');
    }

    requestCopy
      ..persistentConnection = request.persistentConnection
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..headers.addAll(request.headers);

    return requestCopy;
  }
}
