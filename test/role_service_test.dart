import 'package:flutter_test/flutter_test.dart';
import 'package:front_inventarios/auth/role_service.dart';

void main() {
  group('RoleService.roleFromName', () {
    test('returns admin for ADMIN', () {
      expect(RoleService.roleFromName('ADMIN'), UserRole.admin);
    });

    test('returns ti for TI', () {
      expect(RoleService.roleFromName('TI'), UserRole.ti);
    });

    test('returns ayudante for PRESTAMO', () {
      expect(RoleService.roleFromName('PRESTAMO'), UserRole.ayudante);
    });

    test('returns unknown for null or unsupported roles', () {
      expect(RoleService.roleFromName(null), UserRole.unknown);
      expect(RoleService.roleFromName('MANAGER'), UserRole.unknown);
    });
  });
}
