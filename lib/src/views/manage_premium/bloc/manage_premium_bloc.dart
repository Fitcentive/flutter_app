import 'package:flutter_app/src/infrastructure/repos/rest/public_gateway_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/stream/authenticated_user_stream_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/user.dart';
import 'package:flutter_app/src/views/manage_premium/bloc/manage_premium_event.dart';
import 'package:flutter_app/src/views/manage_premium/bloc/manage_premium_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ManagePremiumBloc extends Bloc<ManagePremiumEvent, ManagePremiumState> {
  final UserRepository userRepository;
  final PublicGatewayRepository publicGatewayRepository;
  final FlutterSecureStorage secureStorage;
  final AuthenticatedUserStreamRepository authUserStreamRepository;

  ManagePremiumBloc({
    required this.userRepository,
    required this.publicGatewayRepository,
    required this.secureStorage,
    required this.authUserStreamRepository,
  }) : super(const ManagePremiumStateInitial()) {
    on<CancelPremium>(_cancelPremium);
    on<FetchUserPremiumSubscription>(_fetchUserPremiumSubscription);
    on<AddPaymentMethodToUser>(_addPaymentMethodToUser);
    on<MakePaymentMethodUsersDefault>(_makePaymentMethodUsersDefault);
    on<RemovePaymentMethodForUser>(_removePaymentMethodForUser);
  }

  void _removePaymentMethodForUser(RemovePaymentMethodForUser event, Emitter<ManagePremiumState> emit) async {
    final currentState = state;
    if (currentState is SubscriptionInfoLoaded) {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      await publicGatewayRepository.deletePaymentMethodForCustomer(event.paymentMethodId, accessToken!);

      emit(const CardDeletedSuccessfully());

      final cards = await publicGatewayRepository.getPaymentMethodsForUser(accessToken);

      final defaultCard = cards.where((element) => element.isDefault).first;
      final otherCards = cards.where((element) => !element.isDefault);
      final sortedCards = [defaultCard, ...otherCards];

      emit(
          SubscriptionInfoLoaded(
              subscription: currentState.subscription,
              cards: sortedCards
          )
      );
    }
  }

  void _makePaymentMethodUsersDefault(MakePaymentMethodUsersDefault event, Emitter<ManagePremiumState> emit) async {
    final currentState = state;
    if (currentState is SubscriptionInfoLoaded) {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      await publicGatewayRepository.makePaymentMethodDefaultForCustomer(event.paymentMethodId, accessToken!);

      final cards = await publicGatewayRepository.getPaymentMethodsForUser(accessToken);

      final defaultCard = cards.where((element) => element.isDefault).first;
      final otherCards = cards.where((element) => !element.isDefault);
      final sortedCards = [defaultCard, ...otherCards];

      emit(
          SubscriptionInfoLoaded(
              subscription: currentState.subscription,
              cards: sortedCards
          )
      );
    }
  }

  void _addPaymentMethodToUser(AddPaymentMethodToUser event, Emitter<ManagePremiumState> emit) async {
    final currentState = state;
    if (currentState is SubscriptionInfoLoaded) {
      try {
        final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
        final newPaymentMethod = await publicGatewayRepository.addPaymentMethodToCustomer(event.paymentMethodId, accessToken!);

        emit(const CardAddedSuccessfully());

        final cards = await publicGatewayRepository.getPaymentMethodsForUser(accessToken);

        final defaultCard = cards.where((element) => element.isDefault).first;
        final otherCards = cards.where((element) => !element.isDefault);
        final sortedCards = [defaultCard, ...otherCards];

        emit(
            SubscriptionInfoLoaded(
                subscription: currentState.subscription,
                cards: sortedCards
            )
        );
      } catch (ex) {
        emit(const CardAddFailure());
        emit(
            SubscriptionInfoLoaded(
                subscription: currentState.subscription,
                cards: currentState.cards
            )
        );
      }
    }
  }

  void _fetchUserPremiumSubscription(FetchUserPremiumSubscription event, Emitter<ManagePremiumState> emit) async {
    emit(const SubscriptionInfoLoading());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    // Hacky fix because users only have 1 subscription for now ideally
    final subscriptionFut = publicGatewayRepository.getUserSubscriptions(accessToken!);
    final cardsFut = publicGatewayRepository.getPaymentMethodsForUser(accessToken);
    // Hacky fix because users only have 1 card for now
    // final cards = await publicGatewayRepository.getPaymentMethodsForUser(accessToken);

    final subscription = await subscriptionFut;
    final cards = await cardsFut;

    final defaultCard = cards.where((element) => element.isDefault).first;
    final otherCards = cards.where((element) => !element.isDefault);
    final sortedCards = [defaultCard, ...otherCards];

    emit(
        SubscriptionInfoLoaded(
          subscription: subscription.first,
          cards: sortedCards
        )
    );
  }

  void _cancelPremium(CancelPremium event, Emitter<ManagePremiumState> emit) async {
    emit(const CancelLoading());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    await publicGatewayRepository.cancelStripeSubscription(accessToken!);

    final plebUser = User(
        event.user.user.id,
        event.user.user.email,
        event.user.user.username,
        event.user.user.accountStatus,
        event.user.user.authProvider,
        event.user.user.enabled,
        false,
        event.user.user.createdAt,
        event.user.user.updatedAt
    );
    final updatedAuthenticatedUser = AuthenticatedUser(
        user: plebUser,
        userAgreements: event.user.userAgreements,
        userProfile: event.user.userProfile,
        authTokens: event.user.authTokens,
        authProvider: event.user.authProvider
    );
    authUserStreamRepository.newUser(updatedAuthenticatedUser);

    emit(const CancelPremiumComplete());
  }
}