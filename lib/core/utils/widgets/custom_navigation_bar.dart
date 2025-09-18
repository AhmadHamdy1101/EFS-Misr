import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomBottomNav extends StatefulWidget {
  const CustomBottomNav({
    super.key,
    required this.icons,
    required this.selectedIndex,
    required this.onPressed,
  });
  final List<String> icons;
  final int selectedIndex;
  final ValueChanged<int> onPressed;

  @override
  _CustomBottomNavState createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, spreadRadius: 1, blurRadius: 5),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(widget.icons.length, (index) {
          return IconButton(
            icon: SvgPicture.asset(
              widget.icons[index],
              color: widget.selectedIndex == index
                  ? Theme.of(context).colorScheme.secondary // أو AppColors.green
                  : Theme.of(context).colorScheme.primary, // أو AppColors.black
            ),
            onPressed: () => widget.onPressed(index),
          );
        }),
      ),
    );
  }
}
