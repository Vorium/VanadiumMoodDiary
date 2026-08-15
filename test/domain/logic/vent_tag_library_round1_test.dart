import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/logic/vent_tag_library.dart';

void main() {
  group('VentTagLibrary', () {
    test('presetTags 8 个且非空不重复', () {
      expect(VentTagLibrary.presetTags.length, 8);
      for (final t in VentTagLibrary.presetTags) {
        expect(t.trim().isEmpty, isFalse);
      }
      expect(VentTagLibrary.presetTags.toSet().length, 8);
    });

    test('isValidTag: 空串/纯空格/超长 false, 正常 true', () {
      expect(VentTagLibrary.isValidTag(''), isFalse);
      expect(VentTagLibrary.isValidTag('   '), isFalse);
      expect(VentTagLibrary.isValidTag('x' * 13), isFalse);
      expect(VentTagLibrary.isValidTag('家庭'), isTrue);
      expect(VentTagLibrary.isValidTag('  自定义标签  '), isTrue);
    });
  });
}
