import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:micelio_app/screens/priceTables/components/add_dialog.dart';
import 'package:micelio_app/screens/priceTables/components/edit_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserFilter { onlyActive, deleted, all }

class PriceTablesPage extends StatefulWidget {
  const PriceTablesPage({Key? key}) : super(key: key);

  @override
  State<PriceTablesPage> createState() => _PriceTablesPageState();
}

class _PriceTablesPageState extends State<PriceTablesPage> {
  late final CollectionReference _users;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _products;
  late final CollectionReference _priceTables;
  bool _isAdmin = false;
  bool _loading = false;
  bool _isProcessing = false; // Controle para operações em andamento
  String _searchQuery = '';
  List<DocumentSnapshot> _productsList = [];
  List<DocumentSnapshot> _priceTablesList = [];
  List<DocumentSnapshot> _filteredProductsList = [];
  List<DocumentSnapshot> _filteredPriceTablesList = [];

  _PriceTablesPageState()
      : _products = FirebaseFirestore.instance.collection('products'),
        _priceTables = FirebaseFirestore.instance.collection('priceTables'),
        _users = FirebaseFirestore.instance.collection('users');

  @override
  void initState() {
    _checkIfUserIsAdmin();
    super.initState();
    _fetchProducts();
    _loading = true;
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

  Future<void> _fetchProducts() async {
    setState(() {
      _loading = true;
      _isProcessing = false; // Resetar o estado de processamento
    });
    try {
      final snapshot = await _products.orderBy('name').get();
      final snapshotTables = await _priceTables.orderBy('name').get();
      if (!_isAdmin) {
        final userUid = FirebaseAuth.instance.currentUser!.uid;
        final userTables = snapshotTables.docs
            .where((table) => table['userUid'] == userUid)
            .toList();
        setState(() {
          _productsList = snapshot.docs;
          _priceTablesList = userTables;
          _filterPriceTables();
          _loading = false;
        });
        return;
      } else {
        //se for admin, mostrar todas as tabelas de preco
        setState(() {
          _productsList = snapshot.docs;
          _priceTablesList = snapshotTables.docs;
          _filterPriceTables();
          _loading = false;
        });
        return;
      }
    } catch (e) {
      print('Erro ao buscar produtos ou tabelas: $e');
      setState(() {
        _loading = false;
        _isProcessing = false;
      });
    }
  }

  void _filterPriceTables() {
    setState(() {
      _filteredPriceTablesList = _priceTablesList.where((priceTable) {
        final name =
            (priceTable.data() as Map<String, dynamic>)['name'] as String;
        return name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    });
  }

  //funcao para buscar o nome do usuario que criou a tabela de precos
  Future<Map<String, dynamic>> _getUserNameAndAdminStatus(
      String userUid) async {
    final userDoc = await _users.doc(userUid).get();
    final data = userDoc.data() as Map<String, dynamic>?;
    final userName = data?['name'] ?? 'Usuário não encontrado';
    final isAdmin = data?['isAdmin'] ?? false;

    return {
      'name': userName,
      'isAdmin': isAdmin,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar as tabelas de preço de acordo com o valor de _isAdmin
    final adminTables = _filteredPriceTablesList.where((table) {
      final data = table.data() as Map<String, dynamic>;
      return data['isAdmin'] == true;
    }).toList();

    final userTables = _filteredPriceTablesList.where((table) {
      final data = table.data() as Map<String, dynamic>;
      return data['isAdmin'] == false;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Tabelas de Preço'),
            const SizedBox(width: 10),
            Text(
              '(${_filteredPriceTablesList.length})',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          Tooltip(
            message: 'Criar nova tabela de preços',
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddDialog, // Desabilita quando em processamento
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
                    _filterPriceTables();
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                //se _isAdmin for true e houver tabelas de preco, mostrar a tabela de preco do admin
                if (_isAdmin)
                  Expanded(
                    child: DataTable2(
                      columns: const [
                        DataColumn2(
                          label: Text('Nome'),
                          size: ColumnSize.L,
                        ),
                        DataColumn2(
                          label: Center(child: Text('N.º de Produtos')),
                          size: ColumnSize.S,
                        ),
                        DataColumn2(
                          label: Center(child: Text('Preenchidos')),
                          size: ColumnSize.S,
                        ),
                        DataColumn2(
                          label: Center(child: Text('Status')),
                          size: ColumnSize.S,
                        ),
                        DataColumn2(
                          label: Center(child: Text('Ações')),
                          size: ColumnSize.M,
                        ),
                      ],
                      rows: List.generate(adminTables.length, (index) {
                        final priceTable = adminTables[index];
                        final productCount = priceTable['products'].length;

                        final filledCount = priceTable['products']
                            .where((product) => product['price'] != null)
                            .length;
                        return DataRow(
                          cells: [
                            DataCell(
                              FutureBuilder<Map<String, dynamic>>(
                                future: _getUserNameAndAdminStatus(
                                    priceTable['userUid'] as String),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Text('Carregando...');
                                  } else if (snapshot.hasError) {
                                    return const Text('Erro ao carregar nome');
                                  } else {
                                    final userData = snapshot.data ??
                                        {
                                          'name': 'Usuário não encontrado',
                                          'isAdmin': false
                                        };
                                    final userName = userData['name'] as String;
                                    final isAdmin = userData['isAdmin'] as bool;

                                    return Text(
                                      '${priceTable['name']} - $userName',
                                      style: TextStyle(
                                        color: Colors.black,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            DataCell(
                                Center(child: Text(productCount.toString()))),
                            DataCell(
                                Center(child: Text(filledCount.toString()))),
                            DataCell(Center(
                                child: Text(priceTable['status']
                                    ? 'Ativo'
                                    : 'Inativo'))),
                            DataCell(
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Tooltip(
                                    message: 'Editar',
                                    child: IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        setState(() {
                                          _showEditDialog(
                                              priceTable.id,
                                              priceTable.data()
                                                  as Map<String, dynamic>);
                                        });
                                      },
                                    ),
                                  ),
                                  Tooltip(
                                    message: 'Deletar',
                                    child: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: _isProcessing
                                          ? null
                                          : () {
                                              _deletePriceTable(priceTable.id);
                                            },
                                    ),
                                  ),
                                  Tooltip(
                                    message: 'Atualizar Produtos',
                                    child: IconButton(
                                      icon: const Icon(Icons.refresh),
                                      onPressed: _isProcessing
                                          ? null
                                          : () {
                                              _updatePriceTableProducts(
                                                  priceTable.id);
                                            },
                                    ),
                                  ),
                                  Tooltip(
                                    message: 'Clonar',
                                    child: IconButton(
                                      icon: const Icon(Icons.copy),
                                      onPressed: () {
                                        _clonePriceTable(priceTable.id);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                if (_isAdmin)
                  Text('Tabelas de Preço do Distribuidor',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      )),
                Expanded(
                  child: DataTable2(
                    columns: const [
                      DataColumn2(
                        label: Text('Nome'),
                        size: ColumnSize.L,
                      ),
                      DataColumn2(
                        label: Center(child: Text('N.º de Produtos')),
                        size: ColumnSize.S,
                      ),
                      DataColumn2(
                        label: Center(child: Text('Preenchidos')),
                        size: ColumnSize.S,
                      ),
                      DataColumn2(
                        label: Center(child: Text('Status')),
                        size: ColumnSize.S,
                      ),
                      DataColumn2(
                        label: Center(child: Text('Ações')),
                        size: ColumnSize.M,
                      ),
                    ],
                    rows: List.generate(userTables.length, (index) {
                      final priceTable = userTables[index];
                      final productCount = priceTable['products'].length;

                      final filledCount = priceTable['products']
                          .where((product) => product['price'] != null)
                          .length;
                      return DataRow(
                        cells: [
                          DataCell(
                            FutureBuilder<Map<String, dynamic>>(
                              future: _getUserNameAndAdminStatus(
                                  priceTable['userUid'] as String),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Text('Carregando...');
                                } else if (snapshot.hasError) {
                                  return const Text('Erro ao carregar nome');
                                } else {
                                  final userData = snapshot.data ??
                                      {
                                        'name': 'Usuário não encontrado',
                                        'isAdmin': false
                                      };
                                  final userName = userData['name'] as String;
                                  final isAdmin = userData['isAdmin'] as bool;

                                  return Text(
                                    '${priceTable['name']} - $userName',
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          DataCell(
                              Center(child: Text(productCount.toString()))),
                          DataCell(Center(child: Text(filledCount.toString()))),
                          DataCell(Center(
                              child: Text(
                                  priceTable['status'] ? 'Ativo' : 'Inativo'))),
                          DataCell(
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Tooltip(
                                  message: 'Editar',
                                  child: IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      setState(() {
                                        _showEditDialog(
                                            priceTable.id,
                                            priceTable.data()
                                                as Map<String, dynamic>);
                                      });
                                    },
                                  ),
                                ),
                                Tooltip(
                                  message: 'Deletar',
                                  child: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: _isProcessing
                                        ? null
                                        : () {
                                            _deletePriceTable(priceTable.id);
                                          },
                                  ),
                                ),
                                Tooltip(
                                  message: 'Atualizar Produtos',
                                  child: IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: _isProcessing
                                        ? null
                                        : () {
                                            _updatePriceTableProducts(
                                                priceTable.id);
                                          },
                                  ),
                                ),
                                // if (!_isAdmin)
                                Tooltip(
                                  message: 'Clonar',
                                  child: IconButton(
                                    icon: const Icon(Icons.copy),
                                    onPressed: () {
                                      _clonePriceTable(priceTable.id);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
    );
  }

  void _showAddDialog() async {
    await _checkIfUserIsAdmin();
    final isAdmin = _isAdmin;

    setState(() => _isProcessing = true);
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AddDialog(
        onAdd: () async {
          await _fetchProducts();
          setState(() => _isProcessing = false);
        },
        onAddResult: (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(result ?? 'Tabela de Produtos adicionada com sucesso'),
            ),
          );
        },
        products: _productsList,
        isAdmin: isAdmin, // Passe o parâmetro isAdmin para o modal
      ),
    );
  }

  void _showEditDialog(String documentId, Map<String, dynamic> values) async {
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => EditDialog(
        onEdit: () async {
          await _fetchProducts();
          setState(() => _isProcessing = false);
        },
        documentId: documentId,
        values: values,
      ),
    );
  }

  void _deletePriceTable(String documentId) async {
    setState(() => _isProcessing = true);
    try {
      await _priceTables.doc(documentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tabela de Preços deletada com sucesso')),
      );
      await _fetchProducts();
    } catch (e) {
      print('Erro ao deletar tabela de preço: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao deletar tabela de preço')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _updatePriceTableProducts(String documentId) async {
    setState(() => _isProcessing = true);
    try {
      // Obtém os produtos da tabela de preços
      final doc = await _priceTables.doc(documentId).get();
      final products = List<Map<String, dynamic>>.from(
          (doc.data() as Map<String, dynamic>)['products'] ?? []);

      // Cria uma nova lista para armazenar produtos atualizados
      List<Map<String, dynamic>> updatedProducts = [];

      for (var product in products) {
        final productId = product['uid'] as String?;
        if (productId != null) {
          final productData = await _products.doc(productId).get();
          if (productData.exists) {
            // Atualiza o nome do produto se o produto existir
            updatedProducts.add({
              'uid': productId,
              'name': productData['name'],
              'price': product['price'], // Mantém o preço original
            });
          }
        }
      }

      // Identifica produtos novos para adicionar à tabela de preços
      final productIds =
          updatedProducts.map((product) => product['uid']).toList();
      final newProducts = _productsList
          .where((product) => !productIds.contains(product.id))
          .map((product) => {
                'uid': product.id,
                'name': product[
                    'name'], // Use um valor padrão ou uma variável se necessário
                'price': null,
              })
          .toList();

      // Adiciona novos produtos à lista atualizada
      updatedProducts.addAll(newProducts);

      // Atualiza o documento da tabela de preços
      await _priceTables.doc(documentId).update({
        'products': updatedProducts,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tabela de Preços atualizada com sucesso')),
      );

      await _fetchProducts(); // Atualiza a lista de produtos
    } catch (e) {
      print('Erro ao atualizar produtos da tabela de preço: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erro ao atualizar produtos da tabela de preço')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  //funcao para clonar a tabela de precos com outro nome abrindo uma nova dialog com input
  void _clonePriceTable(String documentId) async {
    // final isAdmin = _isAdmin;
    setState(() => _isProcessing = true);
    try {
      final doc = await _priceTables.doc(documentId).get();
      final data = doc.data() as Map<String, dynamic>;
      final products = List<Map<String, dynamic>>.from(data['products'] ?? []);
      final isAdminDatabela = data['isAdmin'] as bool;
      final userUidDaTabela = data['userUid'] as String;

      String name = data['name'] as String;

      final newName = await showDialog<String?>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clonar Tabela de Preços'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Digite o nome da nova tabela de preços:'),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Nome da Tabela de Preços',
                ),
                onChanged: (value) {
                  name = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, name),
              child: const Text('Clonar'),
            ),
          ],
        ),
      );

      if (newName != null && newName.isNotEmpty) {
        // Verifica se já existe uma tabela com o mesmo nome
        final existingTables =
            await _priceTables.where('name', isEqualTo: newName).get();

        if (existingTables.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Já existe uma tabela com esse nome')),
          );
        } else {
          // Adiciona a nova tabela
          await _priceTables.add({
            'userUid': userUidDaTabela,
            'name': newName,
            'products': products,
            'status': true,
            'isAdmin': isAdminDatabela,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Tabela de Preços clonada com sucesso')),
          );
          await _fetchProducts();
        }
      }
    } catch (e) {
      print('Erro ao clonar tabela de preços: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao clonar tabela de preços')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}
