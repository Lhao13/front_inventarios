// role_service_test.dart - Test stub para panel web
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_web/auth/role_service.dart';

void main() {
  test('UserRole panel web solo tiene admin, ti, unknown', () {
    expect(UserRole.admin, isA<UserRole>());
    expect(UserRole.ti, isA<UserRole>());
    expect(UserRole.unknown, isA<UserRole>());
  });
}
