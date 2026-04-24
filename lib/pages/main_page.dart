import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:front_inventarios/components/side_menu.dart';
import 'package:front_inventarios/pages/asset_management_page.dart';
import 'package:front_inventarios/pages/maintenance_page.dart';
import 'package:front_inventarios/pages/admin/admin_tables_page.dart';
import 'package:front_inventarios/pages/admin/admin_users_page.dart';
import 'package:front_inventarios/main.dart';
import 'package:front_inventarios/auth/role_service.dart';
import 'package:front_inventarios/widgets/barcode_scanner_screen.dart';
import 'package:front_inventarios/pages/quick_search_result_page.dart';
import 'package:front_inventarios/pages/assets/pc_assets_page.dart';
import 'package:front_inventarios/pages/assets/communication_assets_page.dart';
import 'package:front_inventarios/pages/assets/generic_assets_page.dart';
import 'package:front_inventarios/pages/assets/software_assets_page.dart';
import 'package:front_inventarios/services/sync_queue_service.dart';
import 'package:front_inventarios/services/local_db_service.dart';
import 'package:front_inventarios/widgets/user_info_widget.dart';

/// Página principal de la aplicación.
///
/// Esta es la página que se muestra cuando el usuario ha iniciado sesión
/// correctamente y sus credenciales son válidas.
/// Contiene un menú lateral (drawer) con opciones de navegación.
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  /// Índice de la página actual
  int currentPageIndex = 0;
  final GlobalKey<ScaffoldState> _assetScaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _maintenanceScaffoldKey =
      GlobalKey<ScaffoldState>();

  /// Lista de páginas disponibles
  late final List<Widget> _pages = [
    _HomePage(onNavigateToAssets: () => setState(() => currentPageIndex = 1)),
    AssetManagementPage(scaffoldKey: _assetScaffoldKey),
    MaintenancePage(scaffoldKey: _maintenanceScaffoldKey),
    const AdminTablesPage(),
    const AdminUsersPage(),
  ];

  @override
  Widget build(BuildContext context) {
    // Seguridad: Si intentan entrar a mantenimiento sin ser TI/Admin, mostrar error o redirigir
    Widget currentPage = _pages[currentPageIndex];
    if (currentPageIndex == 2) {
      final role = RoleService.currentRole;
      if (role != UserRole.admin && role != UserRole.ti) {
        currentPage = const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Acceso Denegado',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text('No tienes permisos para esta sección.'),
            ],
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentPageIndex == 0
              ? 'Sistema de\nActivos'
              : currentPageIndex == 1
              ? 'Gestión de Activos'
              : currentPageIndex == 2
              ? 'Mantenimientos'
              : currentPageIndex == 3
              ? 'Tablas Maestras'
              : 'Usuarios',
          textScaler: const TextScaler.linear(0.9),
          textAlign: TextAlign.center,
        ),
        leading: currentPageIndex != 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // Si estamos en activos y el filtro está abierto, cerrarlo
                  if (currentPageIndex == 1 &&
                      (_assetScaffoldKey.currentState?.isEndDrawerOpen ??
                          false)) {
                    _assetScaffoldKey.currentState?.closeEndDrawer();
                    return;
                  }
                  // Si estamos en mantenimientos y el filtro está abierto, cerrarlo
                  if (currentPageIndex == 2 &&
                      (_maintenanceScaffoldKey.currentState?.isEndDrawerOpen ??
                          false)) {
                    _maintenanceScaffoldKey.currentState?.closeEndDrawer();
                    return;
                  }
                  // De lo contrario, volver al Home
                  setState(() => currentPageIndex = 0);
                },
              )
            : null, // Muestra el ícono del drawer por defecto si es null y hay un drawer
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: SyncQueueService.instance.hasSyncErrorsNotifier,
            builder: (context, hasErrors, _) {
              if (hasErrors) {
                return IconButton(
                  icon: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber,
                  ),
                  tooltip: 'Errores de Sincronización',
                  onPressed: () => _showSyncErrorsDialog(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: SyncQueueService.instance.isOnlineNotifier,
            builder: (context, isOnline, _) {
              return ValueListenableBuilder<bool>(
                valueListenable: SyncQueueService.instance.isSyncingNotifier,
                builder: (context, isSyncing, _) {
                  if (!isOnline) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Icon(Icons.cloud_off, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Offline',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (isSyncing) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.orange,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Sincronizando...',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Icon(Icons.cloud_done, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Online',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),

      /// Drawer (menú lateral)
      drawer: SideMenu(
        currentPageIndex: currentPageIndex,
        onPageSelected: (index) {
          setState(() {
            currentPageIndex = index;
          });
        },
      ),

      /// Cuerpo: muestra la página actual según el índice
      body: PopScope(
        canPop: currentPageIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;

          // SI EL FILTRO DE ACTIVOS ESTÁ ABIERTO, CERRARLO PRIMERO
          if (currentPageIndex == 1 &&
              (_assetScaffoldKey.currentState?.isEndDrawerOpen ?? false)) {
            _assetScaffoldKey.currentState?.closeEndDrawer();
            return;
          }

          // SI EL FILTRO DE MANTENIMIENTO ESTÁ ABIERTO, CERRARLO PRIMERO
          if (currentPageIndex == 2 &&
              (_maintenanceScaffoldKey.currentState?.isEndDrawerOpen ??
                  false)) {
            _maintenanceScaffoldKey.currentState?.closeEndDrawer();
            return;
          }

          if (currentPageIndex != 0) {
            setState(() {
              currentPageIndex = 0;
            });
          }
        },
        child: SafeArea(
          bottom: true,
          child: Column(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable:
                    SyncQueueService.instance.hasSyncErrorsNotifier,
                builder: (context, hasErrors, _) {
                  if (!hasErrors) return const SizedBox.shrink();
                  return Material(
                    color: Colors.red.shade100,
                    child: InkWell(
                      onTap: _showSyncErrorsDialog,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.red),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Errores de sincronización detectados. Toca para resolver.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.red),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              Expanded(child: currentPage),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSyncErrorsDialog() async {
    final pendingOps = await LocalDbService.instance.getPendingOperations();
    final failedOps = pendingOps
        .where((op) => op['status'] == 'failed')
        .toList();

    if (!mounted) return;

    if (failedOps.isEmpty) {
      SyncQueueService.instance.hasSyncErrorsNotifier.value = false;
      context.showSnackBar('No hay errores pendientes.');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Errores'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Los siguientes registros no pudieron subirse porque hubo un conflicto (Ej: Número de Serie duplicado o no existe). Para continuar con la sincronización, debes descartarlos:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: failedOps.length,
                  itemBuilder: (context, index) {
                    final op = failedOps[index];
                    Map<String, dynamic> params = {};
                    try {
                      params = jsonDecode(op['params_json'] as String);
                    } catch (_) {}
                    final serie =
                        params['p_numero_serie'] ??
                        params['numero_serie'] ??
                        '';
                    final nombre = params['p_nombre'] ?? params['nombre'] ?? '';
                    final tipo = op['rpc_name'].toString().replaceAll('_', ' ');

                    return ListTile(
                      title: Text('Operación: $tipo'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (serie.isNotEmpty) Text('Serie: $serie'),
                          if (nombre.isNotEmpty) Text('Nombre: $nombre'),
                          if (op['error_msg'] != null)
                            Text(
                              'Motivo: ${op['error_msg']}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Descartar operación',
                        onPressed: () async {
                          await LocalDbService.instance.removeOperation(
                            op['id'] as String,
                          );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            _showSyncErrorsDialog(); // Recargar diálogo
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              for (var op in failedOps) {
                await LocalDbService.instance.removeOperation(
                  op['id'] as String,
                );
              }
              SyncQueueService.instance.hasSyncErrorsNotifier.value = false;
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (mounted) context.showSnackBar('Cola de errores limpiada.');
              }
            },
            child: const Text(
              'Descartar Todos',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePage extends StatefulWidget {
  final VoidCallback onNavigateToAssets;

  const _HomePage({required this.onNavigateToAssets});

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int _totalAssets = 0;
  bool _isLoading = true;
  final ScrollController _homeScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchStats();
    // Escuchar cambios globales (Realtime, Sincronización, etc)
    SyncQueueService.instance.onCacheUpdated.addListener(_fetchStats);
  }

  @override
  void dispose() {
    SyncQueueService.instance.onCacheUpdated.removeListener(_fetchStats);
    _homeScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    try {
      if (SyncQueueService.instance.isOnline) {
        // Si hay internet, pedimos el conteo real al servidor
        final response = await Supabase.instance.client
            .from('activo')
            .select('id');
        if (mounted) {
          setState(() {
            _totalAssets = (response as List).length;
            _isLoading = false;
          });
        }
      } else {
        // Si no hay internet, usamos la caché local
        final response = await LocalDbService.instance.getCollection('activo');
        if (mounted) {
          setState(() {
            _totalAssets = response.length;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // Fallback a local si el servidor falla o no hay red
      if (mounted) {
        final response = await LocalDbService.instance.getCollection('activo');
        setState(() {
          _totalAssets = response.length;
          _isLoading = false;
        });
      }
    }
  }

  void _handleQuickSearch(bool isOnlyNumeric) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BarcodeScannerScreen(isOnlyNumeric: isOnlyNumeric),
      ),
    );
    if (result != null && result is String) {
      if (!mounted) return;
      // Navegar a la página de resultados de búsqueda rápida
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuickSearchResultPage(
            searchValue: result,
            isNumericCode: isOnlyNumeric,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _homeScrollController,
      thumbVisibility: true,
      thickness: 8,
      trackVisibility: true,
      child: SingleChildScrollView(
        controller: _homeScrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECCIÓN 1
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                      top: 40,
                      bottom: 20,
                      left: 24,
                      right: 24,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1566bd), Colors.blue.shade900],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const UserInfoWidget(),
                              const SizedBox(height: 20),
                              Text(
                                '$_totalAssets Activos',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Registrados',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.analytics_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                      ],
                    ),
                  ),

            // Contenido con Padding lateral
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECCIÓN 2: GESTIÓN DE ACTIVOS (Agrupados en columna)
                  const Text(
                    'Gestión de Activos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Consulta y administra el inventario.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      _buildModernMenuCard(
                        context,
                        title: 'Activos Globales',
                        subtitle: 'Ver todo el inventario consolidado',
                        icon: Icons.inventory_rounded,
                        color: Colors.blue.shade700,
                        isHighlighted: true,
                        onTap: widget.onNavigateToAssets,
                      ),
                      _buildModernMenuCard(
                        context,
                        title: 'Equipos PC',
                        subtitle: 'Laptops, desktops y servidores',
                        icon: Icons.computer_rounded,
                        color: Colors.blueGrey.shade600,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PcAssetsPage(),
                          ),
                        ),
                      ),
                      _buildModernMenuCard(
                        context,
                        title: 'Software y Licencias',
                        subtitle: 'Aplicaciones y registros digitales',
                        icon: Icons.developer_board_rounded,
                        color: Colors.blueGrey.shade600,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SoftwareAssetsPage(),
                          ),
                        ),
                      ),
                      _buildModernMenuCard(
                        context,
                        title: 'Comunicaciones',
                        subtitle: 'Equipos de red, telefonía y conectividad',
                        icon: Icons.router_rounded,
                        color: Colors.blueGrey.shade600,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CommsAssetsPage(),
                          ),
                        ),
                      ),
                      _buildModernMenuCard(
                        context,
                        title: 'Activos Genéricos',
                        subtitle: 'Otros dispositivos y periféricos',
                        icon: Icons.devices_other_rounded,
                        color: Colors.blueGrey.shade600,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GenericAssetsPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),

                  // SECCIÓN 3: BÚSQUEDA RÁPIDA
                  const Text(
                    'Identificación Rápida',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Escanea activos para consulta instantánea.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickSearchCard(
                          context,
                          title: 'Serie',
                          subtitle: 'Escanear SN',
                          icon: Icons.qr_code_scanner_rounded,
                          color: Colors.indigo,
                          onTap: () => _handleQuickSearch(false),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildQuickSearchCard(
                          context,
                          title: 'Código',
                          subtitle: 'Escanear ID',
                          icon: Icons.document_scanner_rounded,
                          color: Colors.indigo,
                          onTap: () => _handleQuickSearch(true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // SECCIÓN 4: OPERACIONES
                  const Text(
                    'Operación y Control',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (RoleService.currentRole == UserRole.admin || RoleService.currentRole == UserRole.ti)
                    _buildModernMenuCard(
                      context,
                      title: 'Agenda de Mantenimientos',
                      subtitle: 'Calendario y programación de tareas',
                      icon: Icons.build_circle_rounded,
                      color: Colors.orange.shade800,
                      onTap: () {
                        final mainPageState = context
                            .findAncestorStateOfType<MainPageState>();
                        mainPageState?.setState(() {
                          mainPageState.currentPageIndex = 2;
                        });
                      },
                    ),
                  const SizedBox(height: 17),

                  // SECCIÓN 5: ADMINISTRACIÓN (Solo Visible para Admin)
                  if (RoleService.currentRole == UserRole.admin) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Panel Administrativo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Configuraciones maestras y usuarios.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildModernMenuCard(
                      context,
                      title: 'Estados de los activos',
                      subtitle:
                          'Configurar los campos que un activo puede tener',
                      icon: Icons.settings_applications_rounded,
                      color: Colors.blueGrey.shade800,
                      onTap: () {
                        final mainPageState = context
                            .findAncestorStateOfType<MainPageState>();
                        mainPageState?.setState(() {
                          mainPageState.currentPageIndex = 3;
                        });
                      },
                    ),
                    _buildModernMenuCard(
                      context,
                      title: 'Gestión de Usuarios',
                      subtitle: 'Control de accesos y roles',
                      icon: Icons.admin_panel_settings_rounded,
                      color: Colors.blueGrey.shade800,
                      onTap: () {
                        final mainPageState = context
                            .findAncestorStateOfType<MainPageState>();
                        mainPageState?.setState(() {
                          mainPageState.currentPageIndex = 4;
                        });
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isHighlighted = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            color.withAlpha(isHighlighted ? 40 : 20),
            Colors.cyan.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isHighlighted ? color : color.withAlpha(80),
          width: isHighlighted ? 2 : 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withAlpha(isHighlighted ? 50 : 30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: isHighlighted
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 16,
                          color: isHighlighted ? color : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: color.withAlpha(180),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSearchCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade300, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade100,
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
