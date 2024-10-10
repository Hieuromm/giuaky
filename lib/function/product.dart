import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String imageUrl;

  Product({required this.id, required this.name, required this.category, required this.price, required this.imageUrl});

  factory Product.fromDocument(DocumentSnapshot doc) {
    return Product(
      id: doc.id,
      name: doc['name'],
      category: doc['category'],
      price: doc['price'],
      imageUrl: doc['imageUrl'],
    );
  }
}
