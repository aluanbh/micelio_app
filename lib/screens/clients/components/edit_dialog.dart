import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  void initState() {
    super.initState();
    //se tiver nome no documento, preencher os campos com os valores do documento
    _nameController.text = widget.values['name'] ?? '';
    _cpfController.text = _formatCpf(widget.values['cpf'] ?? '');
    _phoneController.text = _formatPhoneNumber(widget.values['phone'] ?? '');
    _emailController.text = widget.values['email'] ?? '';
    _cnpjController.text = _formatCnpj(widget.values['cnpj'] ?? '');
    _stateRegistrationController.text =
        widget.values['stateRegistration'] ?? '';
    _rgController.text = widget.values['rg'] ?? '';
    _municipalRegistrationController.text =
        widget.values['municipalRegistration'] ?? '';
    _cepController.text = _formatCep(widget.values['cep'] ?? '');
    _streetController.text = widget.values['street'] ?? '';
    _numberController.text = widget.values['number'] ?? '';
    _complementController.text = widget.values['complement'] ?? '';
    _neighborhoodController.text = widget.values['neighborhood'] ?? '';
    _cityController.text = widget.values['city'] ?? '';
    _stateController.text = widget.values['state'] ?? '';
    _responsibleController.text = widget.values['responsible'] ?? '';
    _isPj = widget.values['isPj'] ?? false;
    _rgController.text = widget.values['rg'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar usuário'),
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
                      if (cep.length == 10) {
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
            //se não preencher name, email, cpf ou cnpj se for pessoa jurídica, exibir mensagem de erro
            if (_nameController.text.isEmpty ||
                (_isPj && _cnpjController.text.isEmpty) ||
                (!_isPj && _cpfController.text.isEmpty)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Por favor, preencha todos os campos obrigatórios.'),
                  backgroundColor: Colors.red,
                ),
              );
            } else {
              final result = await _editUser(context);
              widget.onEditResult(result);
              widget.onEdit();
              Navigator.pop(context);
            }
          },
          child: const Text('Editar'),
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

      print('cep: ${_cepController.text}');
      String url = 'https://viacep.com.br/ws/${_cepController.text}/json/';
      final uri = Uri.parse(url);
      final response = await http.get(uri);

      print('response: ${response.body}');
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

  Future<String?> _editUser(BuildContext context) async {
    try {
      //verificar se um outro usuário já possui o mesmo email
      final emailSnapshot = await _clients
          .where('email', isEqualTo: _emailController.text)
          .where(FieldPath.documentId, isNotEqualTo: widget.documentId)
          .get();
      if (emailSnapshot.docs.isNotEmpty) {
        return 'Já existe um usuário com este email';
      }

      //verificar se um outro usuário já possui o mesmo cpf se for pessoa física
      final cpfSnapshot = await _clients
          .where('cpf', isEqualTo: _cpfController.text)
          .where(FieldPath.documentId, isNotEqualTo: widget.documentId)
          .get();
      if (cpfSnapshot.docs.isNotEmpty && !_isPj) {
        return 'Já existe um usuário com este CPF';
      }

      //verificar se um outro usuário já possui o mesmo cnpj se for pessoa jurídica
      final cnpjSnapshot = await _clients
          .where('cnpj', isEqualTo: _cnpjController.text)
          .where(FieldPath.documentId, isNotEqualTo: widget.documentId)
          .get();
      if (cnpjSnapshot.docs.isNotEmpty && _isPj) {
        return 'Já existe um usuário com este CNPJ';
      }

      await _clients.doc(widget.documentId).update({
        'name': _nameController.text.isEmpty ? null : _nameController.text,
        'cpf': _cpfController.text.isEmpty ? null : _cpfController.text,
        'phone': _phoneController.text.isEmpty
            ? null
            : '+55' + _phoneController.text.replaceAll(RegExp(r'[^\d]'), ''),
        'email': _emailController.text.isEmpty ? null : _emailController.text,
        'cnpj': _cnpjController.text.isEmpty ? null : _cnpjController.text,
        'stateRegistration': _stateRegistrationController.text.isEmpty
            ? null
            : _stateRegistrationController.text,
        'rg': _rgController.text.isEmpty ? null : _rgController.text,
        'municipalRegistration': _municipalRegistrationController.text.isEmpty
            ? null
            : _municipalRegistrationController.text,
        'cep': _cepController.text.isEmpty ? null : _cepController.text,
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
        'responsible': _responsibleController.text.isEmpty
            ? null
            : _responsibleController.text,
        'isPj': _isPj,
      });

      _nameController.clear();
      _cpfController.clear();
      _phoneController.clear();
      _emailController.clear();
      _cnpjController.clear();
      _stateRegistrationController.clear();
      _rgController.clear();
      _municipalRegistrationController.clear();
      _cepController.clear();
      _streetController.clear();
      _numberController.clear();
      _complementController.clear();
      _neighborhoodController.clear();
      _cityController.clear();
      _stateController.clear();
      _responsibleController.clear();

      return null; // Indica sucesso, sem mensagem de erro
    } catch (e) {
      print('Erro ao editar o usuário: $e');
      return 'Erro ao editar o usuário: $e'; // Retorna a mensagem de erro
    }
  }
}
