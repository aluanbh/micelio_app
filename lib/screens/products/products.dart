import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:micelio_app/screens/products/components/add_dialog.dart';
import 'package:micelio_app/screens/products/components/edit_dialog.dart';
import 'package:micelio_app/screens/products/components/show_dialog.dart';

enum UserFilter { onlyActive, deleted, all }

class ProductPage extends StatefulWidget {
  const ProductPage({Key? key}) : super(key: key);

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _products;

  bool _isAdmin = false;
  bool _loading = true;
  String _searchQuery = '';
  List<DocumentSnapshot> _productsList = [];
  List<DocumentSnapshot> _filteredProductsList = [];

  _ProductPageState()
      : _products = FirebaseFirestore.instance.collection('products');

  @override
  void initState() {
    super.initState();
    _checkIfUserIsAdmin();
    _fetchProducts();
  }

  Future<void> _checkIfUserIsAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _isAdmin = userDoc.data()?['isAdmin'] ?? false;
      });
    }
  }

  Future<void> _fetchProducts() async {
    setState(() => _loading = true);

    try {
      final snapshot = await _products.orderBy('name').get();
      setState(() {
        _productsList = snapshot.docs;
        _filterProducts(); // Apply filter to the fetched products
        _loading = false;
      });
    } catch (e) {
      print('Erro ao buscar produtos: $e');
      setState(() => _loading = false);
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProductsList = _productsList.where((product) {
        final name = (product.data() as Map<String, dynamic>)['name'] as String;
        return name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        automaticallyImplyLeading: false,
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddDialog,
            ),
          SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 200,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _filterProducts();
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : DataTable2(
              columns: const [
                DataColumn2(
                  label: Text('Nome'),
                  size: ColumnSize.L,
                ),
                DataColumn2(
                  label: Center(child: Text('Item composto')),
                  size: ColumnSize.S,
                ),
                DataColumn2(
                  label: Center(child: Text('Volume')),
                  size: ColumnSize.S,
                ),
                DataColumn2(
                  label: Center(child: Text('Ações')),
                  size: ColumnSize.S,
                ),
              ],
              rows: List.generate(_filteredProductsList.length, (index) {
                final product = _filteredProductsList[index];
                return DataRow(
                  cells: [
                    DataCell(Text(product['name'])),
                    DataCell(
                      Center(
                          child: Text(product['isComposite'] ? 'Sim' : 'Não')),
                    ),
                    DataCell(
                      Center(
                          child: Text(
                        product['netWeight'] >= 1000
                            ? '${product['netWeight'] / 1000}kg'
                            : '${product['netWeight']}g',
                      )),
                    ),
                    DataCell(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _isAdmin
                            ? _adminActions(product.id,
                                product.data() as Map<String, dynamic>)
                            : _userActions(product.id,
                                product.data() as Map<String, dynamic>),
                      ),
                    ),
                  ],
                );
              }),
            ),
    );
  }

  DataRow _buildDataRow(DocumentSnapshot product) {
    final productData = product.data() as Map<String, dynamic>;

    return DataRow(
      cells: [
        DataCell(Text(productData['name'])),
        DataCell(
          Row(
            children: _isAdmin
                ? _adminActions(product.id, productData)
                : _userActions(product.id, productData),
          ),
        ),
      ],
    );
  }

  List<Widget> _adminActions(
      String documentId, Map<String, dynamic> productData) {
    return [
      IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => _showEditDialog(documentId, productData),
      ),
      if (productData['status'] != 'deleted')
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _deleteProduct(documentId),
        ),
    ];
  }

  List<Widget> _userActions(
      String documentId, Map<String, dynamic> productData) {
    return [
      IconButton(
        icon: const Icon(Icons.remove_red_eye),
        onPressed: () => _showUserDetailsDialog(documentId, productData),
      ),
    ];
  }

  void _showAddDialog() async {
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AddDialog(
        onAdd: () => _fetchProducts(),
        onAddResult: (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result ?? 'Usuário adicionado com sucesso')),
          );
        },
        //enviar todos os produtos cadastrados
        products: _productsList,
      ),
    );
  }

  void _showEditDialog(String documentId, Map<String, dynamic> values) async {
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => EditDialog(
        onEdit: () => _fetchProducts(),
        onEditResult: (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result ?? 'Usuário editado com sucesso')),
          );
        },
        documentId: documentId,
        values: values,
        products: _productsList,
      ),
    );
  }

  void _showUserDetailsDialog(
      String documentId, Map<String, dynamic> values) async {
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => ShowDialog(
        onEdit: () => _fetchProducts(),
        onEditResult: (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result ?? 'Usuário visualizado com sucesso')),
          );
        },
        documentId: documentId,
        values: values,
      ),
    );
  }

  void _deleteProduct(String documentId) async {
    try {
      // Verificar se o produto está sendo utilizado em algum item composto antes de deletar
      const String collectionPath = 'products';
      final snapshot = await _firestore
          .collection(collectionPath)
          .where('components', arrayContains: documentId)
          .get();

      print('snapshot: ${snapshot.docs}');
      if (snapshot.docs.isNotEmpty) {
        final productName = snapshot.docs.first.data()['name'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 10),
            content: Text(
              'Este produto está sendo utilizado no item composto: $productName',
            ),
          ),
        );
        print('este produto está sendo utilizado em um item composto');
        return;
      }

      await _firestore.collection('products').doc(documentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto deletado com sucesso')),
      );
      _fetchProducts();
    } catch (e) {
      print('Erro ao deletar produto: $e');
    }
  }
}
