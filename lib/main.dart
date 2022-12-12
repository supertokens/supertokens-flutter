import 'package:supertokens/src/normalised-url-domain.dart';

void main() {
  String out = NormalisedURLDomain.normaliseUrlDomainOrThrowError(
      'http://api.example.com?hello=1');
  print(out);
}
