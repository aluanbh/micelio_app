// lib/components/CustomMouseRegion.dart

import 'package:flutter/material.dart';

class CustomMouseRegion extends StatelessWidget {
  final String hoverText;
  final String activeText;
  final ValueNotifier<String> hoverPage;
  final ValueNotifier<String> activePage;
  final ValueNotifier<Widget> currentPage;
  final Widget page;

  const CustomMouseRegion({
    Key? key,
    required this.hoverText,
    required this.activeText,
    required this.hoverPage,
    required this.activePage,
    required this.currentPage,
    required this.page,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => hoverPage.value = hoverText,
      onExit: (_) => hoverPage.value = "",
      child: ValueListenableBuilder<String>(
        valueListenable: hoverPage,
        builder: (context, hoverValue, child) {
          return ValueListenableBuilder<String>(
            valueListenable: activePage,
            builder: (context, activeValue, child) {
              return Container(
                color: hoverValue == hoverText || activeValue == activeText
                    ? Colors.grey[800]
                    : Colors.black,
                child: ListTile(
                  title: Text(
                    hoverText,
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    currentPage.value = page;
                    activePage.value = activeText;
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
