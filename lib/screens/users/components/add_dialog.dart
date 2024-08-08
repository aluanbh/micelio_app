import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class AddDialog extends StatefulWidget {
  final Function(String?) onAddResult;
  final Function() onAdd;

  AddDialog({required this.onAdd, required this.onAddResult});

  @override
  State<AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<AddDialog> {
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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar novo usuário'),
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
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true,
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
            if (_isValidPhoneNumber(_phoneController.text)) {
              final result = await _addUser(context);
              widget.onAddResult(result);
              widget.onAdd();
              Navigator.pop(context);
            } else {
              // Exiba uma mensagem de erro, por exemplo:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Número de telefone inválido. Por favor, insira um número válido.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Adicionar'),
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

  Future<String?> _addUser(BuildContext context) async {
    try {
      final emailSnapshot =
          await _users.where('email', isEqualTo: _emailController.text).get();
      if (emailSnapshot.docs.isNotEmpty) {
        return 'Já existe um usuário com este email';
      }

      final cpfSnapshot =
          await _users.where('cpf', isEqualTo: _cpfController.text).get();
      if (cpfSnapshot.docs.isNotEmpty) {
        return 'Já existe um usuário com este CPF';
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: _emailController.text, password: _passwordController.text);

      print('Usuário criado com sucesso: ${userCredential.user}');

      if (userCredential.user == null) {
        return 'Erro ao criar o usuário'; // Retorna a mensagem de erro
      }

      // Use o UID do usuário recém-criado
      final uid = userCredential.user!.uid;

      await _users.doc(uid).set({
        'uid': userCredential.user!.uid,
        'name': _nameController.text,
        'cpf': _cpfController.text,
        'phone': _phoneController.text.isEmpty
            ? null
            : '+55' + _phoneController.text.replaceAll(RegExp(r'[^\d]'), ''),
        'email': _emailController.text,
        'isAdmin': _isAdmin,
        'status': 'active',
      });

      _nameController.clear();
      _cpfController.clear();
      _phoneController.clear();
      _emailController.clear();
      _passwordController.clear();

      return null; // Indica sucesso, sem mensagem de erro
    } catch (e) {
      print('Erro ao criar o usuário: $e');
      return 'Erro ao criar o usuário: $e'; // Retorna a mensagem de erro
    }
  }
}
