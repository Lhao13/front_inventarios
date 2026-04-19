import 'package:flutter/material.dart';

class FilterMemoryCache {
  static final Map<String, AssetFilterCriteria> globalCache = {};
}

class AssetFilterCriteria {
  final Set<int> selectedTiposActivo;
  final Set<int> selectedCondiciones;
  final Set<int> selectedSedes;
  final Set<int> selectedAreas;
  final Set<int> selectedCiudades;
  final Set<int> selectedCustodios;
  final Set<int> selectedProveedores;
  final Set<int> selectedMarcas;
  final Set<String> selectedNombres;
  final Set<String> selectedCodigos;
  final Set<String> selectedSeries;
  final DateTimeRange? rangoAdquisicion;
  final DateTimeRange? rangoEntrega;

  const AssetFilterCriteria({
    this.selectedTiposActivo = const {},
    this.selectedCondiciones = const {},
    this.selectedSedes = const {},
    this.selectedAreas = const {},
    this.selectedCiudades = const {},
    this.selectedCustodios = const {},
    this.selectedProveedores = const {},
    this.selectedMarcas = const {},
    this.selectedNombres = const {},
    this.selectedCodigos = const {},
    this.selectedSeries = const {},
    this.rangoAdquisicion,
    this.rangoEntrega,
  });

  bool matches(Map<String, dynamic> asset, {String? ignoreField}) {
    final assetMarcaId = _extractAssetMarcaId(asset);

    final matchesTipo = ignoreField == 'id_tipo_activo' || selectedTiposActivo.isEmpty || selectedTiposActivo.contains(asset['id_tipo_activo']);
    final matchesCondicion = ignoreField == 'id_condicion_activo' || selectedCondiciones.isEmpty || selectedCondiciones.contains(asset['id_condicion_activo']);
    final matchesSede = ignoreField == 'id_sede_activo' || selectedSedes.isEmpty || selectedSedes.contains(asset['id_sede_activo']);
    final matchesArea = ignoreField == 'id_area_activo' || selectedAreas.isEmpty || selectedAreas.contains(asset['id_area_activo']);
    final matchesCiudad = ignoreField == 'id_ciudad_activo' || selectedCiudades.isEmpty || selectedCiudades.contains(asset['id_ciudad_activo']);
    final matchesCustodio = ignoreField == 'id_custodio' || selectedCustodios.isEmpty || selectedCustodios.contains(asset['id_custodio']);
    final matchesProveedor = ignoreField == 'id_provedor' || selectedProveedores.isEmpty || selectedProveedores.contains(asset['id_provedor']);
    final matchesMarca = ignoreField == 'id_marca' || selectedMarcas.isEmpty || selectedMarcas.contains(assetMarcaId);

    final matchesNombre = ignoreField == 'nombre' || selectedNombres.isEmpty || selectedNombres.contains((asset['nombre'] ?? '').toString());
    final matchesCodigo = ignoreField == 'codigo' || selectedCodigos.isEmpty || selectedCodigos.contains((asset['codigo'] ?? '').toString());
    final matchesSerie = ignoreField == 'numero_serie' || selectedSeries.isEmpty || selectedSeries.contains((asset['numero_serie'] ?? '').toString());

    final matchesAdquisicion = _matchesDateRange(
      fieldName: 'fecha_adquisicion',
      asset: asset,
      range: rangoAdquisicion,
      ignoreField: ignoreField,
    );

    final matchesEntrega = _matchesDateRange(
      fieldName: 'fecha_entrega',
      asset: asset,
      range: rangoEntrega,
      ignoreField: ignoreField,
    );

    return matchesTipo &&
        matchesCondicion &&
        matchesSede &&
        matchesArea &&
        matchesCiudad &&
        matchesCustodio &&
        matchesProveedor &&
        matchesMarca &&
        matchesNombre &&
        matchesCodigo &&
        matchesSerie &&
        matchesAdquisicion &&
        matchesEntrega;
  }

  List<Map<String, dynamic>> apply(List<Map<String, dynamic>> assets) {
    return assets.where((asset) => matches(asset)).toList();
  }

  int? _extractAssetMarcaId(Map<String, dynamic> asset) {
    if (asset['info_pc'] != null && (asset['info_pc'] as List).isNotEmpty) {
      return (asset['info_pc'] as List)[0]['id_marca'] as int?;
    }
    if (asset['info_equipo_comunicacion'] != null && (asset['info_equipo_comunicacion'] as List).isNotEmpty) {
      return (asset['info_equipo_comunicacion'] as List)[0]['id_marca'] as int?;
    }
    if (asset['info_equipo_generico'] != null && (asset['info_equipo_generico'] as List).isNotEmpty) {
      return (asset['info_equipo_generico'] as List)[0]['id_marca'] as int?;
    }
    return null;
  }

  bool _matchesDateRange({
    required String fieldName,
    required Map<String, dynamic> asset,
    required DateTimeRange? range,
    required String? ignoreField,
  }) {
    if (ignoreField == fieldName || range == null || asset[fieldName] == null) {
      return true;
    }

    try {
      final dt = DateTime.parse(asset[fieldName].toString());
      return !dt.isBefore(range.start) && !dt.isAfter(range.end);
    } catch (_) {
      return true;
    }
  }
}
