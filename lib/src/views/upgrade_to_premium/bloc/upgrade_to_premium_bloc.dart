import 'package:flutter_app/src/infrastructure/repos/rest/public_gateway_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/stream/AuthenticatedUserStreamRepository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/user.dart';
import 'package:flutter_app/src/views/upgrade_to_premium/bloc/upgrade_to_premium_event.dart';
import 'package:flutter_app/src/views/upgrade_to_premium/bloc/upgrade_to_premium_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UpgradeToPremiumBloc extends Bloc<UpgradeToPremiumEvent, UpgradeToPremiumState> {
  final UserRepository userRepository;
  final PublicGatewayRepository publicGatewayRepository;
  final FlutterSecureStorage secureStorage;
  final AuthenticatedUserStreamRepository authUserStreamRepository;

  UpgradeToPremiumBloc({
    required this.userRepository,
    required this.publicGatewayRepository,
    required this.secureStorage,
    required this.authUserStreamRepository,
  }) : super(const UpgradeToPremiumStateInitial()) {
    on<InitiateUpgradeToPremium>(_initiateUpgradeToPremium);
  }

  void _initiateUpgradeToPremium(InitiateUpgradeToPremium event, Emitter<UpgradeToPremiumState> emit) async {
    try {
      emit(const UpgradeLoading());
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final subscriptionId = await publicGatewayRepository.createStripeSubscription(event.paymentMethodId, accessToken!);

      final newPremiumUser = User(
          event.user.user.id,
          event.user.user.email,
          event.user.user.username,
          event.user.user.accountStatus,
          event.user.user.authProvider,
          event.user.user.enabled,
          true,
          event.user.user.createdAt,
          event.user.user.updatedAt
      );
      final updatedAuthenticatedUser = AuthenticatedUser(
          user: newPremiumUser,
          userAgreements: event.user.userAgreements,
          userProfile: event.user.userProfile,
          authTokens: event.user.authTokens,
          authProvider: event.user.authProvider
      );
      authUserStreamRepository.newUser(updatedAuthenticatedUser);

      emit(const UpgradeToPremiumComplete());
    } catch (ex) {
      emit(UpgradeToPremiumFailure(reason: ex.toString()));
    }

  }
}