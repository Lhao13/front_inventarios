import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late final SupabaseClient supabase;

  setUpAll(() {
    supabase = SupabaseClient(
      'https://kphizkgjcawfameowpmw.supabase.co',
      'sb_publishable_F44aOAKPBeBbGL0VYZ-DxQ_ZgnEkUiY',
    );
  });

  group('Supabase RPC Integration Tests', () {

    test('Auth & Role Check', () async {
      final res = await supabase.auth.signInWithPassword(
        email: 'leandrocoral.m@gmail.com',
        password: '123456',
      );
      expect(res.session, isNotNull);
      
      final roleRes = await supabase
          .from('usuario_rol')
          .select('rol(nombre)')
          .eq('user_id', res.session!.user.id)
          .maybeSingle();

      print('Role found for user: $roleRes');
    });

    test('Crear Activo PC and Delete Activo', () async {
      final testAssetId = 999999;
      final testDetailId = 999999;
      
      try {
        print('Intentando crear activo...');
        // If parameters are wrong, this will throw PostgrestException
        await supabase.rpc('crear_activo_pc', params: {
          'p_id': testAssetId,
          'p_numero_serie': 'TEST-SN-1234',
          'p_id_tipo_activo': 1, 
          'p_categoria_activo': 'PC',
          'p_nombre': 'PC de Prueba',
          'p_codigo': 777,
          'p_ip': '192.168.1.100',
          'p_detail_id': testDetailId,
        });

        print('Activo creado satisfactoriamente.');
      } catch (e) {
        print('Error en crear_activo_pc: $e');
      }

      try {
        print('Intentando eliminar activo...');
        await supabase.rpc('eliminar_activo', params: {
          'p_id': testAssetId,
        });
        print('Activo eliminado satisfactoriamente.');
      } catch (e) {
        print('Error en eliminar_activo: $e');
      }
    });

    tearDownAll(() async {
      await supabase.auth.signOut();
    });
  });
}
