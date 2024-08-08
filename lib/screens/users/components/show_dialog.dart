import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class ShowDialog extends StatefulWidget {
  final Function(String?) onEditResult;
  final Function() onEdit;
  final String documentId;
  final Map<String, dynamic> values;

  ShowDialog(
      {required this.onEdit,
      required this.documentId,
      required this.values,
      required this.onEditResult});

  @override
  State<ShowDialog> createState() => _ShowDialogState();
}

class _ShowDialogState extends State<ShowDialog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final CollectionReference _users =
      FirebaseFirestore.instance.collection('users');

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _cpfController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _isAdmin = false;

  final MaskTextInputFormatter _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final MaskTextInputFormatter _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _isAdmin = widget.values['isAdmin'] ?? false;
    _nameController.text = widget.values['name'];
    _cpfController.text = widget.values['cpf'] ?? '';
    _phoneController.text = widget.values['phone'] ?? '';
    _emailController.text = widget.values['email'];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detalhar usuário'),
      content: Container(
        width: 550, // Ajuste a largura conforme necessário
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Admin'),
              value: _isAdmin,
              onChanged: (value) {},
            ),
            TextField(
              enabled: false,
              style: TextStyle(color: Colors.black),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              enabled: false,
              style: TextStyle(color: Colors.black),
              controller: _cpfController,
              decoration: const InputDecoration(labelText: 'CPF'),
              keyboardType: TextInputType.number,
              inputFormatters: [_cpfFormatter],
            ),
            TextField(
              enabled: false,
              style: TextStyle(color: Colors.black),
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Telefone'),
              keyboardType: TextInputType.phone,
              inputFormatters: [_phoneFormatter],
            ),
            TextField(
              enabled: false,
              style: TextStyle(color: Colors.black),
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
