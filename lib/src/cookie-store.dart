import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mutex/mutex.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SuperTokensCookieStore {
  Map<Uri, List<Cookie>> allCookies;
  SharedPreferences sharedPreferences;
  final cookieSharedPrefsKey = "supertokens-persistent-cookies";
  ReadWriteMutex readWriteLock = ReadWriteMutex();

  SuperTokensCookieStore() {
    SharedPreferences.getInstance().then((value) {
      sharedPreferences = value;
      _loadFromPersistence();
    });
  }

  Future<void> _loadFromPersistence() async {
    allCookies = {};
    String cookiesStringInStorage =
        sharedPreferences.getString(cookieSharedPrefsKey) ?? "{}";
    Map<String, dynamic> cookiesInStorage = jsonDecode(cookiesStringInStorage);
    cookiesInStorage.forEach((key, value) {
      Uri uri = Uri.parse(key);
      List<String> cookieStrings = List.from(value);
      List<Cookie> cookies =
          cookieStrings.map((e) => Cookie.fromSetCookieValue(e)).toList();
      allCookies[uri] = cookies;
    });
  }

  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) async {
    readWriteLock.acquireWrite();
    await Future.forEach(cookies, (element) async {
      Uri uriToStore = await _getCookieUri(uri, element);
      List<Cookie> currentCookies = allCookies[uriToStore] ?? List.from([]);
      currentCookies = currentCookies
          .where((e) => e != null && e.name != element.name)
          .toList();

      DateTime current = DateTime.now();
      if (element.expires != current &&
          element.expires.millisecondsSinceEpoch >
              current.millisecondsSinceEpoch) {
        currentCookies.add(element);
      }

      allCookies[uriToStore] = currentCookies;
    });

    allCookies.removeWhere((key, value) => value.isEmpty);

    await _updatePersistentStorage();
    readWriteLock.release();
  }

  Future<Uri> _getCookieUri(Uri requestUri, Cookie cookie) async {
    Uri cookieUri = Uri.parse(
        "${requestUri.scheme == null ? "http" : requestUri.scheme}://${requestUri.host}${cookie.path == null ? "/" : cookie.path}");

    if (cookie.domain != null) {
      String domain = cookie.domain;
      if (domain[0] == ".") {
        domain = domain.substring(1);
      }

      try {
        cookieUri = Uri(
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

  Future<void> _updatePersistentStorage() async {
    Map<String, List<String>> mapToStore = {};
    allCookies.forEach((key, value) {
      String uriString = key.toString();
      List<String> cookieStrings =
          List.from(value.map((e) => e.toString()).toList());
      mapToStore[uriString] = cookieStrings;
    });

    String stringToStore = jsonEncode(mapToStore);
    await sharedPreferences.setString(cookieSharedPrefsKey, stringToStore);
  }

  Future<List<Cookie>> getForRequest(Uri uri) async {
    readWriteLock.acquireRead();

    List<Cookie> cookiesToReturn = [];
    List<Cookie> allValidCookies = [];

    for (Uri storedUri in allCookies.keys) {
      if (_doesDomainMatch(storedUri.host, uri.host) &&
          _doesPathMatch(storedUri.path, uri.path)) {
        List<Cookie> storedCookies = allCookies[storedUri] ?? List.from([]);
        allValidCookies.addAll(storedCookies);
      }
    }

    if (allValidCookies.isNotEmpty) {
      List<Cookie> cookiesToRemoveFromStorage = [];
      allValidCookies.forEach((element) {
        DateTime current = DateTime.now();
        if (element.expires == current || element.expires.isBefore(current)) {
          cookiesToRemoveFromStorage.add(element);
        } else {
          cookiesToReturn.add(element);
        }
      });

      if (cookiesToRemoveFromStorage.isNotEmpty) {
        await _removeFromPersistence(uri, cookiesToRemoveFromStorage);
      }
    }

    readWriteLock.release();
    return cookiesToReturn;
  }

  bool _doesDomainMatch(String cookieHost, String requestHost) {
    return requestHost == cookieHost || requestHost.endsWith(".$cookieHost");
  }

  bool _doesPathMatch(String cookiePath, String requestPath) {
    return (requestPath == cookiePath) ||
        (requestPath.startsWith(cookiePath) &&
            cookiePath[cookiePath.length - 1] == "/") ||
        (requestPath.startsWith(cookiePath) &&
            requestPath.substring(cookiePath.length)[0] == "/");
  }

  Future<void> _removeFromPersistence(
      Uri uri, List<Cookie> cookiesToRemove) async {
    List<Cookie> _cookiesToRemove = List.from(cookiesToRemove);
    List<Cookie> currentCookies = allCookies[uri] ?? List.from([]);

    _cookiesToRemove.forEach((element) {
      currentCookies.remove(element);
    });

    allCookies[uri] = currentCookies;
    await _updatePersistentStorage();
    return;
  }
}
