import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class EditDialog extends StatefulWidget {
  final Function(String?) onEditResult;
  final Function() onEdit;
  final String documentId;
  final Map<String, dynamic> values;

  EditDialog(
      {required this.onEdit,
      required this.documentId,
      required this.values,
      required this.onEditResult});

  @override
  State<EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final CollectionReference _users =
      FirebaseFirestore.instance.collection('users');

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _cpfController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

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
    _cpfController.text = _formatCpf(widget.values['cpf'] ?? '');
    _phoneController.text = _formatPhoneNumber(widget.values['phone'] ?? '');
    _emailController.text = widget.values['email'];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar usuário'),
      content: Container(
        width: 550, // Ajuste a largura conforme necessário
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Admin'),
              value: _isAdmin,
              onChanged: (value) {
                setState(() {
                  _isAdmin = value;
                });
              },
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: _cpfController,
              decoration: const InputDecoration(labelText: 'CPF'),
              keyboardType: TextInputType.number,
              inputFormatters: [_cpfFormatter],
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Telefone'),
              keyboardType: TextInputType.phone,
              inputFormatters: [_phoneFormatter],
            ),
            TextField(
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
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () async {
            if (_isValidPhoneNumber(_phoneController.text) &&
                _isValidCpf(_cpfController.text)) {
              final result = await _editUser(context);
              widget.onEditResult(result);
              widget.onEdit();
              Navigator.pop(context);
            } else if (!_isValidPhoneNumber(_phoneController.text)) {
              // Exiba uma mensagem de erro, por exemplo:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Número de telefone inválido. Por favor, insira um número válido.'),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (!_isValidCpf(_cpfController.text)) {
              // Exiba uma mensagem de erro, por exemplo:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('CPF inválido. Por favor, insira um CPF válido.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Editar'),
        ),
      ],
    );
  }

  String _formatCpf(String cpf) {
    if (cpf.isEmpty) {
      return '';
    }
    return cpf.replaceAllMapped(RegExp(r'^(\d{3})(\d{3})(\d{3})(\d{2})$'),
        (match) => '${match[1]}.${match[2]}.${match[3]}-${match[4]}');
  }

  String _formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      return '';
    }
    return phoneNumber.replaceFirst('+55', '').replaceAllMapped(
        RegExp(r'^(\d{2})(\d{5})(\d{4})$'),
        (match) => '(${match[1]}) ${match[2]}-${match[3]}');
  }

  bool _isValidPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      // Número de telefone é opcional, então é válido se estiver vazio
      return true;
    }
    // Remova a máscara e adicione +55 antes do número
    final cleanedPhone = '+55' + phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    // Verifique se o número de telefone tem pelo menos 10 dígitos
    return cleanedPhone.length >= 10;
  }

  bool _isValidCpf(String cpf) {
    if (cpf.isEmpty) {
      // CPF é opcional, então é válido se estiver vazio
      return true;
    }
    // Remova a máscara do CPF "." "-" e verifique se tem 11 dígitos
    final cleanedCpf = cpf.replaceAll(RegExp(r'[^\d]'), '');
    // Verifique se o CPF tem 11 dígitos
    return cleanedCpf.length == 11;
  }

  Future<String?> _editUser(BuildContext context) async {
    try {
      //verificar se um outro usuário já possui o mesmo email
      final emailSnapshot = await _users
          .where('email', isEqualTo: _emailController.text)
          .where(FieldPath.documentId, isNotEqualTo: widget.documentId)
          .get();
      if (emailSnapshot.docs.isNotEmpty) {
        return 'Já existe um usuário com este email';
      }

      //verificar se um outro usuário já possui o mesmo cpf
      final cpfSnapshot = await _users
          .where('cpf', isEqualTo: _cpfController.text)
          .where(FieldPath.documentId, isNotEqualTo: widget.documentId)
          .get();
      if (cpfSnapshot.docs.isNotEmpty) {
        return 'Já existe um usuário com este CPF';
      }
      await _users.doc(widget.documentId).update({
        'name': _nameController.text,
        'cpf': _cpfController.text,
        'phone': _phoneController.text.isEmpty
            ? null
            : '+55' + _phoneController.text.replaceAll(RegExp(r'[^\d]'), ''),
        'email': _emailController.text,
        'isAdmin': _isAdmin,
      });

      _nameController.clear();
      _cpfController.clear();
      _phoneController.clear();
      _emailController.clear();
      return null; // Indica sucesso, sem mensagem de erro
    } catch (e) {
      print('Erro ao editar o usuário: $e');
      return 'Erro ao editar o usuário: $e'; // Retorna a mensagem de erro
    }
  }
}
