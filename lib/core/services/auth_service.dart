import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:html' as html;
import '../providers/user_profile_state_provider.dart';

import '../../router/app_router.dart';

import '../../features/postLogin/users/user_barrel.dart';
import 'rbac_service.dart';
import 'error_handler.dart';

class AuthService {
  final SupabaseClient _client;
  final RbacService _rbacService;
  final Ref _ref;
  StreamSubscription<List<Map<String, dynamic>>>? _profileSubscription;

  AuthService(this._client, this._rbacService, this._ref);

  /// Sign in with Google and load user profile
  Future<void> signInWithGoogle() async {
    final redirectUri = kReleaseMode
        ? 'https://omkarsutar.github.io/OrderAppOperationsV01/'
        : 'http://localhost:3000/OrderAppOperationsV01/';

    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUri,
      );
    } catch (e, stackTrace) {
      ErrorHandler.handle(
        e,
        stackTrace,
        context: 'Google Sign-In',
        showToUser: true,
      );
      rethrow;
    }
  }

  /// Listen for auth state changes and keep profile in sync
  void initializeAuthListener() {
    _client.auth.onAuthStateChange.listen((authState) async {
      switch (authState.event) {
        case AuthChangeEvent.signedIn:
          if (kIsWeb) {
            // Clean up URL query parameters (code, state, etc.) after Google login redirect
            final currentUrl = html.window.location.href;
            if (currentUrl.contains('?')) {
              final newUrl =
                  currentUrl.split('?')[0] + html.window.location.hash;
              html.window.history.replaceState(null, '', newUrl);
              debugPrint('AuthService: Cleaned up URL parameters');
            }
          }
          await loadAndStoreUserProfile();
          initializeUserProfileStream();
          break;
        case AuthChangeEvent.signedOut:
          disposeProfileStream();
          _ref.read(userProfileStateProvider.notifier).clearProfile();
          _ref.read(routerProvider).go('/'); // Navigate to welcome page
          break;
        case AuthChangeEvent.tokenRefreshed:
        case AuthChangeEvent.userUpdated:
          // Keep profile fresh when token or user info changes
          await loadAndStoreUserProfile();
          break;
        default:
          break;
      }
    });
  }

  /// Load user profile from Supabase and store globally, then initialize RBAC
  Future<void> loadAndStoreUserProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final userData = await _client
        .from(ModelUserFields.table)
        .select('*')
        .eq(ModelUserFields.userId, userId)
        .single();

    final profile = ModelUser.fromMap(userData);

    // Initialize RBAC for the logged-in user BEFORE marking profile as ready
    await _rbacService.initializeRbac(userId);

    _ref.read(userProfileStateProvider.notifier).setProfile(profile);
  }

  /// Subscribe to realtime updates for the current user's profile
  void initializeUserProfileStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // Cancel any existing subscription
    _profileSubscription?.cancel();

    _profileSubscription = _client
        .from(ModelUserFields.table)
        .stream(primaryKey: [ModelUserFields.userId])
        .eq(ModelUserFields.userId, userId)
        .listen((snapshot) {
          if (snapshot.isNotEmpty) {
            final updatedProfile = ModelUser.fromMap(snapshot.first);
            _ref
                .read(userProfileStateProvider.notifier)
                .setProfile(updatedProfile);
          }
        });
  }

  /// Cancel profile stream subscription
  void disposeProfileStream() {
    _profileSubscription?.cancel();
    _profileSubscription = null;
  }

  /// Sign out the current user
  Future<void> signOut() async {
    _rbacService.clearCache();
    await _client.auth.signOut();
    disposeProfileStream();
    _ref.read(userProfileStateProvider.notifier).clearProfile();
  }

  /// Get the current Supabase user
  User? get currentUser => _client.auth.currentUser;
}
