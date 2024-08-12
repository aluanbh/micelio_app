import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/services.dart';

class StockPage extends StatefulWidget {
  const StockPage({Key? key}) : super(key: key);

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  late final CollectionReference _products;
  late final CollectionReference _stock;

  bool _loading = true;
  String _searchQuery = '';
  List<DocumentSnapshot> _productsList = [];
  List<DocumentSnapshot> _stockList = [];
  List<DocumentSnapshot> _filteredProductsList = [];

  _StockPageState()
      : _products = FirebaseFirestore.instance.collection('products'),
        _stock = FirebaseFirestore.instance.collection('stock');

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _loading = true);

    try {
      final snapshotProducts = await _products.orderBy('name').get();
      final snapshotStock = await _stock.get();
      setState(() {
        _productsList = snapshotProducts.docs;
        _stockList = snapshotStock.docs;
        _filterProducts(); // Apply filter to the fetched products
        _checkstartStock(); // Verifica se todos os produtos estão cadastrados no stock
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
        title: Row(
          children: [
            const Text('Estoque'),
            const SizedBox(width: 10),
            Text(
              '(${_filteredProductsList.length})',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
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
                  label: Center(child: Text('Status')),
                  size: ColumnSize.S,
                ),
                DataColumn2(
                  label: Center(child: Text('Quantidade')),
                  size: ColumnSize.S,
                ),
                DataColumn2(
                  label: Center(child: Text('Ações')),
                  size: ColumnSize.S,
                ),
              ],
              rows: List.generate(_filteredProductsList.length, (index) {
                final product = _filteredProductsList[index];

                final stock =
                    _stockList?.firstWhere((stock) => stock.id == product.id);

                final stockQuantity =
                    stock != null ? (stock['quantity'] as int) : 0;
                final TextEditingController _controller =
                    TextEditingController(text: stockQuantity.toString());

                return DataRow(
                  cells: [
                    DataCell(Text(product['name'])),
                    DataCell(Center(
                        child: Text(product['status'] ? 'Ativo' : 'Inativo'))),
                    DataCell(
                      Center(
                        child: TextField(
                          //alinhar o texto ao centro
                          textAlign: TextAlign.center,
                          controller: _controller,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],

                          onSubmitted: (value) {
                            final newQuantity = int.tryParse(value) ?? 0;
                            if (newQuantity < 0) {
                              _showAlert(
                                  context, "Quantidade não pode ser negativa.");
                              _controller.text = stockQuantity.toString();
                            } else {
                              _updateStock(
                                  product.id, newQuantity, _controller);
                            }
                          },
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              _removeStock(product.id, _controller);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              _addStock(product.id, _controller);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
    );
  }

  void _checkstartStock() {
    for (final product in _filteredProductsList) {
      final productUid = product.id;

      // Verifica se o produto já existe no stock
      if (!_stockList.any((stock) => stock.id == productUid)) {
        // Adiciona o produto ao stock com o mesmo UID
        _stock.doc(productUid).set({
          'quantity': 0,
        });
      }
    }

    // Remove documentos de stock que não têm um produto correspondente
    for (final stock in _stockList) {
      if (!_filteredProductsList.any((product) => product.id == stock.id)) {
        _stock.doc(stock.id).delete();
      }
    }
  }

// Função para adicionar estoque ao produto selecionado na coleção stock
  void _addStock(String productUid, TextEditingController controller) async {
    // Incrementa a quantidade no documento do stock
    await _stock.doc(productUid).update({
      'quantity': FieldValue.increment(1),
    });

    // Obtém a nova quantidade do Firestore
    final updatedDoc = await _stock.doc(productUid).get();
    final updatedQuantity = updatedDoc['quantity'] as int;

    // Atualiza o valor do controlador
    controller.text = updatedQuantity.toString();
  }

  void _removeStock(String productUid, TextEditingController controller) async {
    //verifica se a quantidade é maior que 0 caso contrário não decrementa e exibe um alerta
    if (int.parse(controller.text) == 0) {
      _showAlert(context, "Quantidade não pode ser negativa.");
      return;
    }
    // Decrementa a quantidade no documento do stock
    await _stock.doc(productUid).update({
      'quantity': FieldValue.increment(-1),
    });

    // Obtém a nova quantidade do Firestore
    final updatedDoc = await _stock.doc(productUid).get();
    final updatedQuantity = updatedDoc['quantity'] as int;

    // Atualiza o valor do controlador
    controller.text = updatedQuantity.toString();
  }

  void _updateStock(String productUid, int newQuantity,
      TextEditingController controller) async {
    // Atualiza a quantidade no documento do stock
    await _stock.doc(productUid).update({
      'quantity': newQuantity,
    });

    // Atualiza o valor do controlador
    controller.text = newQuantity.toString();
  }

  void _showAlert(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ação inválida"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
