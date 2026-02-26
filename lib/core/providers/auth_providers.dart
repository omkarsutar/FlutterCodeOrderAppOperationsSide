import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'core_providers.dart';
import '../../features/postLogin/users/user_barrel.dart';
import 'user_profile_state_provider.dart';

/// Provides the authentication service
final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final rbacService = ref.watch(rbacServiceProvider);
  return AuthService(client, rbacService, ref);
});

/// Stream of authentication state changes
final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

/// Stream of the current user's profile
final userProfileProvider = StreamProvider<ModelUser?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final authState = ref.watch(authStateProvider).value;

  final user = authState?.session?.user ?? client.auth.currentUser;
  if (user == null) return Stream.value(null);

  return client
      .from(ModelUserFields.table)
      .stream(primaryKey: [ModelUserFields.userId])
      .eq(ModelUserFields.userId, user.id)
      .map((snapshot) {
        if (snapshot.isEmpty) return null;
        return ModelUser.fromMap(snapshot.first);
      });
});

/// Provider for the enriched user profile (with labels)
final enrichedUserProfileProvider = FutureProvider<ModelUser?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userProfile = ref.watch(userProfileProvider).value;

  if (userProfile == null) return null;

  final enriched = await client
      .from(ModelUserFields.tableViewWithForeignKeyLabels)
      .select()
      .eq(ModelUserFields.userId, userProfile.userId)
      .single();

  final updatedProfile = ModelUser.fromMap(enriched);
  // Optional: keep userProfileStateProvider in sync for legacy code
  ref.read(userProfileStateProvider.notifier).setProfile(updatedProfile);
  return updatedProfile;
});
