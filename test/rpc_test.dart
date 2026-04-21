import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
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
      // Test Leandro
      var res = await supabase.auth.signInWithPassword(
        email: 'leandrocoral.m@gmail.com',
        password: '123456',
      );
      expect(res.session, isNotNull);
      
      var dbRes = await supabase
          .from('usuario_rol')
          .select('*, rol(*)')
          .eq('user_id', res.session!.user.id);
      debugPrint('Leandro role details: $dbRes');
      
      await supabase.auth.signOut();

      // Test VeroFI
      res = await supabase.auth.signInWithPassword(
        email: 'verofi78111169@flosek.com',
        password: '123456',
      );
      expect(res.session, isNotNull);

      dbRes = await supabase
          .from('usuario_rol')
          .select('*, rol(*)')
          .eq('user_id', res.session!.user.id);
      debugPrint('VeroFI role details: $dbRes');
    });

    test('Crear Activo PC and Delete Activo', () async {
      
      try {
        debugPrint('Intentando crear activo...');
        // If parameters are wrong, this will throw PostgrestException
        await supabase.rpc('crear_activo_pc', params: {
          "p_numero_serie": "HP-TEST-001",
          "p_nombre": "PC Test",
          "p_codigo": 9901,
          "p_id_tipo_activo": 1,
          "p_id_condicion_activo": 2,
          "p_id_custodio": 1,
          "p_id_ciudad_activo": 1,
          "p_id_sede_activo": 1,
          "p_id_area_activo": 2,
          "p_id_provedor": 1,
          "p_fecha_adquisicion": "2024-01-10",
          "p_ip": "192.168.1.10",
          "p_fecha_entrega": "2024-01-12",
          "p_coordenada": "-0.180653,-78.467838",
          "p_procesador": "Intel i7",
          "p_ram": "16GB",
          "p_almacenamiento": "512GB SSD",
          "p_id_marca": 1,
          "p_modelo": "TestDesk 800",
          "p_cargador_codigo": "HP-CH-01",
          "p_num_puertos": 6,
          "p_observaciones": "Equipo de prueba"
        });

        debugPrint('Activo creado satisfactoriamente.');
      } catch (e) {
        debugPrint('Error en crear_activo_pc: $e');
      }

      // Find the ID of the created asset
      try {
        final findResponse = await supabase
            .from('activo')
            .select('id')
            .eq('numero_serie', 'HP-TEST-001')
            .maybeSingle();

        if (findResponse != null && findResponse['id'] != null) {
          final int createdId = findResponse['id'];
          debugPrint('Intentando eliminar activo $createdId...');
          await supabase.rpc('eliminar_activo', params: {
            'p_id_activo': createdId,
          });
          debugPrint('Activo eliminado satisfactoriamente.');
        } else {
           debugPrint('Activo no encontrado para eliminar.');
        }
      } catch (e) {
        debugPrint('Error en eliminar_activo: $e');
      }
    });

    tearDownAll(() async {
      await supabase.auth.signOut();
    });
  });
}

