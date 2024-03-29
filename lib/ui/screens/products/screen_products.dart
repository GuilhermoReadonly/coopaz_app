import 'package:coopaz_app/dao/data_access.dart';
import 'package:coopaz_app/logger.dart';
import 'package:coopaz_app/podo/product.dart';
import 'package:coopaz_app/ui/common_widgets/loading_widget.dart';
import 'package:coopaz_app/state/app_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'widget_product_list.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key, required this.productDao});

  final GoogleSheetDao<Product> productDao;

  final String title = 'Produits';

  @override
  Widget build(BuildContext context) {
    log('Build screen $title');

    return Consumer<AppModel>(builder: (context, model, child) {
      Widget w;
      if (model.products.isNotEmpty) {
        w = ProductList();
      } else {
        productDao.get().then((p) => model.products = p);
        w = const Loading(text: 'Chargement de la liste des produits...');
      }
      return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                  onPressed: () async {
                    model.products = [];
                  },
                  icon: const Icon(Icons.refresh))
            ],
            title: Text(title),
          ),
          body: Container(padding: const EdgeInsets.all(12.0), child: w));
    });
  }
}
