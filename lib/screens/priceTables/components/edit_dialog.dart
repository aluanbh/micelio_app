import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditDialog extends StatefulWidget {
  final Function() onEdit;
  final String documentId;
  final Map<String, dynamic> values;

  EditDialog({
    required this.onEdit,
    required this.documentId,
    required this.values,
  });

  @override
  State<EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _priceTables =
      FirebaseFirestore.instance.collection('priceTables');

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isActive = true;
  List<Map<String, dynamic>> _productList = [];
  List<Map<String, dynamic>> _filteredProductList = [];
  String _searchQuery = '';

  // Map para armazenar controladores de texto para cada produto
  final Map<String, TextEditingController> _productControllers = {};
  // Map para armazenar preços atualizados
  final Map<String, String> _updatedPrices = {};

  @override
  void initState() {
    super.initState();
    _isActive = widget.values['status'] ?? false;
    _nameController.text = widget.values['name'] ?? '';
    _productList =
        List<Map<String, dynamic>>.from(widget.values['products'] ?? []);
    _filteredProductList = _productList;

    // Inicializar controladores para cada produto
    for (var product in _productList) {
      final productId = product['uid'] as String;
      final price = product['price']?.toString() ?? '';
      _productControllers[productId] = TextEditingController(text: price);
    }
  }

  @override
  void dispose() {
    // Liberar controladores ao destruir o widget
    _nameController.dispose();
    _searchController.dispose();
    _productControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _filterProducts() {
    setState(() {
      _filteredProductList = _productList.where((product) {
        final name = product['name'] as String;
        return name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    });
  }

  Future<void> _saveChanges() async {
    //primeiro verifica se o nome da nova tabela já existe, ignorando a tabela atual
    final name = _nameController.text;
    final snapshot = await _priceTables
        .where('name', isEqualTo: name)
        .where(FieldPath.documentId, isNotEqualTo: widget.documentId)
        .get();

    if (snapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Já existe uma tabela com esse nome.')),
      );
      return;
    } else {
      try {
        // Atualize o preço dos produtos no Firestore
        final doc = await _priceTables.doc(widget.documentId).get();
        final products = List<Map<String, dynamic>>.from(
            (doc.data() as Map<String, dynamic>)['products'] ?? []);

        for (var product in products) {
          final productId = product['uid'] as String;
          if (_productControllers.containsKey(productId)) {
            final newPrice = _productControllers[productId]?.text ?? '';
            product['price'] = double.tryParse(newPrice) ?? product['price'];
          }
        }

        await _priceTables.doc(widget.documentId).update({
          'name': _nameController.text,
          'status': _isActive,
          'products': products,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tabela de Preços atualizada com sucesso')),
        );

        Navigator.pop(context); // Fechar o diálogo ou navegação
      } catch (e) {
        print('Erro ao atualizar o preço do produto: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar a tabela de preços')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar produto'),
      content: Container(
        width: 550, // Ajuste a largura conforme necessário
        child: SingleChildScrollView(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Ativo'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                decoration:
                    const InputDecoration(labelText: 'Pesquisar produtos'),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _filterProducts();
                  });
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200, // Ajuste a altura conforme necessário
                child: ListView(
                  children: _filteredProductList.map((product) {
                    final name = product['name'] as String;
                    final productId = product['uid'] as String;

                    return ListTile(
                      title: Text(name),
                      subtitle: Text(
                          'Preço: ${_productControllers[productId]?.text ?? ''}'),
                      trailing: SizedBox(
                        width: 100,
                        child: TextFormField(
                          controller: _productControllers[productId],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Preço',
                            border: OutlineInputBorder(),
                          ),
                          onFieldSubmitted: (newValue) {
                            _updateProductPrice(productId, newValue);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () async {
            await _saveChanges();
            widget.onEdit();
          },
          child: const Text('Editar'),
        ),
      ],
    );
  }

  void _updateProductPrice(String productId, String newPrice) {
    setState(() {
      _updatedPrices[productId] = newPrice;
    });
  }
}
