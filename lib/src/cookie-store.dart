import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class SuperTokensCookieStore {
  Map<Uri, List<Cookie>>? _allCookies;
  SharedPreferences? _sharedPreferences;
  final _cookieSharedPrefsKey = "supertokens-persistent-cookies";

  SuperTokensCookieStore() {
    SharedPreferences.getInstance().then((value) {
      _sharedPreferences = value;
      _loadFromPersistence();
    });
  }

  /// Loads all cookies stored in shared preferences into the in memory map [_allCookies]
  Future<void> _loadFromPersistence() async {
    _allCookies = {};
    String cookiesStringInStorage =
        _sharedPreferences?.getString(_cookieSharedPrefsKey) ?? "{}";
    Map<String, dynamic> cookiesInStorage = jsonDecode(cookiesStringInStorage);
    cookiesInStorage.forEach((key, value) {
      Uri uri = Uri.parse(key);
      List<String> cookieStrings = List.from(value);
      List<Cookie> cookies =
          cookieStrings.map((e) => Cookie.fromSetCookieValue(e)).toList();
      _allCookies?[uri] = cookies;
    });
    print('hi');
  }

  /// Saves the provided cookie list against the provided Uri.
  ///
  /// If the cookies do not have a set domain, it defaults to the host of the provided Uri.
  ///
  /// If the cookies do not have a set path, it defaults to "/".
  ///
  /// If the provided Uri does not have a scheme, it defaults to http when saving cookies.
  ///
  /// Expired cookies are not saved.
  ///
  /// If you are trying to store cookies from a "set-cookie" header response, consider using the [saveFromSetCookieHeader] utility method which parses the header string.
  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) async {
    await Future.forEach<Cookie>(cookies, (element) async {
      Uri uriToStore = await _getCookieUri(uri, element);
      List<Cookie> currentCookies = _allCookies?[uriToStore] ?? List.from([]);
      currentCookies = currentCookies
          // ignore: unnecessary_null_comparison
          .where((e) => e != null && e.name != element.name)
          .toList();

      DateTime current = DateTime.now();
      if (element.expires != null &&
          element.expires != current &&
          element.expires!.millisecondsSinceEpoch >
              current.millisecondsSinceEpoch) {
        currentCookies.add(element);
      }

      _allCookies?[uriToStore] = currentCookies;
    });

    _allCookies?.removeWhere((key, value) => value.isEmpty);

    await _updatePersistentStorage();
    await _loadFromPersistence();
  }

  /// Returns a Uri to use when saving the cookie
  Future<Uri> _getCookieUri(Uri requestUri, Cookie cookie) async {
    Uri cookieUri = Uri.parse(
        // ignore: unnecessary_null_comparison
        "${requestUri.scheme == null ? "http" : requestUri.scheme}://${requestUri.host}${cookie.path == null ? "/" : cookie.path}");

    if (cookie.domain != null) {
      String domain = cookie.domain ?? "";
      if (domain[0] == ".") {
        domain = domain.substring(1);
      }

      try {
        cookieUri = Uri(
          // ignore: unnecessary_null_comparison
          scheme: requestUri.scheme == null ? "http" : requestUri.scheme,
          host: domain,
          path: cookie.path == null ? "/" : cookie.path,
        );
      } catch (e) {
        // Do nothing
      }
    }

    return cookieUri;
  }

  /// Uses the [_allCookies] map to update values in shared preferences.
  ///
  /// Strips expired cookies before storing in shared preferences
  Future<void> _updatePersistentStorage() async {
    Map<String, List<String>> mapToStore = {};
    _allCookies?.forEach((key, value) {
      String uriString = key.toString();
      List<String> cookieStrings =
          List.from(value.map((e) => e.toString()).toList());
      mapToStore[uriString] = cookieStrings;
    });

    String stringToStore = jsonEncode(mapToStore);
    await _sharedPreferences?.setString(_cookieSharedPrefsKey, stringToStore);
  }

  /// Returns a list of [Cookie]s to be sent when making requests to the provided Uri
  ///
  /// Does not return expired cookies and will remove them from persistent storage if any are found.
  ///
  /// If you are trying to add cookies to a "cookie" header for a network call, consider using the [getCookieHeaderStringForRequest] which creates a semi-colon separated cookie string for a given Uri.
  Future<List<Cookie>> getForRequest(Uri uri) async {
    List<Cookie> cookiesToReturn = [];
    List<Cookie> allValidCookies = [];

    if (_allCookies == null) {
      return cookiesToReturn;
    }

    for (Uri storedUri in _allCookies!.keys) {
      if (_doesDomainMatch(storedUri.host, uri.host) &&
          _doesPathMatch(storedUri.path, uri.path)) {
        List<Cookie> storedCookies = _allCookies?[storedUri] ?? List.from([]);
        allValidCookies.addAll(storedCookies);
      }
    }

    if (allValidCookies.isNotEmpty) {
      List<Cookie> cookiesToRemoveFromStorage = [];
      allValidCookies.forEach((element) {
        DateTime current = DateTime.now();
        if (element.expires == current ||
            (element.expires != null && element.expires!.isBefore(current))) {
          cookiesToRemoveFromStorage.add(element);
        } else {
          cookiesToReturn.add(element);
        }
      });

      if (cookiesToRemoveFromStorage.isNotEmpty) {
        await _removeFromPersistence(uri, cookiesToRemoveFromStorage);
      }
    }

    return cookiesToReturn;
  }

  /// Checks whether a network request's domain can be considered valid for a cookie to be sent
  bool _doesDomainMatch(String cookieHost, String requestHost) {
    return requestHost == cookieHost || requestHost.endsWith(".$cookieHost");
  }

  /// Checks whether a network request's path can be considered valid for a cookie to be sent
  bool _doesPathMatch(String cookiePath, String requestPath) {
    return (requestPath == cookiePath) ||
        (requestPath.startsWith(cookiePath) &&
            cookiePath[cookiePath.length - 1] == "/") ||
        (requestPath.startsWith(cookiePath) &&
            requestPath.substring(cookiePath.length)[0] == "/");
  }

  /// Removes a list of cookies from persistent storage
  Future<void> _removeFromPersistence(
      Uri uri, List<Cookie> cookiesToRemove) async {
    List<Cookie> _cookiesToRemove = List.from(cookiesToRemove);
    List<Cookie> currentCookies = _allCookies?[uri] ?? List.from([]);

    _cookiesToRemove.forEach((element) {
      currentCookies.remove(element);
    });

    _allCookies?[uri] = currentCookies;
    await _updatePersistentStorage();
    await _loadFromPersistence();
    return;
  }

  /// Returns a semi-colon separated cookie string that can be used as the value for a "cookie" header in network requests for a given Uri.
  ///
  /// Does not return expired cookies and will remove them from persistent storage if any are found.
  Future<String> getCookieHeaderStringForRequest(Uri uri) async {
    List<Cookie> cookies = await getForRequest(uri);
    // ignore: unnecessary_null_comparison
    if (cookies != null && cookies.isNotEmpty) {
      List<String> cookiesStringList =
          cookies.map((e) => e.toString()).toList();
      String cookieHeaderString = cookiesStringList.join(";");
      return cookieHeaderString;
    }

    return "";
  }

  /// Saves cookies to persistent storage using the "set-cookie" header value from network responses.
  ///
  /// If the cookies do not have a set domain, it defaults to the host of the provided Uri.
  ///
  /// If the cookies do not have a set path, it defaults to "/".
  ///
  /// If the provided Uri does not have a scheme, it defaults to http when saving cookies.
  ///
  /// Expired cookies are not saved.
  Future<void> saveFromSetCookieHeader(Uri uri, String? setCookieHeader) async {
    if (setCookieHeader != null) {
      List<String> setCookiesStringList =
          setCookieHeader.split(RegExp(r',(?=[^ ])'));
      List<Cookie> setCookiesList = setCookiesStringList
          .map((e) => Cookie.fromSetCookieValue(e))
          .toList();
      await saveFromResponse(uri, setCookiesList);
    }
  }
}
