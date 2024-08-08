import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:micelio_app/components/multi_select.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final CollectionReference _priceTables =
      FirebaseFirestore.instance.collection('priceTables');

  final TextEditingController _nameController = TextEditingController();

  bool _isActive = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar nova tabela de preço'),
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
            final result = await _addPriceTable(context);
            widget.onAddResult(result);
            widget.onAdd();
            Navigator.pop(context);
          },
          child: const Text('Adicionar'),
        ),
      ],
    );
  }

  Future<String?> _addPriceTable(BuildContext context) async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      return 'O nome é obrigatório';
    }

    try {
      final data = {
        'userUid': FirebaseAuth.instance.currentUser!.uid,
        'name': name,
        'createdAt': Timestamp.now(),
        'status': _isActive,
        'products': widget.products.map((product) {
          return {
            'uid': product.id,
            'name': (product.data() as Map<String, dynamic>)['name'],
            'price': null,
          };
        }).toList(),
      };

      await _priceTables.add(data);

      _nameController.clear();

      return null;
    } catch (e) {
      print('Erro ao criar a tabela de preços: $e');
      return 'Erro ao criar a tabela de preços: $e';
    }
  }
}
