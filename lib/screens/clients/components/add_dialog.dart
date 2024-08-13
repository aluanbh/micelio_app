import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddDialog extends StatefulWidget {
  final Function(String?) onAddResult;
  final Function() onAdd;

  AddDialog({required this.onAdd, required this.onAddResult});

  @override
  State<AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<AddDialog> {
  final CollectionReference _clients =
      FirebaseFirestore.instance.collection('clients');

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _cnpjController = TextEditingController();

  final TextEditingController _stateRegistrationController =
      TextEditingController();

  final TextEditingController _cpfController = TextEditingController();

  final TextEditingController _rgController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _cepController = TextEditingController();

  final TextEditingController _streetController = TextEditingController();

  final TextEditingController _numberController = TextEditingController();

  final TextEditingController _complementController = TextEditingController();

  final TextEditingController _neighborhoodController = TextEditingController();

  final TextEditingController _cityController = TextEditingController();

  final TextEditingController _stateController = TextEditingController();

  final TextEditingController _responsibleController = TextEditingController();

  final TextEditingController _municipalRegistrationController =
      TextEditingController();

  bool _isPj = false;

  bool _isAdmin = false;

  final MaskTextInputFormatter _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final MaskTextInputFormatter _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final MaskTextInputFormatter _cnpjFormatter = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final MaskTextInputFormatter _cepFormatter = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar novo cliente'),
      content: Container(
        width: 650, // Ajuste a largura conforme necessário
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Pessoa Jurídica ?'),
              value: _isPj,
              onChanged: (value) {
                setState(() {
                  _isPj = value;
                });
              },
            ),
            const Row(
              children: [
                Text(
                  'Dados:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: _isPj ? 'Razão Social' : 'Nome',
              ),
            ),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _isPj ? _cnpjController : _cpfController,
                    decoration: InputDecoration(
                      labelText: _isPj ? 'CNPJ' : 'CPF',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      _isPj ? _cnpjFormatter : _cpfFormatter,
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller:
                        _isPj ? _stateRegistrationController : _rgController,
                    decoration: InputDecoration(
                      labelText: _isPj ? 'Inscrição Estadual' : 'RG',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            if (_isPj)
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _responsibleController,
                      decoration:
                          const InputDecoration(labelText: 'Responsável'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _municipalRegistrationController,
                      decoration: const InputDecoration(
                          labelText: 'Inscrição Municipal'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Telefone'),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_phoneFormatter],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 32,
            ),
            const Row(
              children: [
                Text(
                  'Endereço:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _cepController,
                    decoration: const InputDecoration(labelText: 'CEP'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [_cepFormatter],
                    onChanged: (cep) {
                      if (cep.length == 9) {
                        _buscarCep();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _streetController,
                    decoration: const InputDecoration(labelText: 'Rua'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _numberController,
                    decoration: const InputDecoration(labelText: 'Número'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _complementController,
                    decoration: const InputDecoration(labelText: 'Complemento'),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _neighborhoodController,
                    decoration: const InputDecoration(labelText: 'Bairro'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'Cidade'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _stateController,
                    decoration: const InputDecoration(labelText: 'Estado'),
                  ),
                ),
              ],
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

  bool _isLoadingCep = false;

  Future<void> _buscarCep() async {
    setState(() {
      _isLoadingCep = true;
    });

    try {
      if (!_isValidCep(_cepController.text.replaceAll(RegExp(r'[^\d]'), ''))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("CEP inválido. Por favor, insira um CEP válido."),
          ),
        );
        return;
      }

      String url = 'https://viacep.com.br/ws/${_cepController.text}/json/';
      final uri = Uri.parse(url);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('data: $data');
        if (data['logradouro'] != null) {
          _streetController.text = data['logradouro'];
        }
        if (data['bairro'] != null) {
          _neighborhoodController.text = data['bairro'];
        }
        if (data['localidade'] != null) {
          _cityController.text = data['localidade'];
        }
        if (data['uf'] != null) {
          _stateController.text = data['uf'];
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao buscar CEP. Por favor, tente novamente."),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao buscar CEP. Por favor, tente novamente."),
        ),
      );
    } finally {
      setState(() {
        _isLoadingCep = false;
      });
    }
  }

  bool _isValidCep(String cep) {
    return RegExp(r'\d{8}').hasMatch(cep);
  }

  String _formatCnpj(String cnpj) {
    if (cnpj.isEmpty) {
      return '';
    }
    return cnpj.replaceAllMapped(
        RegExp(r'^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$'),
        (match) =>
            '${match[1]}.${match[2]}.${match[3]}/${match[4]}-${match[5]}');
  }

  String _formatCep(String cep) {
    if (cep.isEmpty) {
      return '';
    }
    return cep.replaceAllMapped(
        RegExp(r'^(\d{5})(\d{3})$'), (match) => '${match[1]}-${match[2]}');
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
    //se for pessoa jurídica, cnpj, name, email sao obrigatórios
    if (_isPj) {
      if (_cnpjController.text.isEmpty) {
        return 'CNPJ é obrigatório';
      }
      if (_nameController.text.isEmpty) {
        return 'Razão Social é obrigatória';
      }
      if (_emailController.text.isEmpty) {
        return 'Email é obrigatório';
      }
    } else {
      if (_cpfController.text.isEmpty) {
        return 'CPF é obrigatório';
      }
      if (_nameController.text.isEmpty) {
        return 'Nome é obrigatório';
      }
      if (_emailController.text.isEmpty) {
        return 'Email é obrigatório';
      }
    }

    try {
      final emailSnapshot =
          await _clients.where('email', isEqualTo: _emailController.text).get();
      if (emailSnapshot.docs.isNotEmpty) {
        return 'Já existe um usuário com este email';
      }

      final cpfSnapshot =
          await _clients.where('cpf', isEqualTo: _cpfController.text).get();
      if (cpfSnapshot.docs.isNotEmpty) {
        return 'Já existe um usuário com este CPF';
      }

      await _clients.add({
        'owner': FirebaseAuth.instance.currentUser!.uid,
        'name': _nameController.text.isEmpty ? null : _nameController.text,
        'cpf': _cpfController.text.replaceAll(RegExp(r'[^\d]'), '').isEmpty
            ? null
            : _cpfController.text.replaceAll(RegExp(r'[^\d]'), ''),
        'phone': _phoneController.text.replaceAll(RegExp(r'[^\d]'), '').isEmpty
            ? null
            : _phoneController.text.replaceAll(RegExp(r'[^\d]'), ''),
        'email': _emailController.text.isEmpty ? null : _emailController.text,
        'cep': _cepController.text.replaceAll(RegExp(r'[^\d]'), '').isEmpty
            ? null
            : _cepController.text.replaceAll(RegExp(r'[^\d]'), ''),
        'street':
            _streetController.text.isEmpty ? null : _streetController.text,
        'number':
            _numberController.text.isEmpty ? null : _numberController.text,
        'complement': _complementController.text.isEmpty
            ? null
            : _complementController.text,
        'neighborhood': _neighborhoodController.text.isEmpty
            ? null
            : _neighborhoodController.text,
        'city': _cityController.text.isEmpty ? null : _cityController.text,
        'state': _stateController.text.isEmpty ? null : _stateController.text,
        'cnpj': _cnpjController.text.replaceAll(RegExp(r'[^\d]'), '').isEmpty
            ? null
            : _cnpjController.text.replaceAll(RegExp(r'[^\d]'), ''),
        'stateRegistration': _stateRegistrationController.text.isEmpty
            ? null
            : _stateRegistrationController.text,
        'rg': _rgController.text.isEmpty ? null : _rgController.text,
        'responsible': _responsibleController.text.isEmpty
            ? null
            : _responsibleController.text,
        'municipalRegistration': _municipalRegistrationController.text.isEmpty
            ? null
            : _municipalRegistrationController.text,
        'isPj': _isPj,
      });

      return null; // Indica sucesso, sem mensagem de erro
    } catch (e) {
      print('Erro ao criar o usuário: $e');
      return 'Erro ao criar o usuário: $e'; // Retorna a mensagem de erro
    }
  }
}
