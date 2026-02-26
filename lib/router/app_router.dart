import 'package:flutter/foundation.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/notes/note_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/po_items/po_item_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/products/product_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/purchase_orders/purchase_order_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/rbac_modules/rbac_module_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/rbac_permissions/rbac_permission_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/roles/role_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/route_shop_links/route_shop_link_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/routes/route_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/shops/shop_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/po_collections/po_collection_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/retailer_shop_links/retailer_shop_link_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/users/user_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/providers/core_providers.dart';
import '../core/providers/user_profile_state_provider.dart';

import '../features/postLogin/loading_page/loading_page.dart';
import '../features/preLogin/welcome_page.dart';
import '../features/auth/auth_page.dart';
import '../features/postLogin/cart/cart_barrel.dart';
import '../shared/widgets/shared_widget_barrel.dart';
import '../core/routing/module_route_generator.dart';
import '../core/services/rbac_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      ...authRoutes,
      ...NotesRoutesJson.routes,
      ...RoutesRoutesJson.routes,
      ...ShopsRoutesJson.routes,
      ...RouteShopLinksRoutesJson.routes,
      ...RolesRoutesJson.routes,
      ...UsersRoutesJson.routes,
      ...PurchaseOrdersRoutesJson.routes,
      ...PoItemsRoutesJson.routes,
      ...ProductsRoutesJson.routes,
      ...RbacModulesRoutesJson.routes,
      ...RbacPermissionsRoutesJson.routes,
      ...PoCollectionsRoutesJson.routes,
      ...RetailerShopLinkRoutesJson.routes,
    ],
    initialLocation: AppRoute.welcome,
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;

      final isAtRoot = state.uri.path == AppRoute.welcome;
      final isAuthPage =
          state.uri.path == AppRoute.login || state.uri.path == AppRoute.signup;

      final profile = ref.read(userProfileStateProvider).profile;
      final rbacService = ref.read(rbacServiceProvider);

      // Check role first if possible
      final roleName = rbacService.roleName?.toLowerCase();
      final isGuest = roleName == 'guest';

      debugPrint(
        'AppRouter: Redirect Check | LoggedIn: $isLoggedIn | Role: $roleName | Path: ${state.uri.path}',
      );

      // Profile is "ready" if RBAC is initialized AND (is Guest OR has preferred route)
      final isProfileReady =
          rbacService.isInitialized &&
          (isGuest || profile?.preferredRouteId != null);

      final isPublicRoute =
          state.uri.path.startsWith('/products') ||
          state.uri.path.startsWith('/cart');

      // --- Pending Order Redirect (High Priority) ---
      if (isLoggedIn && (isAuthPage || isAtRoot)) {
        final prefs = await SharedPreferences.getInstance();
        final hasPendingOrder = prefs.containsKey('pending_order');
        debugPrint(
          '[AppRouter] Checking for pending order in router: $hasPendingOrder',
        );
        if (hasPendingOrder) {
          debugPrint('AppRouter: Pending order found -> Redirecting to Cart');
          return state.namedLocation(AppRoute.cartName);
        }
      }

      // Redirect to products page if not logged in and trying to access protected routes
      if (!isLoggedIn && !isAuthPage && !isAtRoot && !isPublicRoute) {
        return state.namedLocation(ProductsRoutesJson.listRouteName);
      }

      // Redirect to products page if at root and not logged in
      if (!isLoggedIn && isAtRoot) {
        return state.namedLocation(ProductsRoutesJson.listRouteName);
      }
      if (isLoggedIn && (isAuthPage || isAtRoot)) {
        debugPrint(
          'AppRouter: Handling Root/Auth Page Redirect for LoggedIn User',
        );

        if (!isProfileReady && !rbacService.isInitialized) {
          debugPrint('AppRouter: Profile/RBAC not ready -> Loading');
          return AppRoute.loading; // Wait for RBAC at minimum
        }

        // If RBAC is ready but preferredRouteId is null, and NOT guest, still show loading
        // (This preserves existing behavior for other roles while fixing it for guests)
        if (rbacService.isInitialized &&
            !isGuest &&
            profile?.preferredRouteId == null) {
          debugPrint('AppRouter: Profile missing preferredRouteId -> Loading');
          return AppRoute.loading;
        }

        debugPrint('AppRouter: User role is $roleName');

        // Redirect guest to Products
        if (roleName == 'guest') {
          debugPrint('AppRouter: Guest user -> Redirecting to Products');
          return state.namedLocation(ProductsRoutesJson.listRouteName);
        }

        // Redirect salesperson to Todays Shops
        if (roleName == 'salesperson') {
          return state.namedLocation(
            ShopsRoutesJson.listRouteName,
            queryParameters: {'tapCondition': 'listWithoutTodaysPOs'},
          );
        }

        return state.namedLocation(PurchaseOrdersRoutesJson.listRouteName);
      }

      // --- RBAC Route Protection ---
      // Check if the current route has a permission requirement
      final routeName = state.name;

      debugPrint(
        'AppRouter: RBAC Check Loop | Path: ${state.uri.path} | RouteName: $routeName',
      );

      if (isLoggedIn && routeName != null) {
        final permission = ModuleRouteRegistry.getRoutePermission(routeName);

        if (permission != null) {
          final hasAccess = rbacService.hasPermission(
            permission.moduleId,
            permission.action,
          );

          debugPrint(
            'AppRouter: RBAC Check | Route: $routeName | Module: ${permission.moduleId} | Action: ${permission.action.name} | Role: $roleName | Allowed: $hasAccess',
          );

          if (!hasAccess) {
            debugPrint(
              'AppRouter: Access denied for route $routeName -> Redirecting to unauthorized',
            );
            return AppRoute.unauthorized;
          }
        } else {
          // Verbose logging of unprotected routes
          debugPrint(
            'AppRouter: No RBAC permission found for route $routeName',
          );
        }
      }

      return null;
    },
  );
});

final authRoutes = [
  GoRoute(
    path: AppRoute.loading,
    builder: (context, state) => const LoadingPage(),
  ),
  GoRoute(
    name: AppRoute.welcomeName,
    path: AppRoute.welcome,
    builder: (context, state) => const WelcomePage(),
  ),
  GoRoute(
    name: AppRoute.loginName,
    path: AppRoute.login,
    builder: (context, state) => const AuthPage(),
  ),
  GoRoute(
    name: AppRoute.signupName,
    path: AppRoute.signup,
    builder: (context, state) => const AuthPage(),
  ),
  GoRoute(
    name: AppRoute.profileName,
    path: AppRoute.profile,
    builder: (context, state) => const UserProfilePage(),
  ),
  GoRoute(
    name: AppRoute.cartName,
    path: AppRoute.cart,
    builder: (context, state) => const CartPage(),
  ),
  GoRoute(
    name: 'purchase_order_collection',
    path: '/purchase_orders/:poId/collect',
    builder: (context, state) =>
        PurchaseOrderCollectionPage(poId: state.pathParameters['poId']!),
  ),
  GoRoute(
    name: AppRoute.unauthorizedName,
    path: AppRoute.unauthorized,
    builder: (context, state) => const UnauthorizedPage(),
  ),
];
