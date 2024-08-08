import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:micelio_app/screens/users/components/add_dialog.dart';
import 'package:micelio_app/screens/users/components/edit_dialog.dart';

enum UserFilter { onlyActive, deleted, all }

class UserPage extends StatefulWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _users;
  final MaskTextInputFormatter _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final MaskTextInputFormatter _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  UserFilter _userFilter = UserFilter.onlyActive;
  bool _isAdmin = false;

  List<DocumentSnapshot> _allUsers = [];
  List<DocumentSnapshot> _activeUsers = [];
  List<DocumentSnapshot> _deletedUsers = [];
  bool _loading = true;

  _UserPageState() : _users = FirebaseFirestore.instance.collection('users');

  @override
  void initState() {
    super.initState();
    _checkIfUserIsAdmin();
    _fetchUsers();
  }

  Future<void> _checkIfUserIsAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _isAdmin = userDoc.data()?['isAdmin'] ?? false;
      });
    }
  }

  void _fetchUsers() async {
    setState(() {
      _loading = true;
    });

    try {
      QuerySnapshot allUsersSnapshot = await _users.get();
      _allUsers = allUsersSnapshot.docs;

      QuerySnapshot deletedUsersSnapshot =
          await _users.where('status', isEqualTo: 'deleted').get();
      _deletedUsers = deletedUsersSnapshot.docs;

      QuerySnapshot activeUsersSnapshot =
          await _users.where('status', isNotEqualTo: 'deleted').get();
      _activeUsers = activeUsersSnapshot.docs;

      print('Usuários ativos: ${_activeUsers.length}');
    } catch (e) {
      print('Erro ao buscar usuários: $e');
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<DocumentSnapshot> users =
        _userFilter == UserFilter.deleted ? _deletedUsers : _activeUsers;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Usuários'),
            const SizedBox(width: 10),
            Text(
              '(${_userFilter == UserFilter.deleted ? _deletedUsers.length : _activeUsers.length})',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          Container(
            padding: const EdgeInsets.only(right: 10),
            child: Tooltip(
              message: 'Criar novo usuário',
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
          Row(
            children: [
              Text(
                'Exibir usuários deletados',
                style: const TextStyle(fontSize: 16),
              ),
              Switch(
                value: _userFilter == UserFilter.deleted,
                onChanged: (value) => setState(() => _userFilter =
                    value ? UserFilter.deleted : UserFilter.onlyActive),
              ),
            ],
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
                        label: Text('CPF'),
                        size: ColumnSize.S,
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
                      users.length,
                      (index) {
                        final user = users[index];
                        return DataRow(
                          cells: [
                            DataCell(Text(user['name'])),
                            DataCell(
                              user.data() is Map<String, dynamic> &&
                                      (user.data() as Map<String, dynamic>)
                                          .containsKey('cpf') &&
                                      user['cpf'] != null
                                  ? Text(
                                      _formatCpf(user['cpf']),
                                    )
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
                                  if (_userFilter != UserFilter.deleted)
                                    Tooltip(
                                      message: 'Deletar',
                                      child: IconButton(
                                        onPressed: () {
                                          _deleteUser(user.id);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Usuário deletado com sucesso')),
                                          );
                                        },
                                        icon: const Icon(Icons.delete),
                                      ),
                                    ),

                                  if (user['status'] == 'deleted')
                                    Tooltip(
                                      message: 'Restaurar',
                                      child: IconButton(
                                        onPressed: () {
                                          _restoreUser(user.id);
                                        },
                                        icon: const Icon(Icons.restore),
                                      ),
                                    ),
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
          _fetchUsers(); // Atualizar a lista de usuários após adicionar
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
              const SnackBar(content: Text('Usuário editado com sucesso')),
            );
          }
          _fetchUsers(); // Atualizar a lista de usuários após editar
        },
        documentId: documentId,
        values: values,
      ),
    );
  }

  void _deleteUser(String documentId) async {
    try {
      await _firestore.collection('users').doc(documentId).update({
        'status': 'deleted',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário deletado com sucesso')),
      );
      _fetchUsers(); // Atualizar a lista de usuários após deletar
    } catch (e) {
      print('Erro ao deletar usuário: $e');
    }
  }

  void _restoreUser(String documentId) async {
    try {
      await _firestore.collection('users').doc(documentId).update({
        'status': 'active',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário restaurado com sucesso')),
      );
      _fetchUsers(); // Atualizar a lista de usuários após restaurar
    } catch (e) {
      print('Erro ao restaurar usuário: $e');
    }
  }
}
