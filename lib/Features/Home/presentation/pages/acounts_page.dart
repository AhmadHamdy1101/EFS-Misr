

import 'package:efs_misr/Features/Home/presentation/widgets/accounts_page_body.dart';
import 'package:flutter/material.dart';


class AccontsPage extends StatefulWidget {
  const AccontsPage({super.key});

  @override
  State<AccontsPage> createState() => _AccontsPageState();
}

class _AccontsPageState extends State<AccontsPage> {



  @override
  Widget build(BuildContext context) {
    return (AccountsPageBody());
  }
}
