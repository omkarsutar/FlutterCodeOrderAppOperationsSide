import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/notes/note_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/po_items/po_item_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/products/product_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/rbac_modules/rbac_module_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/rbac_permissions/rbac_permission_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/roles/role_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/route_shop_links/route_shop_link_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/routes/route_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/shops/shop_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/users/user_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/purchase_orders/purchase_order_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/po_collections/po_collection_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/retailer_shop_links/retailer_shop_link_barrel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html show window;
import 'core/config/supabase_config.dart';
import 'core/globals.dart';
import 'core/providers/auth_providers.dart';
import 'router/app_router.dart';

// Translate letters to numbers: a-0, b-1, c-2, d-3, e-4, f-5, g-6, h-7, i-8, j-9
String _translateUtmSource(String utmSource) {
  final translationMap = {
    'a': '0',
    'b': '1',
    'c': '2',
    'd': '3',
    'e': '4',
    'f': '5',
    'g': '6',
    'h': '7',
    'i': '8',
    'j': '9',
  };

  return utmSource
      .split('')
      .map((char) {
        return translationMap[char] ??
            char; // Keep non-translatable characters unchanged
      })
      .join('');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
  );

  // Extract and store utm_source from URL parameters on web
  if (const bool.fromEnvironment('dart.library.html') == true) {
    try {
      final uri = Uri.parse(html.window.location.href);
      final utmSource = uri.queryParameters['utm_source'];
      if (utmSource != null && utmSource.isNotEmpty) {
        // Translate numeric characters to letters
        final translatedUtmSource = _translateUtmSource(utmSource);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('utm_source', translatedUtmSource);
        debugPrint('UTM Source translated and saved: $translatedUtmSource');
      }

      // Memory Diagnostic Logger
      Stream.periodic(const Duration(seconds: 10)).listen((_) {
        try {
          // ignore: undefined_prefixed_name
          final memory = (html.window.performance as dynamic).memory;
          if (memory != null) {
            final used = (memory.usedJSHeapSize / 1024 / 1024).toStringAsFixed(
              2,
            );
            final limit = (memory.jsHeapSizeLimit / 1024 / 1024)
                .toStringAsFixed(2);
            debugPrint('--- MEMORY DIAGNOSTIC ---');
            debugPrint('JS Heap Used: $used MB / $limit MB');
            debugPrint('-------------------------');
          }
        } catch (e) {
          // Silent fail if performance.memory is not supported (e.g. Firefox)
        }
      });
    } catch (e) {
      debugPrint('Error in web diagnostics: $e');
    }
  }

  // Initialize JSON-based routes
  await NotesRoutesJson.initialize();
  await RolesRoutesJson.initialize();
  await RoutesRoutesJson.initialize();
  await RbacModulesRoutesJson.initialize();
  await UsersRoutesJson.initialize();
  await ProductsRoutesJson.initialize();
  await RouteShopLinksRoutesJson.initialize();
  await RbacPermissionsRoutesJson.initialize();
  await PurchaseOrdersRoutesJson.initialize();
  await PoItemsRoutesJson.initialize();
  await ShopsRoutesJson.initialize();
  await PoCollectionsRoutesJson.initialize();
  await RetailerShopLinkRoutesJson.initialize();

  // Make error messages selectable on web
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return SelectableText(
      details.exceptionAsString(),
      style: const TextStyle(color: const Color(0xFFE53935), fontSize: 14),
    );
  };

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  @override
  void initState() {
    super.initState();

    // Initialize auth listener using the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authServiceProvider).initializeAuthListener();

      // Load profile if session is already active
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        ref.read(authServiceProvider).loadAndStoreUserProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return RoleChangeDetector(
      child: RetailerShopLinkChangeDetector(
        child: MaterialApp.router(
          scaffoldMessengerKey: scaffoldMessengerKey,
          routerConfig: router,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Roboto',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF673AB7), // Deep Purple
              brightness: Brightness.light,
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: const Color(0xFFF3E5F5), // Soft Lilac background
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: const Color(0xFFF3E5F5), // Subtle lilac fill
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
              backgroundColor: Color(0xFF673AB7), // Deep Purple AppBar
              foregroundColor: Colors.white, // White text/icons
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: const Color(0xFFFFC107), // Amber FAB
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A widget that listens for real-time changes to the user's role
/// and automatically refreshes the app state and RBAC permissions.
class RoleChangeDetector extends ConsumerWidget {
  final Widget child;
  const RoleChangeDetector({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<ModelUser?>>(userProfileProvider, (previous, next) {
      if (previous == null || previous.value == null) return;
      if (next.value == null) return;

      final oldRoleId = previous.value?.roleId;
      final newRoleId = next.value?.roleId;

      if (oldRoleId != null && newRoleId != null && oldRoleId != newRoleId) {
        debugPrint(
          'RoleChangeDetector: Role change detected from $oldRoleId to $newRoleId',
        );

        // Show notification to user
        scaffoldMessengerKey.currentState?.clearSnackBars();
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.security, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Your access permissions have changed. Reloading app...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Re-initialize RBAC system and refresh routing
        Future.delayed(const Duration(milliseconds: 500), () async {
          try {
            // 1. Force reload profile and RBAC permissions
            await ref.read(authServiceProvider).loadAndStoreUserProfile();

            // 2. Refresh router to re-evaluate redirects and home page
            ref.read(routerProvider).refresh();

            debugPrint(
              'RoleChangeDetector: App successfully reloaded with new role',
            );
          } catch (e) {
            debugPrint('RoleChangeDetector: Error during role reload: $e');
          }
        });
      }
    });

    return child;
  }
}

/// A widget that listens for real-time changes to retailer_shop_links
/// and automatically refreshes the app state when links are created or updated for the current user.
class RetailerShopLinkChangeDetector extends ConsumerWidget {
  final Widget child;
  const RetailerShopLinkChangeDetector({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<
      AsyncValue<List<ModelRetailerShopLink>>
    >(retailerShopLinksStreamProvider, (previous, next) {
      // Only proceed if both previous and next have data
      if (previous == null || next == null) return;
      if (!previous.hasValue || !next.hasValue) return;

      final previousLinks = previous.value!;
      final currentLinks = next.value!;

      // Check if there are changes (additions, updates, or deletions)
      if (previousLinks.length != currentLinks.length ||
          _hasLinkChanges(previousLinks, currentLinks)) {
        debugPrint(
          'RetailerShopLinkChangeDetector: Retailer shop link changes detected',
        );

        // Show notification to user
        scaffoldMessengerKey.currentState?.clearSnackBars();
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.link, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Your shop assignments have changed. Reloading app...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue.shade800,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Refresh app state
        Future.delayed(const Duration(milliseconds: 500), () async {
          try {
            // 1. Force reload profile and RBAC permissions
            await ref.read(authServiceProvider).loadAndStoreUserProfile();

            // 2. Refresh router to re-evaluate redirects and home page
            ref.read(routerProvider).refresh();

            debugPrint(
              'RetailerShopLinkChangeDetector: App successfully reloaded with new shop links',
            );
          } catch (e) {
            debugPrint(
              'RetailerShopLinkChangeDetector: Error during reload: $e',
            );
          }
        });
      }
    });

    return child;
  }

  /// Check if there are actual changes in the retailer shop links
  bool _hasLinkChanges(
    List<ModelRetailerShopLink> previousLinks,
    List<ModelRetailerShopLink> currentLinks,
  ) {
    // Create maps for easier comparison
    final previousMap = {for (var link in previousLinks) link.linkId: link};
    final currentMap = {for (var link in currentLinks) link.linkId: link};

    // Check for changes in existing links
    for (final entry in previousMap.entries) {
      final linkId = entry.key;
      final previousLink = entry.value;
      final currentLink = currentMap[linkId];

      if (currentLink == null) {
        // Link was deleted
        return true;
      }

      // Check if link data changed (userId or shopId)
      if (previousLink.userId != currentLink.userId ||
          previousLink.shopId != currentLink.shopId) {
        return true;
      }
    }

    // Check for new links
    for (final linkId in currentMap.keys) {
      if (!previousMap.containsKey(linkId)) {
        // New link was added
        return true;
      }
    }

    return false;
  }
}
