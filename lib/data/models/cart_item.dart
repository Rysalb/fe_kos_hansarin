class CartItem {
  final int idMakanan;
  final String namaMakanan;
  final String fotoMakanan;
  final int harga;
  int jumlah;

  CartItem({
    required this.idMakanan,
    required this.namaMakanan,
    required this.fotoMakanan,
    required this.harga,
    this.jumlah = 1,
  });

  int get totalHarga => harga * jumlah;
} 