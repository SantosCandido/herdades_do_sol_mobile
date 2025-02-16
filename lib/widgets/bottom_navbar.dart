import 'package:flutter/material.dart';

class BottomNavbar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavbar({super.key, required this.currentIndex, required this.onTap});

  @override
  _BottomNavbarState createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Cria a animação da estrela
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Duração do ciclo
    )..repeat(reverse: true); // Repete continuamente

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.orange,
      selectedItemColor: Colors.yellow,
      unselectedItemColor: Colors.white,
      elevation: 8,
      currentIndex: widget.currentIndex,
      onTap: widget.onTap,
      type: BottomNavigationBarType.fixed,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.store_mall_directory_rounded),
          label: 'Booking',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Our Estates',
        ),
        BottomNavigationBarItem(
          icon: widget.currentIndex == 2
              ? AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: const Icon(Icons.star, color: Colors.yellow, size: 30),
              );
            },
          )
              : const Icon(Icons.star_border),
          label: '',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_rounded),
          label: 'My Trips',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Profile',
        ),
      ],
    );
  }
}