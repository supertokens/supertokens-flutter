import 'package:flutter_test/flutter_test.dart';
import 'package:supertokens/src/normalised-url-domain.dart';
import 'package:supertokens/src/normalised-url-path.dart';

void main() {
  group('Normalise URL Path :: ', () {
    test("Test if query params are entered", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "exists?email=john.doe%40gmail.com");

      expect(out, '/exists');
    });

    test("Testing nested routes", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "/auth/email/exists?email=john.doe%40gmail.com");

      expect(out, '/auth/email/exists');
    });
    test("Testing un formated path", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError("exists");

      expect(out, '/exists');
    });
    test("Testing correct path input", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError("/exists");

      expect(out, '/exists');
    });
    test("Testing url encoded forms", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "/exists?email=john.doe%40gmail.com");

      expect(out, '/exists');
    });
    test("Testing index route", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "http://api.example.com");

      expect(out, '');
    });
    test("Testing index route with https://", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "https://api.example.com");

      expect(out, '');
    });
    test("Testing index route with https://", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "https://api.example.com");

      expect(out, '');
    });
    test("Testing index route with query param", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "http://api.example.com?hello=1");
      expect(out, "");
    });
    test("Testing route", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "http://api.example.com/hello");
      expect(out, "/hello");
    });
    test("Testing index route with trailing /", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "http://api.example.com/");
      expect(out, "");
    });
    test("Testing index route with port number", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "http://api.example.com:8080");
      expect(out, "");
    });
    test("Testing index route with # path", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "http://api.example.com#random2");
      expect(out, "");
    });
    test("Testing index route without protocol and a trailing /", () {
      String? out =
          NormalisedURLPath.normaliseIRLPathOrThrowError("api.example.com/");
      expect(out, "");
    });
    test("Testing base route without protocol with #path", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "api.example.com#random");
      expect(out, "");
    });
    test("Texting domain without protocol and a trailing /", () {
      String? out =
          NormalisedURLPath.normaliseIRLPathOrThrowError("api.example.com/");
      expect(out, "");
    });
    test("Testing domain without protocol but #path", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "api.example.com#random");
      expect(out, "");
    });
    test("Testing with incorrect domain", () {
      String? out =
          NormalisedURLPath.normaliseIRLPathOrThrowError(".example.com");
      expect(out, "");
    });
    test("Testing index route with query params", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "api.example.com/?hello=1&bye=2");
      expect(out, "");
    });
    test("Testing proper domain with neseted routes", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "https://api.example.com/one/two");
      expect(out, "/one/two");
    });
    test("Testing nested routes", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "http://api.example.com/one/two");
      expect(out, "/one/two");
    });
    test("Testing IP with nested route", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "http://1.2.3.4/one/two");
      expect(out, "/one/two");
    });
    test("Testing nested routes with trailing /", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "https://api.example.com/one/two/");
      expect(out, "/one/two");
    });
    test("Testing IP address withouut protocol", () {
      String? out =
          NormalisedURLPath.normaliseIRLPathOrThrowError("1.2.3.4/one/two");
      expect(out, "/one/two");
    });
    test("Testing nested routes with query params", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "http://api.example.com/one/two?hello=1");
      expect(out, "/one/two");
    });
    test("Testing route with trailing /", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "http://api.example.com/hello/");
      expect(out, "/hello");
    });
    test("Testing nested routes with trailing/", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "http://api.example.com/one/two/");
      expect(out, "/one/two");
    });
    test("Testing domain with port and nested routes", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "http://api.example.com:8080/one/two");
      expect(out, "/one/two");
    });
    test("Testing nested routes with hash route", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "http://api.example.com/one/two#random2");
      expect(out, "/one/two");
    });
    test("Testing domain with nested route without protocol", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "api.example.com/one/two");
      expect(out, "/one/two");
    });
    test("Testing nested routes with hash route with hashed route", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "api.example.com/one/two/#random");
      expect(out, "/one/two");
    });
    test("Testing broken domain", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          ".example.com/one/two");
      expect(out, "/one/two");
    });
    test("Testing url with nested route and query params", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "api.example.com/one/two?hello=1&bye=2");
      expect(out, "/one/two");
    });
    test("Testing nested route", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError("/one/two");
      expect(out, "/one/two");
    });
    test("Testing nested route without leading /", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError("one/two");
      expect(out, "/one/two");
    });
    test("Testing nested route without leading / and a trailing /", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError("one/two/");
      expect(out, "/one/two");
    });
    test("Testing simple route", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError("/one");
      expect(out, "/one");
    });
    test("Testing simple route", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError("one");
      expect(out, "/one");
    });
    test("Testing simple route", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError("one/");
      expect(out, "/one");
    });
    test("no domain trailing /", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError("/one/two/");
      expect(out, "/one/two");
    });
    test("no domain query param", () {
      String? out =
          NormalisedURLPath.normaliseIRLPathOrThrowError("/one/two?hello=1");
      expect(out, "/one/two");
    });
    test("no domain #route", () {
      String? out =
          NormalisedURLPath.normaliseIRLPathOrThrowError("/one/two/#random");
      expect(out, "/one/two");
    });
    test("localhost:4000", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "localhost:4000/one/two");
      expect(out, "/one/two");
    });
    test("127.0.0.1:4000", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "127.0.0.1:4000/one/two");
      expect(out, "/one/two");
    });
    test("no protocol no port IP", () {
      String? out =
          NormalisedURLPath.normaliseIRLPathOrThrowError("127.0.0.1/one/two");
      expect(out, "/one/two");
    });
    test("IP address no port", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "https://127.0.0.1:80/one/two");
      expect(out, "/one/two");
    });
    test("no domain index route", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError("/");
      expect(out, "");
    });
    test("weird netlify function", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "/.netlify/functions/api");
      expect(out, "/.netlify/functions/api");
    });
    test("weird netlify function -- 2", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "/netlify/.functions/api");
      expect(out, "/netlify/.functions/api");
    });
    test("weird netlify function -- 3", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "app.example.com/.netlify/functions/api");
      expect(out, "/.netlify/functions/api");
    });
    test("weird netlify function -- 4", () {
      String? out = NormalisedURLPath.normaliseIRLPathOrThrowError(
          "app.example.com/netlify/.functions/api");
      expect(out, "/netlify/.functions/api");
    });
    test("/ followed by domain", () {
      String? out =
          NormalisedURLPath.normaliseIRLPathOrThrowError("/app.example.com");
      expect(out, "/app.example.com");
    });
  });

//! -------------------------------------------------------------------------------------
//! -------------------------------------------------------------------------------------
//! -------------------------------------------------------------------------------------
//! -------------------------------------------------------------------------------------
//! -------------------------------------------------------------------------------------

  group('Normalise URL Domain :: ', () {
    test("http doamin", () {
      String? out = NormalisedURLDomain.normaliseUrlDomainOrThrowError(
          "http://api.example.com");
      expect(out, "http://api.example.com");
    });
    test("https doamin", () {
      String? out = NormalisedURLDomain.normaliseUrlDomainOrThrowError(
          "https://api.example.com");
      expect(out, "https://api.example.com");
    });
    test("http with query param", () {
      String? out = NormalisedURLDomain.normaliseUrlDomainOrThrowError(
          "http://api.example.com?hello=1");
      expect(out, "http://api.example.com");
    });
    test("http with route", () {
      String? out = NormalisedURLDomain.normaliseUrlDomainOrThrowError(
          "http://api.example.com/hello");
      expect(out, "http://api.example.com");
    });
    test("http with trailing /", () {
      String? out = NormalisedURLDomain.normaliseUrlDomainOrThrowError(
          "http://api.example.com/");
      expect(out, "http://api.example.com");
    });
    test("http with port", () {
      String? out = NormalisedURLDomain.normaliseUrlDomainOrThrowError(
          "http://api.example.com:8080");
      expect(out, "http://api.example.com:8080");
    });
    test("http with # route", () {
      String? out = NormalisedURLDomain.normaliseUrlDomainOrThrowError(
          "http://api.example.com#random2");
      expect(out, "http://api.example.com");
    });
    test("without protocol and a trailing /", () {
      String? out = NormalisedURLDomain.normaliseUrlDomainOrThrowError(
          "api.example.com/");
      expect(out, "https://api.example.com");
    });
    test("no protocol", () {
      String? out =
          NormalisedURLDomain.normaliseUrlDomainOrThrowError("api.example.com");
      expect(out, "https://api.example.com");
    });
    test("no protocol # route", () {
      String? out = NormalisedURLDomain.normaliseUrlDomainOrThrowError(
          "api.example.com#random");
      expect(out, "https://api.example.com");
    });
    test("domain starting with .", () {
      String? out =
          NormalisedURLDomain.normaliseUrlDomainOrThrowError(".example.com");
      expect(out, "https://example.com");
    });
    test("index route with query param", () {
      String? out = NormalisedURLDomain.normaliseUrlDomainOrThrowError(
          "api.example.com/?hello=1&bye=2");
      expect(out, "https://api.example.com");
    });
    // test("localhost", () {
    //   String? out =
    //       NormalisedURLDomain.normaliseUrlDomainOrThrowError("localhost");
    //   expect(out, "https://localhost");
    // });
    test("simple url", () {
      String? out = NormalisedURLDomain.normaliseUrlDomainOrThrowError(
          "http://api.example.com/one/two");
      expect(out, "http://api.example.com");
    });
    test("IP with protocol", () {
      String? out = NormalisedURLDomain.normaliseUrlDomainOrThrowError(
          "http://1.2.3.4/one/two");
      expect(out, "http://1.2.3.4");
    });
    test("IP with https", () {
      String? out = NormalisedURLDomain.normaliseUrlDomainOrThrowError(
          "https://1.2.3.4/one/two");
      expect(out, "https://1.2.3.4");
    });
    test("simple url", () {
      String? out = NormalisedURLDomain.normaliseUrlDomainOrThrowError(
          "https://api.example.com/one/two/");
      expect(out, "https://api.example.com");
    });
    test("url with query params", () {
      String? out = NormalisedURLDomain.normaliseUrlDomainOrThrowError(
          "https://api.example.com/one/two?hello=1");
      expect(out, "https://api.example.com");
    });
    test("url with # route", () {
      String? out = NormalisedURLDomain.normaliseUrlDomainOrThrowError(
          "https://api.example.com/one/two#random");
      expect(out, "https://api.example.com");
    });
    test("no protocol", () {
      String? out = NormalisedURLDomain.normaliseUrlDomainOrThrowError(
          "api.example.com/one/two");
      expect(out, "https://api.example.com");
    });
    test("no rptocol with routes and # routes", () {
      String? out = NormalisedURLDomain.normaliseUrlDomainOrThrowError(
          "api.example.com/one/two/#random");
      expect(out, "https://api.example.com");
    });
    test("starts with dot", () {
      String? out = NormalisedURLDomain.normaliseUrlDomainOrThrowError(
          ".example.com/one/two");
      expect(out, "https://example.com");
    });
    // test("localhost 4000", () {
    //   String? out =
    //       NormalisedURLDomain.normaliseUrlDomainOrThrowError("localhost:4000");
    //   expect(out, "https://localhost:4000");
    // });
    test("IP with port no protocol", () {
      String? out =
          NormalisedURLDomain.normaliseUrlDomainOrThrowError("127.0.0.1:4000");
      expect(out, "https://127.0.0.1:4000");
    });
    test("IP no protocol", () {
      String? out =
          NormalisedURLDomain.normaliseUrlDomainOrThrowError("127.0.0.1");
      expect(out, "https://127.0.0.1");
    });
    test("https IP with port 80", () {
      String? out = NormalisedURLDomain.normaliseUrlDomainOrThrowError(
          "https://127.0.0.1:80");
      expect(out, "https://127.0.0.1:80");
    });
    test("localhost.org:8080", () {
      String? out = NormalisedURLDomain.normaliseUrlDomainOrThrowError(
          "http://localhost.org:8080");
      expect(out, "http://localhost.org:8080");
    });
    test("empty", () {
      String? out = NormalisedURLDomain.normaliseUrlDomainOrThrowError("");
      expect(out, "");
    });
  });
}
