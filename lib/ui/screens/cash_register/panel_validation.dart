import 'package:coopaz_app/dao/order_dao.dart';
import 'package:coopaz_app/podo/member.dart';
import 'package:coopaz_app/podo/payment_method.dart';
import 'package:coopaz_app/state/app_model.dart';
import 'package:coopaz_app/state/cash_register.dart';
import 'package:coopaz_app/ui/common_widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:coopaz_app/logger.dart';
import 'package:provider/provider.dart';

class ValidationPanel extends StatelessWidget {
  const ValidationPanel(
      {super.key,
      required this.tab,
      required this.orderDao,
      required this.formKey});

  final int tab;
  final GlobalKey<FormState> formKey;
  final OrderDao orderDao;

  final String title = 'Caisse';

  static const double cardFeeRate = 0.00553;

  @override
  Widget build(BuildContext context) {
    log('build ValidationPanel');

    AppModel appModel = context.watch<AppModel>();
    CashRegisterModel cashRegisterModel = context.watch<CashRegisterModel>();

    double subtotal = context
        .watch<CashRegisterModel>()
        .cart(tab)
        .map((e) =>
            (double.tryParse(e.qty ?? '0') ?? 0.0) * (e.product?.price ?? 0.0))
        .fold(0.0, (prev, e) => prev + e);

    double cardFee = 0.0;
    if (cashRegisterModel.selectedPaymentMethod(tab) == PaymentMethod.card) {
      cardFee = subtotal * ValidationPanel.cardFeeRate;
    }

    double total = subtotal + cardFee;

    double smallText = appModel.smallText * appModel.zoomText;
    double mediumText = appModel.mediumText * appModel.zoomText;

    return Column(children: [
      Expanded(
          child: ListView(children: [
        Row(children: [
          Expanded(
              child: Container(
                  padding: const EdgeInsets.only(top: 8),
                  alignment: Alignment.bottomLeft,
                  child: Text('Adhérent :',
                      textScaleFactor: appModel.zoomText,
                      style: const TextStyle(fontWeight: FontWeight.w600))))
        ]),
        Row(children: [
          Expanded(
              child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  alignment: Alignment.bottomLeft,
                  child: Autocomplete<Member>(
                    key: ValueKey(
                        cashRegisterModel.selectedMember(tab)?.name ?? ''),
                    initialValue: TextEditingValue(
                        text:
                            cashRegisterModel.selectedMember(tab)?.name ?? ''),
                    displayStringForOption: (Member m) => m.name,
                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      if (textEditingValue.text == '') {
                        return const Iterable<Member>.empty();
                      }
                      return appModel.members.where((Member m) {
                        return m
                            .toString()
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    fieldViewBuilder: (BuildContext context,
                        TextEditingController fieldTextEditingController,
                        FocusNode fieldFocusNode,
                        VoidCallback onFieldSubmitted) {
                      return TextFormField(
                        enabled:
                            !cashRegisterModel.isAwaitingSendFormResponse(tab),
                        decoration: const InputDecoration(
                          hintText: 'Nom adhérent',
                        ),
                        controller: fieldTextEditingController,
                        focusNode: fieldFocusNode,
                        style: TextStyle(fontSize: mediumText),
                        validator: (String? value) {
                          String? result;
                          if (value?.isEmpty ?? false) {
                            result = 'Adhérent invalide';
                          }
                          return result;
                        },
                      );
                    },
                    onSelected: (m) {
                      cashRegisterModel.setSelectedMember(tab, m);
                    },
                  )))
        ]),
        Row(children: [
          Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.topLeft,
                  child: Text('Sous total : ',
                      style: TextStyle(fontSize: smallText)))),
          Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.topLeft,
                  child: Text('${subtotal.toStringAsFixed(2)}€',
                      style: TextStyle(fontSize: smallText))))
        ]),
        Row(children: [
          Expanded(
              child: Container(
                  padding: const EdgeInsets.only(top: 25),
                  alignment: Alignment.bottomLeft,
                  child: Text('Paiement : ',
                      style: TextStyle(fontSize: smallText))))
        ]),
        Row(children: [
          Expanded(
              flex: 2,
              child: !cashRegisterModel.isAwaitingSendFormResponse(tab)
                  ? DropdownButton<PaymentMethod>(
                      value: cashRegisterModel.selectedPaymentMethod(tab),
                      elevation: 16,
                      onChanged: (PaymentMethod? value) {
                        // This is called when the user selects an item.
                        cashRegisterModel.setSelectedPaymentMethod(
                            tab, value ?? PaymentMethod.card);
                      },
                      items: PaymentMethod.values
                          .map<DropdownMenuItem<PaymentMethod>>(
                              (PaymentMethod value) {
                        return DropdownMenuItem<PaymentMethod>(
                          value: value,
                          child: Text(value.asString,
                              style: TextStyle(fontSize: smallText)),
                        );
                      }).toList(),
                    )
                  : Text(cashRegisterModel.selectedPaymentMethod(tab).asString,
                      textScaleFactor: appModel.zoomText))
        ]),
        if (cashRegisterModel.selectedPaymentMethod(tab) ==
            PaymentMethod.cheque)
          TextFormField(
            controller: TextEditingController(
                text: cashRegisterModel.chequeOrTransferNumber(tab))
              ..selection = TextSelection.collapsed(
                  offset: cashRegisterModel.chequeOrTransferNumber(tab).length),
            decoration: const InputDecoration(
              hintText: 'N. chèque',
            ),
            onChanged: (String value) {
              cashRegisterModel.setChequeOrTransferNumber(tab, value);
            },
            textAlign: TextAlign.right,
          ),
        if (cashRegisterModel.selectedPaymentMethod(tab) ==
            PaymentMethod.transfer)
          TextFormField(
            controller: TextEditingController(
                text: cashRegisterModel.chequeOrTransferNumber(tab))
              ..selection = TextSelection.collapsed(
                  offset:
                      (cashRegisterModel.chequeOrTransferNumber(tab)).length),
            decoration: const InputDecoration(
              hintText: 'N. virement',
            ),
            onChanged: (String value) {
              cashRegisterModel.setChequeOrTransferNumber(tab, value);
            },
            textAlign: TextAlign.right,
          ),
        if (cashRegisterModel.selectedPaymentMethod(tab) == PaymentMethod.card)
          Row(children: [
            Expanded(
                flex: 1,
                child: Align(
                    alignment: Alignment.topLeft,
                    child: Text('Frais CB : ',
                        style: TextStyle(fontSize: smallText)))),
            Expanded(
                flex: 1,
                child: Align(
                    alignment: Alignment.topLeft,
                    child: Text('${cardFee.toStringAsFixed(2)}€',
                        style: TextStyle(fontSize: smallText))))
          ]),
        Row(children: [
          Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.topLeft,
                  child: Text('Total : ',
                      textScaleFactor: appModel.zoomText,
                      style: const TextStyle(fontWeight: FontWeight.bold)))),
          Expanded(
              flex: 1,
              child: Align(
                  alignment: Alignment.topLeft,
                  child: Text('${total.toStringAsFixed(2)}€',
                      textScaleFactor: appModel.zoomText,
                      style: const TextStyle(fontWeight: FontWeight.bold))))
        ]),
      ])),
      if (cashRegisterModel.isAwaitingSendFormResponse(tab) == false)
        Center(
            child: Container(
          padding: const EdgeInsets.symmetric(vertical: 25.0),
          child: FloatingActionButton.extended(
            heroTag: null,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            onPressed: () {
              if (_validateAll()) {
                log('Send form !!!');
                _sendForm(cashRegisterModel);
              } else {
                log('Form invalid');
              }
            },
            tooltip: 'Valider le formulaire et envoyer la facture',
            label: Text('Valider', textScaleFactor: appModel.zoomText),
          ),
        ))
      else
        const Loading(text: "En attente du traitement de la facture..."),
    ]);
  }

  bool _validateAll() {
    log(formKey.currentState.toString());
    if (formKey.currentState!.validate()) {
      return true;
    }
    return false;
  }

  _sendForm(CashRegisterModel model) async {
    model.setIsAwaitingSendFormResponse(tab, true);

    // send data to macro
    String chequeOrTransferNumber = '';

    if (model.selectedPaymentMethod(tab) != PaymentMethod.card) {
      chequeOrTransferNumber = model.chequeOrTransferNumber(tab);
    }

    await orderDao.createOrder(
        model.selectedMember(tab)?.email ?? '',
        model.cart(tab),
        model.selectedPaymentMethod(tab),
        chequeOrTransferNumber);
    // reset form
    formKey.currentState?.reset();

    model.cleanCart(tab);
    model.setIsAwaitingSendFormResponse(tab, false);
  }
}
