import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/public_gateway_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/stream/AuthenticatedUserStreamRepository.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/color_utils.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/image_utils.dart';
import 'package:flutter_app/src/utils/snackbar_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/manage_premium/bloc/manage_premium_bloc.dart';
import 'package:flutter_app/src/views/manage_premium/bloc/manage_premium_event.dart';
import 'package:flutter_app/src/views/manage_premium/bloc/manage_premium_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as fs;
import 'package:intl/intl.dart';

class ManagePremiumView extends StatefulWidget {
  static const String routeName = "manage-premium";

  final PublicUserProfile currentUserProfile;
  final AuthenticatedUser authenticatedUser;

  const ManagePremiumView({
    super.key,
    required this.currentUserProfile,
    required this.authenticatedUser,
  });

  static Route route({
    required PublicUserProfile currentUserProfile,
    required AuthenticatedUser authenticatedUser,
  }) => MaterialPageRoute(
    settings: const RouteSettings(
        name: routeName
    ),
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider<ManagePremiumBloc>(
            create: (context) => ManagePremiumBloc(
              userRepository: RepositoryProvider.of<UserRepository>(context),
              secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
              publicGatewayRepository: RepositoryProvider.of<PublicGatewayRepository>(context),
              authUserStreamRepository: RepositoryProvider.of<AuthenticatedUserStreamRepository>(context),
            )),
      ],
      child: ManagePremiumView(
        currentUserProfile: currentUserProfile,
        authenticatedUser: authenticatedUser,
      ),
    ),
  );

  @override
  State<StatefulWidget> createState() {
    return ManagePremiumViewState();
  }
}

class ManagePremiumViewState extends State<ManagePremiumView> {

  fs.CardEditController controller = fs.CardEditController();
  fs.CardFieldInputDetails? cardFieldInputDetails;

  late ManagePremiumBloc _managePremiumBloc;

  void update() => setState(() {});

  @override
  void initState() {
    super.initState();

    _managePremiumBloc = BlocProvider.of<ManagePremiumBloc>(context);
    controller.addListener(update);

    _managePremiumBloc.add(
        FetchUserPremiumSubscription(
          user: widget.authenticatedUser
        )
    );
  }

  @override
  void dispose() {
    controller.removeListener(update);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Fitcentive+',
          style: TextStyle(
              color: Colors.teal,
              fontWeight: FontWeight.bold
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.teal,
        ),
      ),
      body: BlocListener<ManagePremiumBloc, ManagePremiumState>(
        listener: (context, state) {
          if (state is CancelPremiumComplete) {
            SnackbarUtils.showSnackBar(context, "You have cancelled your subscription successfully");
            Navigator.pop(context);
          }
          if (state is CancelLoading) {
            SnackbarUtils.showSnackBar(context, "Hold on... let's cancel your subscription...");
          }
        },
        child: BlocBuilder<ManagePremiumBloc, ManagePremiumState>(
          builder: (context, state) {
            if (state is SubscriptionInfoLoaded) {
              return Center(
                child: _dialogContentCard(state),
              );
            }
            else {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.teal,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _userProfileImageView() {
    return Center(
      child: SizedBox(
        width: 100,
        height: 100,
        child: GestureDetector(
          onTap: () async {},
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: ImageUtils.getUserProfileImage(widget.currentUserProfile, 50, 50),
            ),
            child: widget.currentUserProfile.photoUrl == null ? const Icon(
              Icons.account_circle_outlined,
              color: Colors.teal,
              size: 100,
            )
                : null,
          ),
        ),
      ),
    );
  }

  _dialogContentCard(SubscriptionInfoLoaded state) {
    return IntrinsicHeight(
      child: Card(
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Container(
              padding: const EdgeInsets.all(10),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    WidgetUtils.spacer(5),
                    _userProfileImageView(),
                    WidgetUtils.spacer(10),
                    mainContent(state),
                    WidgetUtils.spacer(25),
                    _cancelPremiumButton(),
                    WidgetUtils.spacer(10),
                  ],
                ),
              ),
          )
      ),
    ));
  }

  mainContent(SubscriptionInfoLoaded state) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        WidgetUtils.spacer(5),
        const Text(
          "You are currently subscribed to Fitcentive+!",
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal
          ),
        ),
        WidgetUtils.spacer(15),
        const Text(
          "Your billing period",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            // color: Colors.teal
          ),
        ),
        WidgetUtils.spacer(5),
        Text(
          "${DateFormat('yyyy-MM-dd').format(state.subscription.startedAt.toLocal())} - ${DateFormat('yyyy-MM-dd').format(state.subscription.validUntil.toLocal())}",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            // color: Colors.teal
          ),
        ),
        WidgetUtils.spacer(15),
        const Text(
          "Your next payment date",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            // color: Colors.teal
          ),
        ),
        WidgetUtils.spacer(5),
        Text(
          DateFormat('yyyy-MM-dd').format(state.subscription.validUntil.toLocal().add(const Duration(days: 1))),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            // color: Colors.teal
          ),
        ),
        WidgetUtils.spacer(15),
        const Text(
          "Your payment method",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            // color: Colors.teal
          ),
        ),
        WidgetUtils.spacer(5),
        _showCardDetails(state),
        WidgetUtils.spacer(5),
        _changePaymentMethodText(),
        WidgetUtils.spacer(5),
      ],
    );
  }

  MaterialStateProperty<Color> _getBackgroundColor() {
    return MaterialStateProperty.all<Color>(ColorUtils.BUTTON_DANGER);
  }

  _initiateCancelPremium() async {
    // if (cardFieldInputDetails?.complete ?? false) {
      _managePremiumBloc.add(
          CancelPremium(
              user: widget.authenticatedUser
          )
      );
    // }
  }

  _changePaymentMethodText() {
    return Center(
      child: InkWell(
        onTap: () {
          // todo - need a view to accept/update card details and call APIs appropro
          // Show dialog to change card details here
        },
        child: const Text(
          "Change payment method",
          style: TextStyle(
            color: Colors.teal,
            fontSize: 14
          ),
        ),
      ),
    );
  }

  _cancelPremiumButton() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ElevatedButton(
          style: ButtonStyle(
            backgroundColor: _getBackgroundColor(),
          ),
          onPressed: () async {
            // if (cardFieldInputDetails?.complete ?? false) {
              _showConfirmationDialog();
            // }
          },
          child: const Text("Cancel Fitcentive+", style: TextStyle(fontSize: 15, color: Colors.white)),
        ),
      ),
    );
  }

  _showConfirmationDialog() {
    showDialog(context: context, builder: (context) {
      Widget cancelButton = TextButton(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all<Color>(Colors.teal),
        ),
        onPressed:  () {
          Navigator.pop(context);
        },
        child: const Text("Cancel"),
      );
      Widget unsusbcribeButton = TextButton(
        onPressed:  () {
          Navigator.pop(context);
          _initiateCancelPremium();
        },
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all<Color>(Colors.redAccent),
        ),
        child: const Text("Unsubscribe"),
      );

      return AlertDialog(
        title: const Text(
          "Cancel Fitcentive+",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        content: const Text("You are about to unsubscribe from Fitcentive+. This will cancel your subscription now without a refund"),
        actions: [
          cancelButton,
          unsusbcribeButton,
        ],
      );
    });
  }

  _showCardDetails(SubscriptionInfoLoaded state) {
    return SizedBox(
      height: 175,
      width: 350,
      child: CreditCardWidget(
        cardNumber: "${ConstantUtils.baseCardNumbers}${state.card.lastFour}",
        expiryDate: "${state.card.expiryMonth}/${state.card.expiryYear}",
        cardHolderName: "",
        cvvCode: "XXX",
        showBackView: false,
        cardBgColor: Colors.black,
        obscureCardNumber: true,
        obscureInitialCardNumber: true,
        obscureCardCvv: true,
        isHolderNameVisible: false,
        onCreditCardWidgetChange: (CreditCardBrand ) {

        }, //true when you want to show cvv(back) view
      ),
    );
  }

}