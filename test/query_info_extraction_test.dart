import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('Query Information Extraction', () {
    test('should extract query info for simple query', () {
      final query = QueryString('json:items/name');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.info, isNotNull);
      expect(result.info!.totalParts, equals(1));
      expect(result.info!.parts[0].scheme, equals('json'));
      expect(result.info!.parts[0].path, equals('items/name'));
      expect(result.info!.operators, isEmpty);
      expect(result.info!.variables, isEmpty);
    });

    test('should extract query info with operators', () {
      final query = QueryString('json:firstName ++ json:lastName');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.info, isNotNull);
      expect(result.info!.totalParts, equals(2));
      expect(result.info!.operators, equals(['++']));
      expect(result.info!.parts[0].scheme, equals('json'));
      expect(result.info!.parts[1].scheme, equals('json'));
    });

    test('should extract query info with variables', () {
      final query = QueryString('json:firstName?save=fn ++ template:\${fn}');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.info, isNotNull);
      expect(result.info!.totalParts, equals(2));
      expect(result.info!.variables, contains('fn'));
      expect(result.info!.parts[0].transforms, containsPair('save', ['fn']));
    });

    test('should extract query info with transforms', () {
      final query = QueryString('json:title?transform=upper');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.info, isNotNull);
      expect(result.info!.parts[0].transforms,
          containsPair('transform', ['upper']));
    });

    test('should extract query info with multiple operators', () {
      final query = QueryString('json:a || json:b ++ json:c');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.info, isNotNull);
      expect(result.info!.totalParts, equals(3));
      expect(result.info!.operators, equals(['||', '++']));
    });

    test('should extract query info with pipe operator', () {
      final query = QueryString('json:items >> json:name');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.info, isNotNull);
      expect(result.info!.totalParts, equals(2));
      expect(result.info!.operators, equals(['>>']));
      expect(result.info!.parts[1].isPipe, isTrue);
    });

    test('should extract multiple variables', () {
      final query =
          QueryString('json:a?save=x ++ json:b?save=y ++ template:\${x}-\${y}');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.info, isNotNull);
      expect(result.info!.variables, containsAll(['x', 'y']));
    });

    test('should handle default html scheme', () {
      final query = QueryString('div/p');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.info, isNotNull);
      expect(result.info!.parts[0].scheme, equals('html'));
      expect(result.info!.parts[0].path, equals('div/p'));
    });

    test('should extract parameters and transforms separately', () {
      final query = QueryString('json:items?save=x&keep&transform=upper');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.info, isNotNull);
      expect(result.info!.parts[0].transforms.keys,
          containsAll(['save', 'keep', 'transform']));
    });

    test('should not extract info when query has errors', () {
      final query = QueryString('jsn:items'); // Invalid scheme
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.info, isNull);
      expect(result.errors, isNotEmpty);
    });

    test('toString should show query info for valid query', () {
      final query = QueryString('json:items?save=x ++ template:\${x}');
      final result = query.validate();

      final str = result.toString();
      expect(str, contains('Query Structure:'));
      expect(str, contains('Total parts: 2'));
      expect(str, contains('++'));
      expect(str, contains('\$x'));
    });

    test('toJson should include query info for valid query', () {
      final query = QueryString('json:items');
      final result = query.validate();

      final json = result.toJson();
      expect(json, contains('"isValid":true'));
      expect(json, contains('"info"'));
      expect(json, contains('"totalParts":1'));
    });
  });
}
