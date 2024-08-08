import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:micelio_app/screens/dashboard/dashboard.dart';
import 'package:micelio_app/screens/products/products.dart';
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
                MouseRegion(
                  onEnter: (_) => hoverPage.value = "Dashboard",
                  onExit: (_) => hoverPage.value = "",
                  child: ValueListenableBuilder<String>(
                    valueListenable: hoverPage,
                    builder: (context, hoverValue, child) {
                      return ValueListenableBuilder<String>(
                        valueListenable: activePage,
                        builder: (context, activeValue, child) {
                          return Container(
                            color: hoverValue == "Dashboard" ||
                                    activeValue == "Dashboard"
                                ? Colors.grey[800]
                                : Colors.black,
                            child: ListTile(
                              title: const Text(
                                "Dashboard",
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                currentPage.value = DashbordPage();
                                activePage.value = "Dashboard";
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => hoverPage.value = "Produtos",
                  onExit: (_) => hoverPage.value = "",
                  child: ValueListenableBuilder<String>(
                    valueListenable: hoverPage,
                    builder: (context, hoverValue, child) {
                      return ValueListenableBuilder<String>(
                        valueListenable: activePage,
                        builder: (context, activeValue, child) {
                          return Container(
                            color: hoverValue == "Produtos" ||
                                    activeValue == "Produtos"
                                ? Colors.grey[800]
                                : Colors.black,
                            child: ListTile(
                              title: const Text(
                                "Produtos",
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                currentPage.value = ProductPage();
                                activePage.value = "Produtos";
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => hoverPage.value = "Usuários",
                  onExit: (_) => hoverPage.value = "",
                  child: ValueListenableBuilder<String>(
                    valueListenable: hoverPage,
                    builder: (context, hoverValue, child) {
                      return ValueListenableBuilder<String>(
                        valueListenable: activePage,
                        builder: (context, activeValue, child) {
                          return Container(
                            color: hoverValue == "Usuários" ||
                                    activeValue == "Usuários"
                                ? Colors.grey[800]
                                : Colors.black,
                            child: ListTile(
                              title: const Text(
                                "Usuários",
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                currentPage.value = UserPage();
                                activePage.value = "Usuários";
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => hoverPage.value = "Logout",
                  onExit: (_) => hoverPage.value = "",
                  child: ValueListenableBuilder<String>(
                    valueListenable: hoverPage,
                    builder: (context, hoverValue, child) {
                      return ValueListenableBuilder<String>(
                        valueListenable: activePage,
                        builder: (context, activeValue, child) {
                          return Container(
                            color: hoverValue == "Logout" ||
                                    activeValue == "Logout"
                                ? Colors.grey[800]
                                : Colors.black,
                            child: ListTile(
                              title: const Text(
                                "Logout",
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: () async {
                                FirebaseAuth.instance.signOut();
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.clear();
                                Navigator.pushReplacementNamed(
                                    context, "/login");
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
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
