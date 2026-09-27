/// US sizing options per store product category. Boxing gloves and other
/// padded gear are sized by weight in ounces rather than letter/number
/// sizes, so equipment gets its own list.
abstract final class ProductSizes {
  static const categories = {
    'clothing': 'Clothing',
    'shoes': 'Shoes',
    'equipment': 'Boxing Equipment',
  };
  static const clothing = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  static const shoes = [
    '5', '5.5', '6', '6.5', '7', '7.5', '8', '8.5',
    '9', '9.5', '10', '10.5', '11', '11.5', '12', '13',
  ];
  static const equipment = ['8oz', '10oz', '12oz', '14oz', '16oz'];

  static List<String> forCategory(String category) => switch (category) {
    'clothing' => clothing,
    'shoes' => shoes,
    'equipment' => equipment,
    _ => const [],
  };
}
