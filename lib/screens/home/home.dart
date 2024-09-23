import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:micelio_app/components/mouse_region_item.dart';
import 'package:micelio_app/screens/clients/clients.dart';
import 'package:micelio_app/screens/dashboard/dashboard.dart';
import 'package:micelio_app/screens/priceTables/priceTables.dart';
import 'package:micelio_app/screens/products/products.dart';
import 'package:micelio_app/screens/stock/stock.dart';
import 'package:micelio_app/screens/users/users.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String uid = "";
  String name = "";
  String email = "";
  String phone = "";
  bool isAdmin = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  ValueNotifier<Widget> currentPage = ValueNotifier(DashbordPage());
  ValueNotifier<String> activePage = ValueNotifier("Dashboard");
  ValueNotifier<String> hoverPage = ValueNotifier("");

  isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > 767;
  }

  Future<void> _getUserDataFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String savedUid = prefs.getString('uid') ?? "";
    String savedName = prefs.getString('name') ?? "";
    String savedEmail = prefs.getString('email') ?? "";
    bool savedIsAdmin = prefs.getBool('isAdmin') ?? false;
    String savedPhone = prefs.getString('phone') ?? "";

    setState(() {
      uid = savedUid;
      name = savedName;
      email = savedEmail;
      isAdmin = savedIsAdmin;
      phone = savedPhone;
    });
  }

  @override
  void initState() {
    super.initState();
    _getUserDataFromSharedPreferences();
  }

  //funcao para logout do usuario
  Future<void> _logout() async {
    await _auth.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: screenWidth * 0.15,
            color: Colors.black,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(70, 20, 70, 10),
                  child: Image.asset(
                    'assets/images/logoMiceliobranca.png',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                textAlign: TextAlign.start,
                                "Bem vindo(a),",
                                style: TextStyle(color: Colors.white),
                              ),
                              Text(
                                name,
                                textAlign: TextAlign.start,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          //icon button to logout
                          IconButton(
                              icon:
                                  const Icon(Icons.logout, color: Colors.white),
                              onPressed: () async {
                                await _logout();
                              }),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                CustomMouseRegion(
                  hoverText: "Dashboard",
                  activeText: "Dashboard",
                  hoverPage: hoverPage,
                  activePage: activePage,
                  currentPage: currentPage,
                  page: DashbordPage(),
                ),
                CustomMouseRegion(
                  hoverText: "Produtos",
                  activeText: "Produtos",
                  hoverPage: hoverPage,
                  activePage: activePage,
                  currentPage: currentPage,
                  page: const ProductPage(),
                ),
                CustomMouseRegion(
                  hoverText: "Tabela de Preços",
                  activeText: "Tabela de Preços",
                  hoverPage: hoverPage,
                  activePage: activePage,
                  currentPage: currentPage,
                  page: const PriceTablesPage(),
                ),
                CustomMouseRegion(
                  hoverText: "Estoque",
                  activeText: "Estoque",
                  hoverPage: hoverPage,
                  activePage: activePage,
                  currentPage: currentPage,
                  page: const StockPage(),
                ),
                CustomMouseRegion(
                  hoverText: "Clientes",
                  activeText: "Clientes",
                  hoverPage: hoverPage,
                  activePage: activePage,
                  currentPage: currentPage,
                  page: const ClientsPage(),
                ),
                CustomMouseRegion(
                  hoverText: "Usuários",
                  activeText: "Usuários",
                  hoverPage: hoverPage,
                  activePage: activePage,
                  currentPage: currentPage,
                  page: const UserPage(),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: Center(
                child: ValueListenableBuilder<Widget>(
                  valueListenable: currentPage,
                  builder: (context, value, child) {
                    return value;
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
