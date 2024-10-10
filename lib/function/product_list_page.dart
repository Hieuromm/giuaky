import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product.dart';
import 'add_product_page.dart';
import 'edit_product_page.dart';

class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchTerm = '';
  String _selectedCategory = 'All'; // Biến để lưu loại sản phẩm được chọn
  List<String> _categories = ['All']; // Danh sách loại sản phẩm

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Gọi hàm để lấy danh sách loại sản phẩm
  }

  Future<void> _fetchCategories() async {
    // Truy vấn từ Firestore để lấy danh sách loại sản phẩm
    final snapshot = await _firestore.collection('products').get();
    Set<String> categoriesSet = {'All'}; // Sử dụng Set để loại bỏ các loại trùng lặp

    for (var doc in snapshot.docs) {
      final product = Product.fromDocument(doc);
      categoriesSet.add(product.category); // Thêm loại sản phẩm vào Set
    }

    setState(() {
      _categories = categoriesSet.toList(); // Chuyển Set về List
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product List'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddProductPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Dropdown để chọn loại sản phẩm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: _selectedCategory,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue!; // Cập nhật loại sản phẩm được chọn
                });
              },
              items: _categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          // TextField để tìm kiếm
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchTerm = value; // Cập nhật từ khóa tìm kiếm
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final products = snapshot.data!.docs;

                // Lọc sản phẩm theo từ khóa tìm kiếm và loại sản phẩm
                final filteredProducts = products.where((doc) {
                  final product = Product.fromDocument(doc);
                  final matchesSearchTerm = product.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
                      product.category.toLowerCase().contains(_searchTerm.toLowerCase());
                  final matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
                  return matchesSearchTerm && matchesCategory;
                }).toList();

                return ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = Product.fromDocument(filteredProducts[index]);
                    return ListTile(
                      leading: product.imageUrl.isNotEmpty
                          ? Image.network(
                        product.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                          : Container(width: 50, height: 50, color: Colors.grey),
                      title: Text(product.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('\$${product.price}'),
                          Text('Category: ${product.category}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _firestore.collection('products').doc(product.id).delete();
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProductPage(product: product),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
