import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('check_cn_metadata.py exits 0 when all 8 platforms valid', () async {
    final result = await Process.run(
      'python3', ['scripts/check_cn_metadata.py']);
    expect(result.exitCode, 0, reason: result.stderr);
  });
}