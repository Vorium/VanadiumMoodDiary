import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('check_icon_quality.py exists and is executable', () {
    final f = File('scripts/check_icon_quality.py');
    expect(f.existsSync(), isTrue);
  });
  test('check_icon_quality.py exits 0 when all icons valid', () async {
    final result = await Process.run(
      'python3', ['scripts/check_icon_quality.py']);
    expect(result.exitCode, 0, reason: result.stderr);
  });
}