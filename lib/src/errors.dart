class SuperTokensException implements Exception {
  String cause;
  SuperTokensException(this.cause);
}

class SuperTokensGeneralError implements Exception {
  String cause;
  SuperTokensGeneralError(this.cause);
}
