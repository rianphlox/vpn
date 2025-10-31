// This file contains the implementation of the BottomNavigation widget, which is a custom bottom navigation bar.

import 'package:flutter/material.dart';

/// A custom bottom navigation bar.
class BottomNavigation extends StatelessWidget {
  /// The index of the current tab.
  final int currentIndex;

  /// A callback function that is called when a tab is selected.
  final Function(int)? onTabSelected;

  /// Creates a new instance of the [BottomNavigation].
  const BottomNavigation({
    super.key,
    required this.currentIndex,
    this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A4A).withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // VPN tab
          Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected?.call(0),
              child: Container(
                height: 40,
                margin: EdgeInsets.all(currentIndex == 0 ? 5 : 0),
                decoration: currentIndex == 0
                    ? BoxDecoration(
                        color: const Color(0xFF4A4A6A),
                        borderRadius: BorderRadius.circular(20),
                      )
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield,
                      color: currentIndex == 0 ? Colors.white : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'VPN',
                      style: TextStyle(
                        color: currentIndex == 0 ? Colors.white : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Proxy tab - Commented out as requested
          // Expanded(
          //   child: GestureDetector(
          //     onTap: () => onTabSelected?.call(1),
          //     child: Container(
          //       height: 40,
          //       margin: EdgeInsets.all(currentIndex == 1 ? 5 : 0),
          //       decoration: currentIndex == 1
          //           ? BoxDecoration(
          //               color: const Color(0xFF4A4A6A),
          //               borderRadius: BorderRadius.circular(20),
          //             )
          //           : null,
          //       child: Row(
          //         mainAxisAlignment: MainAxisAlignment.center,
          //         children: [
          //           Icon(
          //             Icons.swap_horiz,
          //             color: currentIndex == 1 ? Colors.white : Colors.grey,
          //             size: 16,
          //           ),
          //           const SizedBox(width: 4),
          //           Text(
          //             'Proxy',
          //             style: TextStyle(
          //               color: currentIndex == 1 ? Colors.white : Colors.grey,
          //               fontSize: 12,
          //               fontWeight: FontWeight.w500,
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
          // Store tab
          Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected?.call(1),
              child: Container(
                height: 40,
                margin: EdgeInsets.all(currentIndex == 1 ? 5 : 0),
                decoration: currentIndex == 1
                    ? BoxDecoration(
                        color: const Color(0xFF4A4A6A),
                        borderRadius: BorderRadius.circular(20),
                      )
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.store,
                      color: currentIndex == 1 ? Colors.white : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Store',
                      style: TextStyle(
                        color: currentIndex == 1 ? Colors.white : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Tools tab
          Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected?.call(2),
              child: Container(
                height: 40,
                margin: EdgeInsets.all(currentIndex == 2 ? 5 : 0),
                decoration: currentIndex == 2
                    ? BoxDecoration(
                        color: const Color(0xFF4A4A6A),
                        borderRadius: BorderRadius.circular(20),
                      )
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.build,
                      color: currentIndex == 2 ? Colors.white : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tools',
                      style: TextStyle(
                        color: currentIndex == 2 ? Colors.white : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
