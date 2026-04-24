import 'package:flutter/material.dart';

class AsymmetricAppBarShape extends ShapeBorder {
  const AsymmetricAppBarShape();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect);
  
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path();
    // Top left
    path.lineTo(0, rect.height); // Extends downward to the full height on the left
    
    // Create an asymmetrical bottom shape
    path.quadraticBezierTo(
      rect.width * 0.35, rect.height,      // Control point
      rect.width, rect.height - 40,        // Right side ends higher up (smaller curve/height)
    );
    
    // Up to top right
    path.lineTo(rect.width, 0);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const CustomAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade400, Colors.orange.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: const AsymmetricAppBarShape(),
        shadows: [
          BoxShadow(
            color: Colors.orange.withAlpha(100),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          // Do NOT apply uniform padding, target specific spacing for asymmetrical alignment
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 32.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (Navigator.of(context).canPop())
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back',
                )
              else if (Scaffold.maybeOf(context)?.hasDrawer ?? false)
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white, size: 22),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: 'Menu',
                )
              else
                const SizedBox(width: 48),
              
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22, // Constant and uniform across pages
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              
              if (actions != null && actions!.isNotEmpty)
                Row(mainAxisSize: MainAxisSize.min, children: actions!)
              else
                const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  @override
  // Increase the overall height of the AppBar to accommodate the asymmetrical bottom
  Size get preferredSize => const Size.fromHeight(110.0);
}
