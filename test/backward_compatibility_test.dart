import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/js.dart';
import 'package:web_query/src/transforms.dart';
import 'package:web_query/src/transforms/data_transforms.dart';

void main() {
  group('Backward Compatibility', () {
    tearDown(() {
      // Clear the registry after each test
      JsExecutorRegistry.clear();
    });

    test('setJsExecutorInstance() should register executor', () {
      // Create a mock executor
      final mockExecutor = FlutterJsExecutor();

      // Use the deprecated function
      // ignore: deprecated_member_use
      setJsExecutorInstance(mockExecutor);

      // Verify it was registered
      expect(JsExecutorRegistry.isConfigured, isTrue);
      expect(JsExecutorRegistry.instance, equals(mockExecutor));
    });

    test(
        'setJsExecutorInstance() should work the same as JsExecutorRegistry.register()',
        () {
      final executor1 = FlutterJsExecutor();
      final executor2 = FlutterJsExecutor();

      // Use old API
      // ignore: deprecated_member_use
      setJsExecutorInstance(executor1);
      expect(JsExecutorRegistry.instance, equals(executor1));

      // Use new API
      JsExecutorRegistry.register(executor2);
      expect(JsExecutorRegistry.instance, equals(executor2));
    });

    test('setJsExecutorInstance() should work with configureJsExecutor()', () {
      final executor1 = FlutterJsExecutor();
      final executor2 = FlutterJsExecutor();

      // Use deprecated API
      // ignore: deprecated_member_use
      setJsExecutorInstance(executor1);
      expect(JsExecutorRegistry.instance, equals(executor1));

      // Use current recommended API
      configureJsExecutor(executor2);
      expect(JsExecutorRegistry.instance, equals(executor2));
    });
  });
}
