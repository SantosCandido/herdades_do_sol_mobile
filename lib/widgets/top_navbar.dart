import 'package:flutter/material.dart';

class TopNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;
  final List<Widget>? actions;
  final String? userImageUrl;

  const TopNavbar({
    super.key,
    required this.title,
    this.backgroundColor = Colors.black,
    this.actions,
    this.userImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: backgroundColor,
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'RobotoCondensed',
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (actions != null) ...actions!,
        if (userImageUrl != null)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: (userImageUrl != null && userImageUrl!.startsWith('http'))
                  ? NetworkImage(userImageUrl!)
                  : const AssetImage('assets/icons/default_avatar.png') as ImageProvider,
              backgroundColor: Colors.grey[700],
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
