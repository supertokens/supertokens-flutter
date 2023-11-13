# SuperTokens Flutter SDK

<a href="https://supertokens.com/discord">
<img src="https://img.shields.io/discord/603466164219281420.svg?logo=discord"
    alt="chat on Discord"></a>

## About

This is a Flutter SDK written in pure dart that is responsible for maintaining a SuperTokens session for a Flutter app.

Learn more at https://supertokens.com

## Usage

### Initialise the SDK

```dart
import 'package:supertokens_flutter/supertokens.dart';

// Initialise the SDK on app launch
void main() {
    SuperTokens.init(apiDomain: "http://localhost:3001");
}
```

### Checking if a session exists

```dart
import 'package:supertokens_flutter/supertokens.dart';

Future<bool> doesSessionExist() async {
    return await SuperTokens.doesSessionExist();
}
```

### Usage with `http`

#### Making network requests

You can make requests as you normally would with `http`, the only difference is that you import the client from the supertokens package instead.

```dart
// Import http from the SuperTokens package
import 'package:supertokens_flutter/http.dart' as http;

Future<void> makeRequest() {
    Uri uri = Uri.parse("http://localhost:3001/api");
    var response = await http.get(uri);
    // handle response
}
```

The SuperTokens SDK will handle session expiry and automatic refreshing for you.

#### Using a custom `http` Client

If you use a custom http client and want to use SuperTokens, you can simply provide the SDK with your client. All requests will continue to use your client along with the session logic that SuperTokens provides.

```dart
// Import http from the SuperTokens package
import 'package:supertokens_flutter/http.dart' as http;

Future<void> makeRequest() {
    Uri uri = Uri.parse("http://localhost:3001/api");

    // provide your custom client to SuperTokens
    var httpClient = http.Client(client: customClient)

    var response = await httpClient.get(uri);
    // handle response
}
```

### Usage with `Dio`

#### Add the SuperTokens interceptor

You can make requests as you normally would with `dio`.

```dart
import 'package:supertokens_flutter/dio.dart';

void setup() {
    Dio dio = Dio(...)
    dio.interceptors.add(SuperTokensInterceptorWrapper(client: dio));
}
```

Or use instance method instead.

```dart
import 'package:supertokens_flutter/dio.dart';

void setup() {
  Dio dio = Dio();  // Create a Dio instance.
  dio.addSupertokensInterceptor();
}
```

#### Making network requests

```dart
import 'package:supertokens_flutter/dio.dart';

void setup() {
    Dio dio = Dio(...)
    dio.interceptors.add(SuperTokensInterceptorWrapper(client: dio));

    var response = dio.get("http://localhost:3001/api");
    // handle response
}
```

### Signing out

```dart
import 'package:supertokens_flutter/supertokens.dart';

Future<void> signOut() async {
    await SuperTokens.signOut();
}
```

### Getting the user id

```dart
import 'package:supertokens_flutter/supertokens.dart';

Future<String> getUserId() async {
    return await SuperTokens.getUserId();
}
```

### Manually refresh sessions

```dart
import 'package:supertokens_flutter/supertokens.dart';

Future<void> manualRefresh() async {
    // Returns true if session was refreshed, false if session is expired
    var success = await SuperTokens.attemptRefreshingSession();
}
```

## Contributing
Please refer to the [CONTRIBUTING.md](https://github.com/supertokens/supertokens-flutter/blob/master/CONTRIBUTING.md) file in this repo.

## Contact us
For any queries, or support requests, please email us at team@supertokens.com, or join our [Discord](supertokens.com/discord) server.

## Authors
Created with :heart: by the folks at SuperTokens.com.
