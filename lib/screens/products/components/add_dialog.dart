import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:micelio_app/components/multi_select.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class AddDialog extends StatefulWidget {
  final Function(String?) onAddResult;
  final Function() onAdd;
  final List<DocumentSnapshot> products;

  AddDialog({
    required this.onAdd,
    required this.onAddResult,
    required this.products,
  });

  @override
  State<AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<AddDialog> {
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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar novo produto'),
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
            final result = await _addProduct(context);
            widget.onAddResult(result);
            widget.onAdd();
            Navigator.pop(context);
          },
          child: const Text('Adicionar'),
        ),
      ],
    );
  }

  Future<String?> _addProduct(BuildContext context) async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      return 'O nome é obrigatório';
    }

    try {
      final data = {
        'name': name,
        'costPrice': _costPriceController.text.isNotEmpty
            ? double.parse(_costPriceController.text
                    .replaceAll(RegExp(r'[^\d]'), '')) /
                100
            : null,
        'grossWeight': _grossWeightController.text.isNotEmpty
            ? double.parse(_grossWeightController.text)
            : null,
        'netWeight': _netWeightController.text.isNotEmpty
            ? double.parse(_netWeightController.text)
            : null,
        'isComposite': _isComposite,
        'status': _isActive,
        if (_isComposite) 'components': _selectedProducts,
      };

      await _products.add(data);

      _nameController.clear();
      _costPriceController.clear();
      _grossWeightController.clear();
      _netWeightController.clear();

      return null; // Indica sucesso, sem mensagem de erro
    } catch (e) {
      print('Erro ao criar o produto: $e');
      return 'Erro ao criar o produto: $e'; // Retorna a mensagem de erro
    }
  }
}
