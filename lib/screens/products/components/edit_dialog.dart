import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class EditDialog extends StatefulWidget {
  final Function(String?) onEditResult;
  final Function() onEdit;
  final String documentId;
  final Map<String, dynamic> values;
  final List<DocumentSnapshot> products;

  EditDialog({
    required this.onEdit,
    required this.documentId,
    required this.values,
    required this.onEditResult,
    required this.products,
  });

  @override
  State<EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _products =
      FirebaseFirestore.instance.collection('products');

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController();
  final TextEditingController _grossWeightController = TextEditingController();
  final TextEditingController _netWeightController = TextEditingController();

  final MaskTextInputFormatter _costPriceFormatter = MaskTextInputFormatter(
    mask: 'R\$ ###.##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final MaskTextInputFormatter _grossWeightFormatter = MaskTextInputFormatter(
    mask: '#####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final MaskTextInputFormatter _netWeightFormatter = MaskTextInputFormatter(
    mask: '#####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool _isActive = true;
  bool _isComposite = false;
  List<String> _selectedProducts = [];

  @override
  void initState() {
    super.initState();
    _isActive = widget.values['status'] ?? false;
    _nameController.text = widget.values['name'] ?? '';
    _costPriceController.text = widget.values['costPrice']?.toString() ?? '';
    _grossWeightController.text =
        widget.values['grossWeight']?.toString() ?? '';
    _netWeightController.text = widget.values['netWeight']?.toString() ?? '';
    _isComposite = widget.values['isComposite'] ?? false;
    _selectedProducts = List<String>.from(widget.values['components'] ?? []);
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
              SwitchListTile(
                title: const Text('Composto'),
                value: _isComposite,
                onChanged: (value) {
                  setState(() {
                    _isComposite = value;
                  });
                },
              ),
              if (_isComposite)
                MultiSelectDialogField(
                  searchable: true,
                  searchHint: 'Pesquisar',
                  title: const Text('Procure e marque os Itens do Kit'),
                  items: widget.products
                      .where((product) => product['isComposite'] == false)
                      .map((product) =>
                          MultiSelectItem(product.id, product['name']))
                      .toList(),
                  initialValue: _selectedProducts,
                  buttonText:
                      const Text('Selecione os componentes do item composto'),
                  onConfirm: (values) {
                    setState(() {
                      _selectedProducts = values;
                    });
                  },
                ),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: _costPriceController,
                decoration: const InputDecoration(labelText: 'Preço de custo'),
                keyboardType: TextInputType.number,
                inputFormatters: [_costPriceFormatter],
              ),
              TextField(
                controller: _grossWeightController,
                decoration: const InputDecoration(labelText: 'Peso bruto (g)'),
                keyboardType: TextInputType.number,
                inputFormatters: [_grossWeightFormatter],
              ),
              TextField(
                controller: _netWeightController,
                decoration:
                    const InputDecoration(labelText: 'Peso líquido (ml)'),
                keyboardType: TextInputType.number,
                inputFormatters: [_netWeightFormatter],
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
            final result = await _editProduct();
            widget.onEditResult(result);
            widget.onEdit();
            Navigator.pop(context);
          },
          child: const Text('Editar'),
        ),
      ],
    );
  }

  Future<String?> _editProduct() async {
    try {
      await _products.doc(widget.documentId).update({
        'name': _nameController.text,
        'costPrice': double.parse(
                _costPriceController.text.replaceAll(RegExp(r'[^\d]'), '')) /
            100,
        'grossWeight': double.parse(_grossWeightController.text),
        'netWeight': double.parse(_netWeightController.text),
        'isComposite': _isComposite,
        'status': _isActive,
        if (_isComposite) 'components': _selectedProducts,
      });
      _clearFormFields();
      return null; // Indica sucesso, sem mensagem de erro
    } catch (e) {
      print('Erro ao editar o produto: $e');
      return 'Erro ao editar o produto: $e'; // Retorna a mensagem de erro
    }
  }

  void _clearFormFields() {
    _nameController.clear();
    _costPriceController.clear();
    _grossWeightController.clear();
    _netWeightController.clear();
  }
}
