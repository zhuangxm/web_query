import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('Text Transforms Integration Tests', () {
    group('Base64 Transform', () {
      test('base64 encode through QueryString', () {
        const jsonData = '{"message": "Hello World"}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final result =
            QueryString('json:message?transform=base64').execute(data);
        expect(result, 'SGVsbG8gV29ybGQ=');
      });

      test('base64decode through QueryString', () {
        const jsonData = '{"encoded": "SGVsbG8gV29ybGQ="}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final result =
            QueryString('json:encoded?transform=base64decode').execute(data);
        expect(result, 'Hello World');
      });

      test('base64 round trip', () {
        const jsonData = '{"text": "Test Message"}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final encoded = QueryString('json:text?transform=base64').execute(data);
        expect(encoded, isA<String>());

        // Create new data with encoded value
        final jsonData2 = '{"encoded": "$encoded"}';
        final data2 = PageData('https://example.com', '', jsonData: jsonData2)
            .getRootElement();

        final decoded =
            QueryString('json:encoded?transform=base64decode').execute(data2);
        expect(decoded, 'Test Message');
      });

      test('base64 with HTML content', () {
        const html = '<div class="content">Hello</div>';
        final data = PageData('https://example.com', html).getRootElement();

        final result =
            QueryString('.content/@text?transform=base64').execute(data);
        expect(result, 'SGVsbG8=');
      });

      test('base64 on list of values', () {
        const jsonData = '{"items": ["apple", "banana", "cherry"]}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final result = QueryString('json:items?transform=base64').execute(data);
        expect(result, isA<List>());
        expect(result, ['YXBwbGU=', 'YmFuYW5h', 'Y2hlcnJ5']);
      });
    });

    group('Reverse Transform', () {
      test('reverse through QueryString', () {
        const jsonData = '{"text": "Hello"}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final result = QueryString('json:text?transform=reverse').execute(data);
        expect(result, 'olleH');
      });

      test('reverse with HTML content', () {
        const html = '<div class="content">World</div>';
        final data = PageData('https://example.com', html).getRootElement();

        final result =
            QueryString('.content/@text?transform=reverse').execute(data);
        expect(result, 'dlroW');
      });

      test('reverse on list', () {
        const jsonData = '{"words": ["abc", "xyz", "123"]}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final result =
            QueryString('json:words?transform=reverse').execute(data);
        expect(result, ['cba', 'zyx', '321']);
      });

      test('reverse is reversible', () {
        const jsonData = '{"text": "palindrome"}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final reversed =
            QueryString('json:text?transform=reverse').execute(data);
        expect(reversed, 'emordnilap');

        // Reverse again
        final jsonData2 = '{"text": "$reversed"}';
        final data2 = PageData('https://example.com', '', jsonData: jsonData2)
            .getRootElement();

        final original =
            QueryString('json:text?transform=reverse').execute(data2);
        expect(original, 'palindrome');
      });
    });

    group('MD5 Transform', () {
      test('md5 through QueryString', () {
        const jsonData = '{"password": "test"}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final result = QueryString('json:password?transform=md5').execute(data);
        expect(result, '098f6bcd4621d373cade4e832627b4f6');
      });

      test('md5 with HTML content', () {
        const html = '<div class="content">password</div>';
        final data = PageData('https://example.com', html).getRootElement();

        final result =
            QueryString('.content/@text?transform=md5').execute(data);
        expect(result, '5f4dcc3b5aa765d61d8327deb882cf99');
      });

      test('md5 on list', () {
        const jsonData = '{"passwords": ["test", "password"]}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final result =
            QueryString('json:passwords?transform=md5').execute(data);
        expect(result, [
          '098f6bcd4621d373cade4e832627b4f6',
          '5f4dcc3b5aa765d61d8327deb882cf99'
        ]);
      });

      test('md5 for cache key generation', () {
        const jsonData = '{"url": "https://example.com/api/data?id=123"}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final cacheKey = QueryString('json:url?transform=md5').execute(data);
        expect(cacheKey, isA<String>());
        expect(cacheKey.length, 32);
        expect(cacheKey, matches(RegExp(r'^[a-f0-9]{32}$')));
      });

      test('md5 is consistent', () {
        const jsonData = '{"text": "same input"}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final hash1 = QueryString('json:text?transform=md5').execute(data);
        final hash2 = QueryString('json:text?transform=md5').execute(data);
        expect(hash1, hash2);
      });
    });

    group('Chaining New Transforms', () {
      test('upper then base64', () {
        const jsonData = '{"text": "hello"}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final result = QueryString('json:text?transform=upper&transform=base64')
            .execute(data);
        expect(result, 'SEVMTE8='); // Base64 of 'HELLO'
      });

      test('reverse then base64', () {
        const jsonData = '{"text": "Hello"}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final result =
            QueryString('json:text?transform=reverse&transform=base64')
                .execute(data);
        expect(result, 'b2xsZUg='); // Base64 of 'olleH'
      });

      test('base64decode then lower', () {
        const jsonData = '{"encoded": "SEVMTE8="}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final result =
            QueryString('json:encoded?transform=base64decode&transform=lower')
                .execute(data);
        expect(result, 'hello');
      });

      test('reverse then md5', () {
        const jsonData = '{"text": "password"}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final result = QueryString('json:text?transform=reverse&transform=md5')
            .execute(data);
        expect(result, isA<String>());
        expect(result.length, 32);
        // Should be different from md5 of original
        expect(result, isNot('5f4dcc3b5aa765d61d8327deb882cf99'));
      });

      test('complex chain: upper, reverse, base64', () {
        const jsonData = '{"text": "hello"}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final result = QueryString(
                'json:text?transform=upper&transform=reverse&transform=base64')
            .execute(data);
        expect(result, 'T0xMRUg='); // Base64 of 'OLLEH' (reversed 'HELLO')
      });
    });

    group('Combining with Other Transforms', () {
      test('base64 on list', () {
        const jsonData = '{"items": ["apple", "banana"]}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final result = QueryString('json:items?transform=base64').execute(data);
        expect(result, ['YXBwbGU=', 'YmFuYW5h']);
      });

      test('md5 then index', () {
        const jsonData = '{"items": ["first", "second", "third"]}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final result =
            QueryString('json:items?transform=md5&index=1').execute(data);
        expect(result, isA<String>());
        expect(result.length, 32);
      });

      test('regexp then base64', () {
        const jsonData = '{"text": "Price: 19.99"}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final result = QueryString(
                r'json:text?transform=regexp:/Price: (\d+\.\d+)/$1/&transform=base64')
            .execute(data);
        expect(result, 'MTkuOTk='); // Base64 of '19.99'
      });
    });

    group('Save and Template with New Transforms', () {
      test('save base64 encoded value', () {
        const jsonData = '{"secret": "password123"}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final result = QueryString(
                'json:secret?transform=base64&save=encoded ++ template:\${encoded}')
            .execute(data);
        expect(result, 'cGFzc3dvcmQxMjM=');
      });

      test('save md5 hash', () {
        const jsonData = '{"password": "test"}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final result = QueryString(
                'json:password?transform=md5&save=hash ++ template:Hash: \${hash}')
            .execute(data);
        expect(result, 'Hash: 098f6bcd4621d373cade4e832627b4f6');
      });

      test('reverse and combine', () {
        const jsonData = '{"first": "Hello", "second": "World"}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final result = QueryString(
                'json:first?transform=reverse&save=r1 ++ json:second?transform=reverse&save=r2 ++ template:\${r1} \${r2}')
            .execute(data);
        expect(result, 'olleH dlroW');
      });
    });

    group('Edge Cases', () {
      test('base64 with empty string', () {
        const jsonData = '{"text": ""}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final result = QueryString('json:text?transform=base64').execute(data);
        // Empty string in JSON may return null
        expect(result, anyOf(equals(''), isNull));
      });

      test('reverse with empty string', () {
        const jsonData = '{"text": ""}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final result = QueryString('json:text?transform=reverse').execute(data);
        // Empty string in JSON may return null
        expect(result, anyOf(equals(''), isNull));
      });

      test('md5 with empty string', () {
        const jsonData = '{"text": ""}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final result = QueryString('json:text?transform=md5').execute(data);
        expect(result, 'd41d8cd98f00b204e9800998ecf8427e');
      });

      test('base64decode with invalid input', () {
        const jsonData = '{"text": "invalid!!!"}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final result =
            QueryString('json:text?transform=base64decode').execute(data);
        expect(result, null);
      });

      test('transforms with unicode', () {
        const jsonData = '{"text": "Hello 世界"}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final encoded = QueryString('json:text?transform=base64').execute(data);
        expect(encoded, isA<String>());

        final jsonData2 = '{"encoded": "$encoded"}';
        final data2 = PageData('https://example.com', '', jsonData: jsonData2)
            .getRootElement();

        final decoded =
            QueryString('json:encoded?transform=base64decode').execute(data2);
        expect(decoded, 'Hello 世界');
      });
    });

    group('Real-World Use Cases', () {
      test('API key encoding for storage', () {
        const jsonData = '{"apiKey": "sk-1234567890abcdef"}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final encoded =
            QueryString('json:apiKey?transform=base64').execute(data);
        expect(encoded, isA<String>());
        expect(encoded, isNot(contains('sk-')));
      });

      test('Generate cache key from URL', () {
        const jsonData =
            '{"url": "https://api.example.com/users/123?include=posts"}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final cacheKey = QueryString('json:url?transform=md5').execute(data);
        expect(cacheKey, isA<String>());
        expect(cacheKey.length, 32);
        expect(cacheKey, matches(RegExp(r'^[a-f0-9]+$')));
      });

      test('Obfuscate sensitive data', () {
        const jsonData = '{"ssn": "123-45-6789"}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final obfuscated =
            QueryString('json:ssn?transform=reverse&transform=base64')
                .execute(data);
        expect(obfuscated, isA<String>());
        expect(obfuscated, isNot(contains('123')));
      });

      test('Hash passwords for comparison', () {
        const jsonData = '{"passwords": ["password1", "password2"]}';
        final data = PageData('https://example.com', '', jsonData: jsonData)
            .getRootElement();

        final hashes =
            QueryString('json:passwords?transform=md5').execute(data);
        expect(hashes, isA<List>());
        expect(hashes.length, 2);
        expect(hashes[0], isNot(equals(hashes[1])));
      });
    });
  });
}
