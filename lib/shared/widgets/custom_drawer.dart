import 'package:flutter/material.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/notes/note_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/products/product_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/purchase_orders/purchase_order_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/rbac_modules/rbac_module_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/rbac_permissions/rbac_permission_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/roles/role_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/route_shop_links/route_shop_link_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/routes/route_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/shops/shop_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/po_collections/po_collection_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/users/user_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/retailer_shop_links/retailer_shop_link_barrel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/core_providers.dart';

import '../../core/utils/dialogs.dart';
import '../../router/app_routes.dart';
import 'read_entity_tile.dart';

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  String? _userDisplayName(WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      // Fallback to metadata if profile not yet loaded/available
      final name = currentUser?.userMetadata?['name']?.toString();
      if (name != null && name.isNotEmpty) return name;
      return currentUser?.email;
    }
    return user.fullName ?? currentUser?.email;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch initialization state to trigger rebuilds for Role display, etc.
    ref.watch(rbacInitializationProvider);

    final authService = ref.watch(authServiceProvider);
    final rbacService = ref.watch(rbacServiceProvider);
    final displayName = _userDisplayName(ref);
    final theme = Theme.of(context);
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (displayName != null)
                  Text(
                    "Order App",
                    style: TextStyle(color: theme.colorScheme.onPrimary),
                  ),
                Text(
                  displayName != null
                      ? 'Welcome, $displayName'
                      : 'Welcome to Order App',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                if (rbacService.roleName != null)
                  Text(
                    'Role: ${rbacService.roleName!}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),

          /* ListTile(
            leading: const Icon(Icons.tab), // 🗂️ Shop Tabs
            title: const Text('Shop Tabs'),
            onTap: () => context.goNamed(ShopsRoutes.shopsWithoutTodaysPOsName),
          ), */
          ReadEntityTile(
            moduleName: ModelShopFields.table, // "shops"
            routeName: ShopsRoutesJson.listRouteName,
            title: 'Todays Shops',
            icon: Icons.store,
            queryParameters: {
              'tapCondition': 'listWithoutTodaysPOs',
              'route_filter': 'north',
            },
            // Hide "Todays Shops" from drawer for deliveryperson and salesperson (they use "Todays Shops" or via POs)
            // But they still have "Read" permission so the route works.
            visible: !['deliveryperson'].contains(rbacService.roleName),
          ),

          // Purchase Orders
          ReadEntityTile(
            moduleName: ModelPurchaseOrderFields.table, // "purchase_orders"
            routeName: PurchaseOrdersRoutesJson.listRouteName,
            title: 'Purchase Orders',
            icon: Icons.receipt_long,
          ),

          // Products
          ReadEntityTile(
            moduleName: ModelProductFields.table, // "products"
            routeName: ProductsRoutesJson.listRouteName,
            title: 'Products',
            icon: Icons.shopping_bag,
            allowAnonymous: true,
          ),

          // Collections
          ReadEntityTile(
            moduleName: ModelPoCollectionFields.table, // "po_collections"
            routeName: 'collections',
            title: 'Collections',
            icon: Icons.payments,
          ),

          ListTile(
            leading: const Icon(Icons.shopping_cart), // 🛒 My Cart
            title: const Text('My Cart'),
            onTap: () => context.goNamed(AppRoute.cartName),
          ),

          if (isLoggedIn)
            ListTile(
              leading: const Icon(Icons.person), // 👤 Profile
              title: const Text('Profile'),
              onTap: () => context.goNamed(AppRoute.profileName),
            ),

          // Shops
          ReadEntityTile(
            moduleName: ModelShopFields.table, // "shops"
            routeName: ShopsRoutesJson.listRouteName,
            title: 'All Shops',
            icon: Icons.store,
            // Hide "All Shops" from drawer for deliveryperson and salesperson (they use "Todays Shops" or via POs)
            // But they still have "Read" permission so the route works.
            visible: ![
              'deliveryperson',
              'salesperson',
            ].contains(rbacService.roleName),
          ),

          // PO Items
          /* ReadEntityTile(
            moduleName: ModelPoItemFields.table, // "po_items"
            routeName: PoItemsRoutesJson.listRouteName,
            title: 'PO Items',
            icon: Icons.list_alt,
          ), */

          // Users
          ReadEntityTile(
            moduleName: ModelUserFields.table, // "users"
            routeName: UsersRoutesJson.listRouteName,
            title: 'Users',
            icon: Icons.group,
          ),

          // Roles
          ReadEntityTile(
            moduleName: ModelRoleFields.table, // "rbac_roles"
            routeName: RolesRoutesJson.listRouteName,
            title: 'Roles',
            icon: Icons.admin_panel_settings,
          ),

          // RBAC Modules
          ReadEntityTile(
            moduleName: ModelRbacModuleFields.table, // "rbac_modules"
            routeName: RbacModulesRoutesJson.listRouteName,
            title: 'RbacModules',
            icon: Icons.extension,
          ),

          // RBAC Permissions
          ReadEntityTile(
            moduleName: ModelRbacPermissionFields.table, // "rbac_permissions"
            routeName: RbacPermissionsRoutesJson.listRouteName,
            title: 'RbacPermissions',
            icon: Icons.lock_open,
          ),

          // Routes
          ReadEntityTile(
            moduleName: ModelRouteFields.table, // "routes"
            routeName: RoutesRoutesJson.listRouteName,
            title: 'Routes',
            icon: Icons.alt_route,
          ),

          // Route Shop Links
          ReadEntityTile(
            moduleName: ModelRouteShopLinkFields.table, // "route_shop_links"
            routeName: RouteShopLinksRoutesJson.listRouteName,
            title: 'Route Shop Links',
            icon: Icons.link,
          ),

          // Retailer Shop Links
          ReadEntityTile(
            moduleName:
                ModelRetailerShopLinkFields.table, // "retailer_shop_link"
            routeName: RetailerShopLinkRoutesJson.listRouteName,
            title: 'Retailer Shop Links',
            icon: Icons.link,
          ),

          // Notes
          ReadEntityTile(
            moduleName: ModelNoteFields.table, // "notes"
            routeName: NotesRoutesJson.listRouteName,
            title: 'Notes',
            icon: Icons.note,
          ),

          if (!isLoggedIn)
            ListTile(
              leading: const Icon(Icons.login), // 🔑 Login
              title: const Text('Login'),
              onTap: () => context.goNamed(AppRoute.loginName),
            ),

          if (!isLoggedIn)
            ListTile(
              leading: const Icon(Icons.waving_hand), // 👋 Welcome
              title: const Text('Welcome'),
              onTap: () => context.goNamed(AppRoute.welcomeName),
            ),

          if (Supabase.instance.client.auth.currentSession != null)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                final confirmed = await showConfirmationDialog(
                  context: context,
                  title: 'Logout',
                  content: 'Are you sure you want to Logout?',
                  confirmLabel: 'Logout',
                );
                if (confirmed) {
                  await authService.signOut();
                }
              },
            ),
        ],
      ),
    );
  }
}
