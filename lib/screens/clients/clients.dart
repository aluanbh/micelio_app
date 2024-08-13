import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:micelio_app/screens/clients/components/add_dialog.dart';
import 'package:micelio_app/screens/clients/components/edit_dialog.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({Key? key}) : super(key: key);

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _clients;
  final MaskTextInputFormatter _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final MaskTextInputFormatter _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  List<DocumentSnapshot> _clientList = [];
  List<DocumentSnapshot> _filteredClientsList = [];

  bool _loading = true;
  bool _isAdmin = false;
  String _searchQuery = '';
  _ClientsPageState()
      : _clients = FirebaseFirestore.instance.collection('clients');

  @override
  void initState() {
    _checkIfUserIsAdmin();
    super.initState();
    _fetchClients();
  }

  Future<void> _checkIfUserIsAdmin() async {
    setState(() {
      _loading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _isAdmin = userDoc.data()?['isAdmin'] ?? false;
        _loading = false;
      });
    }
  }

  void _fetchClients() async {
    setState(() {
      _loading = true;
    });

    try {
      final snapshot = await _clients.orderBy('name').get();

      if (!_isAdmin) {
        final user = FirebaseAuth.instance.currentUser;
        _clientList = snapshot.docs.where((client) {
          return (client.data() as Map<String, dynamic>)['owner'] == user?.uid;
        }).toList();
      } else {
        _clientList = snapshot.docs;
      }

      _filterClients();
    } catch (e) {
      print('Erro ao buscar clientes: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _filterClients() {
    setState(() {
      _filteredClientsList = _clientList.where((client) {
        final data = client.data() as Map<String, dynamic>;
        final name = data['name'] as String;
        final email = data['email'] as String;

        // Tratar CPF
        final cpfTemp = data['cpf'] as String? ?? '';
        final cpf = cpfTemp.replaceAll(RegExp(r'[.-]'), '');

        // Tratar CNPJ
        final cnpjTemp = data['cnpj'] as String? ?? '';
        final cnpj = cnpjTemp.replaceAll(RegExp(r'[./-]'), '');

        // Verificar se o campo CPF ou CNPJ existe e deve ser incluído na busca
        final cpfCnpj = cpf.isNotEmpty ? cpf : cnpj;

        return name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            cpfCnpj.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            email.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Clientes'),
            const SizedBox(width: 10),
            Text(
              '(${_filteredClientsList.length})',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          Container(
            padding: const EdgeInsets.only(right: 10),
            child: Tooltip(
              message: 'Criar novo cliente',
              child: IconButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.white),
                ),
                onPressed: () {
                  _showAddDialog();
                },
                icon: const Icon(Icons.add),
              ),
            ),
          ),
          SizedBox(width: 10),
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
                    _filterClients();
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  child: DataTable2(
                    columns: const [
                      DataColumn2(
                        label: Text('Nome'),
                        size: ColumnSize.L,
                      ),
                      DataColumn2(
                        label: Text('CPF / CNPJ'),
                        size: ColumnSize.M,
                      ),
                      DataColumn2(
                        label: Text('Telefone'),
                        size: ColumnSize.S,
                      ),
                      DataColumn2(
                        label: Text('Email'),
                        size: ColumnSize.L,
                      ),
                      DataColumn2(
                        label: Center(child: Text('Ações')),
                        size: ColumnSize.S,
                      ),
                    ],
                    rows: List.generate(
                      _filteredClientsList.length,
                      (index) {
                        final user = _filteredClientsList[index];
                        return DataRow(
                          cells: [
                            DataCell(Text(user['name'])),
                            DataCell(
                              user.data() is Map<String, dynamic>
                                  ? (() {
                                      final data =
                                          user.data() as Map<String, dynamic>;
                                      final cpf = data['cpf'] as String?;
                                      final cnpj = data['cnpj'] as String?;
                                      final cep = data['cep'] as String?;

                                      if (cpf != null && cpf.isNotEmpty) {
                                        return Text(_formatCpf(cpf));
                                      } else if (cnpj != null &&
                                          cnpj.isNotEmpty) {
                                        return Text(_formatCnpj(cnpj));
                                      } else if (cep != null &&
                                          cep.isNotEmpty) {
                                        return Text(_formatCep(cep));
                                      } else {
                                        return const Text(
                                          'Sem registro',
                                          style: TextStyle(color: Colors.grey),
                                        );
                                      }
                                    })()
                                  : const Text(
                                      'Sem registro',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                            ),
                            DataCell(
                              user.data() is Map<String, dynamic> &&
                                      (user.data() as Map<String, dynamic>)
                                          .containsKey('phone') &&
                                      user['phone'] != null
                                  ? Text(
                                      _formatPhoneNumber(user['phone']),
                                    )
                                  : const Text(
                                      'Sem registro',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                            ),
                            DataCell(Text(user['email'])),
                            DataCell(
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Tooltip(
                                    message: 'Editar',
                                    child: IconButton(
                                      onPressed: () {
                                        _showEditDialog(
                                            user.id,
                                            user.data()
                                                as Map<String, dynamic>);
                                      },
                                      icon: const Icon(Icons.edit),
                                    ),
                                  ),
                                  //nao exibir botao de deletar se o switch estiver ativado
                                  // if (_clientFilter != ClientFilter.deleted)
                                  //   Tooltip(
                                  //     message: 'Deletar',
                                  //     child: IconButton(
                                  //       onPressed: () {
                                  //         _deleteUser(user.id);
                                  //         ScaffoldMessenger.of(context)
                                  //             .showSnackBar(
                                  //           const SnackBar(
                                  //               content: Text(
                                  //                   'Usuário deletado com sucesso')),
                                  //         );
                                  //       },
                                  //       icon: const Icon(Icons.delete),
                                  //     ),
                                  //   ),

                                  // if (user['status'] == 'deleted')
                                  //   Tooltip(
                                  //     message: 'Restaurar',
                                  //     child: IconButton(
                                  //       onPressed: () {
                                  //         _restoreUser(user.id);
                                  //       },
                                  //       icon: const Icon(Icons.restore),
                                  //     ),
                                  //   ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      return '';
    }
    return phoneNumber.replaceFirst('+55', '').replaceAllMapped(
        RegExp(r'^(\d{2})(\d{5})(\d{4})$'),
        (match) => '(${match[1]}) ${match[2]}-${match[3]}');
  }

  String _formatCpf(String cpf) {
    if (cpf.isEmpty) {
      return '';
    }
    return cpf.replaceFirst('+55', '').replaceAllMapped(
        RegExp(r'^(\d{3})(\d{3})(\d{3})(\d{2})$'),
        (match) => '${match[1]}.${match[2]}.${match[3]}-${match[4]}');
  }

  void _showAddDialog() async {
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AddDialog(
        onAdd: () async {
          setState(() {});
        },
        onAddResult: (result) {
          if (result != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Usuário adicionado com sucesso')),
            );
          }
          _fetchClients(); // Atualizar a lista de usuários após adicionar
        },
      ),
    );
  }

  void _showEditDialog(String documentId, Map<String, dynamic> values) async {
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => EditDialog(
        onEdit: () {
          setState(() {});
        },
        onEditResult: (result) {
          if (result != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cliente editado com sucesso')),
            );
          }
          _fetchClients(); // Atualizar a lista de clientes após editar
        },
        documentId: documentId,
        values: values,
      ),
    );
  }

  void _deleteUser(String documentId) async {
    try {
      await _firestore.collection('clients').doc(documentId).update({
        'status': 'deleted',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente deletado com sucesso')),
      );
      _fetchClients(); // Atualizar a lista de clientes após deletar
    } catch (e) {
      print('Erro ao deletar cliente: $e');
    }
  }

  void _restoreUser(String documentId) async {
    try {
      await _firestore.collection('clients').doc(documentId).update({
        'status': 'active',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente restaurado com sucesso')),
      );
      _fetchClients(); // Atualizar a lista de clientes após restaurar
    } catch (e) {
      print('Erro ao restaurar cliente: $e');
    }
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
}
