import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/public_gateway_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/stream/AuthenticatedUserStreamRepository.dart';
import 'package:flutter_app/src/models/authenticated_user.dart';
import 'package:flutter_app/src/models/payment/protected_credit_card.dart';
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
  static const int defaultCarouselPage = 0;

  bool isDefaultPaymentChangeHappening = false;
  String? selectedDefaultPaymentId;

  fs.CardEditController controller = fs.CardEditController();
  fs.CardFieldInputDetails? cardFieldInputDetails;

  List<ProtectedCreditCard> sortedCards = List.empty();

  int _currentCarouselPage = defaultCarouselPage;
  final CarouselController _carouselController = CarouselController();

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
          if (state is CardDeletedSuccessfully) {
            SnackbarUtils.showSnackBarShort(context, "Card removed successfully!");
          }
          if (state is CardAddedSuccessfully) {
            SnackbarUtils.showSnackBarShort(context, "Card added successfully!");
          }
        },
        child: BlocBuilder<ManagePremiumBloc, ManagePremiumState>(
          builder: (context, state) {
            if (state is SubscriptionInfoLoaded) {
              sortedCards = state.cards;
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
      children: WidgetUtils.skipNulls([
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
        creditCardCarouselView(),
        WidgetUtils.spacer(5),
        _showDeleteCurrentCardTextIfNeeded(),
        _changeDefaultPaymentMethodText(),
        WidgetUtils.spacer(5),
        _addPaymentMethodText(),
        WidgetUtils.spacer(5),
      ]),
    );
  }

  _deleteCurrentCard() {
    final selectedPaymentIdToDelete = sortedCards[_currentCarouselPage].paymentMethodId;
    _managePremiumBloc.add(
        RemovePaymentMethodForUser(
            user: widget.authenticatedUser,
            paymentMethodId: selectedPaymentIdToDelete
        )
    );
    SnackbarUtils.showSnackBarShort(context, "Please wait... your card is being deleted...");
  }

  _showDeleteCurrentCardTextIfNeeded() {
    if (isDefaultPaymentChangeHappening && sortedCards.length > 1) {
      return Column(
        children: [
          Center(
            child: InkWell(
              onTap: () {
                _showCardRemoveConfirmationDialog();
              },
              child: const Text(
                "Delete current payment method",
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 14
                ),
              ),
            ),
          ),
          WidgetUtils.spacer(5),
        ],
      );
    }
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

  _changeDefaultPaymentMethodText() {
    return Center(
      child: InkWell(
        onTap: () {
          if (isDefaultPaymentChangeHappening) {
            final selectedDefaultPaymentId = sortedCards[_currentCarouselPage].paymentMethodId;
            _managePremiumBloc.add(
                MakePaymentMethodUsersDefault(
                    user: widget.authenticatedUser,
                    paymentMethodId: selectedDefaultPaymentId
                )
            );
          }
          setState(() {
            isDefaultPaymentChangeHappening = !isDefaultPaymentChangeHappening;
          });
        },
        child: Text(
          isDefaultPaymentChangeHappening ? "Save current as default" : "Change default payment method",
          style: const TextStyle(
            color: Colors.teal,
            fontSize: 14
          ),
        ),
      ),
    );
  }

  _addPaymentMethodText() {
    return Center(
      child: InkWell(
        onTap: () {
          _showAddPaymentMethodDialog();
        },
        child: const Text(
          "Add payment method",
          style: TextStyle(
              color: Colors.teal,
              fontSize: 14
          ),
        ),
      ),
    );
  }

  _saveCardDetails() async {
    if (cardFieldInputDetails?.complete ?? false) {
      final billingDetails = fs.BillingDetails(
        email: widget.authenticatedUser.user.email,
      );
      final paymentMethod = await fs.Stripe.instance.createPaymentMethod(
          params: fs.PaymentMethodParams.card(
            paymentMethodData: fs.PaymentMethodData(
              billingDetails: billingDetails,
            ),
          )
      );

      // Make changes with bloc here
      _managePremiumBloc.add(
          AddPaymentMethodToUser(
              user: widget.authenticatedUser,
              paymentMethodId: paymentMethod.id
          )
      );

    }
  }

  _showAddPaymentMethodDialog() {
    _dialogContent() {
      return Column(
        children: [
          WidgetUtils.spacer(5),
          const Text(
            "Enter your card details",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal
            ),
          ),
          WidgetUtils.spacer(10),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: fs.CardField(
              controller: controller,
              onCardChanged: (card) {
                setState(() {
                  cardFieldInputDetails = card;
                });
              },
            ),
          ),
          WidgetUtils.spacer(25),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                  child: const Text(
                      "Cancel",
                      style: TextStyle(fontSize: 15, color: Colors.white)
                  ),
                ),
              ),
              const Expanded(
                  flex: 1,
                  child: Visibility(
                    visible: false,
                    child: Text(""),
                  )
              ),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(ColorUtils.BUTTON_AVAILABLE),
                  ),
                  onPressed: () async {
                    if (cardFieldInputDetails?.complete ?? false) {
                      Navigator.pop(context);
                      _saveCardDetails();
                      SnackbarUtils.showSnackBarShort(context, "Hang on while we add your new payment method...");
                    }
                  },
                  child: const Text(
                      "Save",
                      style: TextStyle(fontSize: 15, color: Colors.white)
                  ),
                ),
              ),

            ],
          )
        ],
      );
    }

    _dialogContentCard() {
      return IntrinsicHeight(
        child: Card(
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: _dialogContent(),
              ),
            )
        ),
      );
    }

    showDialog(context: context, builder: (context) {
      return Dialog(
        child: _dialogContentCard(),
      );
    });
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
              _showCancelConfirmationDialog();
            // }
          },
          child: const Text("Cancel Fitcentive+", style: TextStyle(fontSize: 15, color: Colors.white)),
        ),
      ),
    );
  }

  _showCancelConfirmationDialog() {
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

  _showCardRemoveConfirmationDialog() {
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
      Widget deleteButton = TextButton(
        onPressed:  () {
          Navigator.pop(context);
          _deleteCurrentCard();
        },
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all<Color>(Colors.redAccent),
        ),
        child: const Text("Remove"),
      );

      return AlertDialog(
        title: const Text(
          "Remove Payment Method",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        content: const Text("You are about to remove this payment method. Are you sure?"),
        actions: [
          cancelButton,
          deleteButton,
        ],
      );
    });
  }

  _showCardDetails(ProtectedCreditCard card) {
    return CreditCardWidget(
      cardNumber: "${ConstantUtils.baseCardNumbers}${card.lastFour}",
      expiryDate: "${card.expiryMonth}/${card.expiryYear}",
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
    );
  }

  _generateCarouselOrStaticImage(List<ProtectedCreditCard> cards) {
    if (cards.isNotEmpty) {
      return cards.map((e) =>
          SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              width: MediaQuery.of(context).size.width * 0.65,
              child: _showCardDetails(e)
          )
      ).toList();
    }
    else {
      return [
        SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            width: MediaQuery.of(context).size.width * 0.65,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () {
                  // Add card UI
                },
                child: const Text(
                  "No previously saved cards... click here to add one",
                  style: TextStyle(
                    color: Colors.teal,
                    fontSize: 14,
                  ),
                ),
              ),
            )
        )
      ];
    }
  }

  _displayCarousel(List<ProtectedCreditCard> cards) {
    return CarouselSlider(
        carouselController: _carouselController,
        items: _generateCarouselOrStaticImage(cards),
        options: CarouselOptions(
          height: 200,
          // aspectRatio: 3.0,
          viewportFraction: 0.825,
          initialPage: 0,
          enableInfiniteScroll: false,
          scrollPhysics: isDefaultPaymentChangeHappening ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
          reverse: false,
          enlargeCenterPage: true,
          enlargeStrategy: CenterPageEnlargeStrategy.height,
          onPageChanged: (page, reason) {
            setState(() {
              _currentCarouselPage = page;
            });
          },
          scrollDirection: Axis.horizontal,
        )
    );
  }

  _generateDotsIfNeeded(List<ProtectedCreditCard> cards) {
    if (cards.isNotEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: cards.asMap().entries.map((entry) {
          return Container(
            width: 8.0,
            height: 8.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black)
                    .withOpacity(_currentCarouselPage == entry.key ? 0.9 : 0.4)),
          );
        }).toList(),
      );
    }
    return null;
  }

  Widget creditCardCarouselView() {
    return Card(
      // borderOnForeground: true,
      shape: !isDefaultPaymentChangeHappening ? null : RoundedRectangleBorder(
          side: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2.5
          )
      ),
      elevation: 0,
      color: Theme.of(context).backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: WidgetUtils.skipNulls([
            WidgetUtils.spacer(10),
            _displayCarousel(sortedCards),
            WidgetUtils.spacer(2.5),
            _generateDotsIfNeeded(sortedCards),
            WidgetUtils.spacer(2.5),
          ]),
        ),
      ),
    );
  }

}