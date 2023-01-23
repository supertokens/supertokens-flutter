class SuperTokensException implements Exception {
  String cause;
  SuperTokensException(this.cause);

  @override
  String toString() {
    return cause;
  }
}

class SuperTokensGeneralError implements Exception {
  String cause;
  SuperTokensGeneralError(this.cause);
}
