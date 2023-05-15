import 'package:flutter_app/src/infrastructure/repos/rest/public_gateway_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/stream/AuthenticatedUserStreamRepository.dart';
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

  }
}