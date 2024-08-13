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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  ValueNotifier<Widget> currentPage = ValueNotifier(DashbordPage());
  ValueNotifier<String> activePage = ValueNotifier("Dashboard");
  ValueNotifier<String> hoverPage = ValueNotifier("");

  isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > 767;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: screenWidth * 0.20,
            color: Colors.black,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(70, 20, 70, 10),
                  child: Image.asset(
                    'assets/images/logoMiceliobranca.png',
                  ),
                ),
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
                  page: ProductPage(),
                ),
                CustomMouseRegion(
                  hoverText: "Tabela de Preços",
                  activeText: "Tabela de Preços",
                  hoverPage: hoverPage,
                  activePage: activePage,
                  currentPage: currentPage,
                  page: PriceTablesPage(),
                ),
                CustomMouseRegion(
                  hoverText: "Estoque",
                  activeText: "Estoque",
                  hoverPage: hoverPage,
                  activePage: activePage,
                  currentPage: currentPage,
                  page: StockPage(),
                ),
                CustomMouseRegion(
                  hoverText: "Clientes",
                  activeText: "Clientes",
                  hoverPage: hoverPage,
                  activePage: activePage,
                  currentPage: currentPage,
                  page: ClientsPage(),
                ),
                CustomMouseRegion(
                  hoverText: "Usuários",
                  activeText: "Usuários",
                  hoverPage: hoverPage,
                  activePage: activePage,
                  currentPage: currentPage,
                  page: UserPage(),
                ),
                CustomMouseRegion(
                  hoverText: "Logout",
                  activeText: "Logout",
                  hoverPage: hoverPage,
                  activePage: activePage,
                  currentPage: currentPage,
                  page: Container(), // Substitua por sua página de logout
                ),
              ],
            ),
          ),
          Container(
            width: screenWidth * 0.80,
            child: Center(
              child: ValueListenableBuilder<Widget>(
                valueListenable: currentPage,
                builder: (context, value, child) {
                  return value;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
