// Example demonstrating the new text transforms: base64, reverse, and md5

import 'package:web_query/query.dart';

void main() {
  print('=== Text Transforms Examples ===\n');

  // Example 1: Base64 Encoding
  print('1. Base64 Encoding:');
  final jsonData1 = '{"message": "Hello World"}';
  final data1 =
      PageData('https://example.com', '', jsonData: jsonData1).getRootElement();
  final encoded = QueryString('json:message?transform=base64').execute(data1);
  print('   Original: Hello World');
  print('   Encoded: $encoded\n');

  // Example 2: Base64 Decoding
  print('2. Base64 Decoding:');
  final jsonData2 = '{"encoded": "SGVsbG8gV29ybGQ="}';
  final data2 =
      PageData('https://example.com', '', jsonData: jsonData2).getRootElement();
  final decoded =
      QueryString('json:encoded?transform=base64decode').execute(data2);
  print('   Encoded: SGVsbG8gV29ybGQ=');
  print('   Decoded: $decoded\n');

  // Example 3: String Reversal
  print('3. String Reversal:');
  final jsonData3 = '{"text": "Hello"}';
  final data3 =
      PageData('https://example.com', '', jsonData: jsonData3).getRootElement();
  final reversed = QueryString('json:text?transform=reverse').execute(data3);
  print('   Original: Hello');
  print('   Reversed: $reversed\n');

  // Example 4: MD5 Hashing
  print('4. MD5 Hashing:');
  final jsonData4 = '{"password": "test123"}';
  final data4 =
      PageData('https://example.com', '', jsonData: jsonData4).getRootElement();
  final hashed = QueryString('json:password?transform=md5').execute(data4);
  print('   Original: test123');
  print('   MD5 Hash: $hashed\n');

  // Example 5: Chaining Transforms
  print('5. Chaining Transforms (reverse + base64):');
  final jsonData5 = '{"text": "Hello"}';
  final data5 =
      PageData('https://example.com', '', jsonData: jsonData5).getRootElement();
  final chained = QueryString('json:text?transform=reverse&transform=base64')
      .execute(data5);
  print('   Original: Hello');
  print('   Reversed: olleH');
  print('   Base64 Encoded: $chained\n');

  // Example 6: Combining with Existing Transforms
  print('6. Combining with Existing Transforms (upper + base64):');
  final jsonData6 = '{"text": "hello"}';
  final data6 =
      PageData('https://example.com', '', jsonData: jsonData6).getRootElement();
  final combined =
      QueryString('json:text?transform=upper&transform=base64').execute(data6);
  print('   Original: hello');
  print('   Uppercase: HELLO');
  print('   Base64 Encoded: $combined\n');

  // Example 7: Processing Lists
  print('7. Processing Lists:');
  final jsonData7 = '{"items": ["apple", "banana", "cherry"]}';
  final data7 =
      PageData('https://example.com', '', jsonData: jsonData7).getRootElement();
  final listResult = QueryString('json:items?transform=reverse').execute(data7);
  print('   Original: [apple, banana, cherry]');
  print('   Reversed: $listResult\n');

  // Example 8: MD5 for Cache Keys
  print('8. Using MD5 for Cache Keys:');
  final jsonData8 = '{"url": "https://example.com/api/data?id=123"}';
  final data8 =
      PageData('https://example.com', '', jsonData: jsonData8).getRootElement();
  final cacheKey = QueryString('json:url?transform=md5').execute(data8);
  print('   URL: https://example.com/api/data?id=123');
  print('   Cache Key: $cacheKey\n');

  // Example 9: Round Trip Base64
  print('9. Round Trip Base64 (encode then decode):');
  final jsonData9 = '{"secret": "My Secret Message"}';
  final data9 =
      PageData('https://example.com', '', jsonData: jsonData9).getRootElement();
  final query9 = QueryString(
      'json:secret?transform=base64&save=enc ++ template:\${enc}?transform=base64decode');
  final roundTrip = query9.execute(data9);
  print('   Original: My Secret Message');
  print('   After encode + decode: $roundTrip\n');

  print('=== All Examples Complete ===');
}
