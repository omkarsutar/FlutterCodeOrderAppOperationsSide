import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/postLogin/users/user_barrel.dart';

class UserProfileState {
  final ModelUser? profile;
  final String? cachedRouteId;
  final String? cachedRouteName;

  UserProfileState({this.profile, this.cachedRouteId, this.cachedRouteName});

  UserProfileState copyWith({
    ModelUser? profile,
    String? cachedRouteId,
    String? cachedRouteName,
    bool clearRouteCache = false,
  }) {
    return UserProfileState(
      profile: profile ?? this.profile,
      cachedRouteId: clearRouteCache
          ? null
          : (cachedRouteId ?? this.cachedRouteId),
      cachedRouteName: clearRouteCache
          ? null
          : (cachedRouteName ?? this.cachedRouteName),
    );
  }
}

class UserProfileNotifier extends Notifier<UserProfileState> {
  @override
  UserProfileState build() {
    return UserProfileState();
  }

  void setProfile(ModelUser profile) {
    state = state.copyWith(profile: profile, clearRouteCache: true);
  }

  void clearProfile() {
    state = UserProfileState();
  }

  void cacheRouteName(String routeId, String routeName) {
    state = state.copyWith(cachedRouteId: routeId, cachedRouteName: routeName);
  }

  String? getCachedRouteName(String routeId) {
    if (state.cachedRouteId == routeId) {
      return state.cachedRouteName;
    }
    return null;
  }
}

final userProfileStateProvider =
    NotifierProvider<UserProfileNotifier, UserProfileState>(() {
      return UserProfileNotifier();
    });
