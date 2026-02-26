import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/module_config.dart';
import '../../../core/routing/module_route_generator.dart';
import '../../../core/services/entity_service.dart';
import 'model/note_model.dart';
import 'providers/note_providers.dart';

/// JSON-based route generation for Notes module
/// Fully migrated to Riverpod - no GetIt dependency
class NotesRoutesJson {
  static late ModuleConfig _config;
  static bool _initialized = false;

  /// Initialize and load JSON configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load configuration from JSON file
    _config = await ModuleConfig.loadFromAsset(
      'lib/features/postLogin/notes/note_config.json',
    );

    // Create typed provider aliases
    final entityServiceProvider = Provider<EntityService<ModelNote>>((ref) {
      return ref.watch(noteServiceProvider);
    });

    final entityAdapterProvider = Provider<EntityAdapter<ModelNote>>((ref) {
      return ref.watch(noteAdapterProvider);
    });

    // Sorting is now configured in the list page's initState() method

    // Register module with route generator
    ModuleRouteRegistry.registerModule<ModelNote>(
      config: _config,
      serviceProvider: entityServiceProvider,
      adapterProvider: entityAdapterProvider,
      streamProvider: notesStreamProvider,
      entityByIdProvider: noteByIdProvider,
      formProvider: noteFormProvider,
    );

    _initialized = true;
  }

  /// Get routes (call after initialize)
  static List<GoRoute> get routes {
    if (!_initialized) {
      throw StateError(
        'NotesRoutesJson not initialized. Call initialize() first.',
      );
    }
    return ModuleRouteRegistry.routes
        .where((route) => route.path.startsWith(_config.routes.basePath))
        .toList();
  }

  /// Route names (for navigation)
  static String get listRouteName => _config.routes.listRouteName;
  static String get newRouteName => _config.routes.newRouteName;
  static String get editRouteName => _config.routes.editRouteName;
  static String get viewRouteName => _config.routes.viewRouteName;

  /// Route paths
  static String get notes => _config.routes.listPath;
  static String get newNote => _config.routes.newPath;
  static String editNoteRoute(String id) => _config.routes.editRoute(id);
  static String viewNoteRoute(String id) => _config.routes.viewRoute(id);
}

/// Example: How to use in your app router
/// 
/// ```dart
/// // In your main app router setup:
/// await NotesRoutesJson.initialize();
/// 
/// final router = GoRouter(
///   routes: [
///     ...NotesRoutesJson.routes,
///     // ... other routes
///   ],
/// );
/// 
/// // Navigate using:
/// context.pushNamed(NotesRoutesJson.notesName);
/// context.pushNamed(NotesRoutesJson.viewNoteName, pathParameters: {'id': noteId});
/// ```
