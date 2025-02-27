import 'package:proyekkos/core/constants/api_constants.dart';
import 'package:proyekkos/data/models/cart_item.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get totalHarga => _items.fold(0, (sum, item) => sum + item.totalHarga);

  void addItem(CartItem item) {
    final existingItemIndex = _items.indexWhere((i) => i.idMakanan == item.idMakanan);
    if (existingItemIndex != -1) {
      _items[existingItemIndex].jumlah++;
    } else {
      _items.add(item);
    }
  }

  void updateItemQuantity(int idMakanan, int jumlah) {
    final index = _items.indexWhere((item) => item.idMakanan == idMakanan);
    if (index != -1) {
      if (jumlah > 0) {
        _items[index].jumlah = jumlah;
      } else {
        _items.removeAt(index);
      }
    }
  }

  void clearCart() {
    _items.clear();
  }

String getFullImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  // Make sure to use the complete URL including the base URL
  return '${ApiConstants.baseUrlStorage}${path}';
}
} 