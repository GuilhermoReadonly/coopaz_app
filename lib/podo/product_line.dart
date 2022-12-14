class ProductLine {
  ProductLine({
    this.name,
    this.qty,
    this.unitPrice,
  });

  String? name;
  double? qty;
  double? unitPrice;

  @override
  String toString() {
    return '{name: $name, family: $qty, supplier: $unitPrice,}';
  }
}
