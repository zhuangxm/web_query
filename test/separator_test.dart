import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/src/separator.dart';

void main() {
  testAttributeSeparator();
  testAnySeparator();
  testJsonSeparator();
  testRegSeparator();
}

void testAttributeSeparator() {
  test('test attribute separator', () {
    final (a, b) = attributeSeparator.split("a@b");
    expect(a, 'a');
    expect(b, 'b');
    final (a1, b1) = attributeSeparator.split(r"a\@@b");
    expect(a1, 'a@');
    expect(b1, 'b');
    final (a2, b2) = attributeSeparator.split(r"a\\@c");
    expect(a2, r'a\@c');
    expect(b2, '');
    final (a3, b3) = attributeSeparator.split(r"a\@c");
    expect(a3, r'a@c');
    expect(b3, '');
  });
}

void testAnySeparator() {
  test('test any separator', () {
    final (a, b) = anySeparator.split("any#hello");
    expect(a, 'any');
    expect(b, 'hello');
    final (a1, b1) = anySeparator.split(r"every#hello");
    expect(a1, 'every');
    expect(b1, 'hello');
    //if not startsWith any# or every#, ignore.
    final (a2, b2) = anySeparator.split(r"otherany#hello");
    expect(a2, r'');
    expect(b2, 'otherany#hello');
  });
}

void testJsonSeparator() {
  test('test json separator', () {
    final (a, b) = jsonSeparator.split("json:hello");
    expect(a, 'json');
    expect(b, 'hello');
    final (a1, b1) = jsonSeparator.split("html:hello");
    expect(a1, 'html');
    expect(b1, 'hello');
    //if not startsWith any# or every#, ignore.
    final (a2, b2) = jsonSeparator.split(r"otherjson:hello");
    expect(a2, r'');
    expect(b2, 'otherjson:hello');
  });
}

void testRegSeparator() {
  test('test regExpWithReplace separator', () {
    RegExpWithReplace test1 = RegExpWithReplace(r"http:\/\/.*");
    expect(test1.getValue("http://www.google.com"), "http://www.google.com");
    RegExpWithReplace test2 = RegExpWithReplace(r"http:\/\/.*/t$$t");
    expect(test2.regExp, r"http://.*");
    expect(test2.replacement, r"t$$t");
    expect(test2.getValue("http://www.google.com"), "thttp://www.google.comt");
    RegExpWithReplace test3 = RegExpWithReplace(r"http:\/\/(.*)/t$$t");
    expect(test3.getValue("http://www.google.com"), "twww.google.comt");
    RegExpWithReplace test4 =
        RegExpWithReplace(r".*/https:\/\/www.google.com$$");
    expect(test4.regExp, r".*");
    expect(test4.replacement, r"https://www.google.com$$");
    expect(test4.getValue("/root"), "https://www.google.com/root");
  });
}
