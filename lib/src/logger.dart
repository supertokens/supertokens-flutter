import 'version.dart';

const String supertokensDebugNamespace = 'com.supertokens';

bool _supertokensWebsiteLogging = false;

// Enable debug logging
void enableLogging() {
  _supertokensWebsiteLogging = true;
}

// Disable debug logging
void disableLogging() {
  _supertokensWebsiteLogging = false;
}

// Logs a debug message
//
// This function will only log the debug message if debug logging
// is enabled.
//
// It can be enabled/disabled through `enableLogging` & `disableLogging`
// functions
void logDebugMessage(String message) {
  if (_supertokensWebsiteLogging) {
    print(
        '$supertokensDebugNamespace {t: "${DateTime.now().toIso8601String()}", message: "$message", supertokens-flutter: "${Version.sdkVersion}"}');
  }
}
