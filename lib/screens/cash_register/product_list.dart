import 'package:coopaz_app/podo/product.dart';
import 'package:coopaz_app/podo/cart_item.dart';
import 'package:coopaz_app/state/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:coopaz_app/logger.dart';
import 'package:provider/provider.dart';

class ProductList extends StatefulWidget {
  const ProductList({super.key, required this.formKey, required this.model});

  final GlobalKey<FormState> formKey;
  final AppModel model;

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  static NumberFormat numberFormat = NumberFormat('#,##0.00');

  @override
  Widget build(BuildContext context) {
    log('build productList');

    var styleHeaders = Theme.of(context)
        .primaryTextTheme
        .titleLarge
        ?.apply(color: Theme.of(context).primaryColor);

    return Consumer<AppModel>(builder: (context, model, child) {
      List<Row> productLineWidgets = _createProductLineWidgets(model);

      return Column(
        children: [
          Row(children: <Widget>[
            Expanded(
                flex: 8,
                child: Text(
                  'Produit',
                  style: styleHeaders,
                )),
            Expanded(
                flex: 2,
                child: Text(
                  'Quantité',
                  style: styleHeaders,
                )),
            Expanded(
                flex: 2,
                child: Text(
                  'Prix unitaire',
                  style: styleHeaders,
                )),
            Expanded(
                flex: 2,
                child: Text(
                  'Unité',
                  style: styleHeaders,
                )),
            Expanded(
                flex: 2,
                child: Text(
                  'Total',
                  style: styleHeaders,
                )),
            Expanded(flex: 1, child: Container()),
          ]),
          Column(children: productLineWidgets),
          Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  log('+ pressed');
                  _validateAll();
                  model.addToCart(CartItem());
                },
                child: const Icon(Icons.add),
              ))
        ],
      );
    });
  }

  bool _validateAll() {
    log(widget.formKey.currentState.toString());
    bool valid = false;
    if (widget.formKey.currentState != null) {
      valid = widget.formKey.currentState!.validate();
    }
    return valid;
  }

  List<Row> _createProductLineWidgets(AppModel model) {
    List<Row> products = [];
    for (var entry in model.cart.asMap().entries) {
      var product = _createProductLineWidget(entry.key, entry.value, model);
      products.add(product);
    }
    return products;
  }

  Row _createProductLineWidget(int index, CartItem cartItem, AppModel model) {
    var total = '';
    double? unitPrice = double.tryParse(cartItem.unitPrice ?? '');
    double? qty = double.tryParse(cartItem.qty ?? '');
    if (unitPrice != null && qty != null) {
      total = '${numberFormat.format(unitPrice * qty)} €';
    }

    var productWidget = Row(children: <Widget>[
      Expanded(
          flex: 8,
          child: Autocomplete<Product>(
            initialValue: TextEditingValue(text: cartItem.name ?? ''),
            key: ValueKey(cartItem),
            displayStringForOption: (Product p) => p.designation,
            optionsBuilder: (TextEditingValue textEditingValue) async {
              if (textEditingValue.text == '') {
                return const Iterable<Product>.empty();
              }
              return model.products.where((Product p) {
                return p
                    .toString()
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (p) {
              model.modifyCartItem(
                  index,
                  CartItem(
                      name: p.designation,
                      unit: p.unit.unitAsString,
                      unitPrice: p.price.toStringAsFixed(2)));
            },
          )),
      Expanded(
          flex: 2,
          child: TextFormField(
            controller: TextEditingController(text: cartItem.qty ?? '')
              ..selection =
                  TextSelection.collapsed(offset: (cartItem.qty ?? '').length),
            decoration: const InputDecoration(
              hintText: 'Quantité',
            ),
            validator: (String? value) {
              if (value == null ||
                  value.isEmpty ||
                  double.tryParse(value) == null) {
                return 'Quantité invalide';
              }
              return null;
            },
            onChanged: (String value) {
              cartItem.qty = value;
              model.modifyCartItem(index, cartItem);
            },
          )),
      Expanded(flex: 2, child: Text(cartItem.unitPrice ?? '')),
      Expanded(flex: 2, child: Text(cartItem.unit ?? '')),
      Expanded(flex: 2, child: Text(total)),
      Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () {
              log('Delete line pressed');
              model.removeFromCart(index);
              _validateAll();
            },
            child: const Icon(Icons.delete),
          ))
    ]);

    return productWidget;
  }
}
