import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:provider/provider.dart'; // Assuming you're using Provider for SelectedIndexNotifier

class TurnOnScreenButton extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final Function sendButtonPress;

  const TurnOnScreenButton({
    Key? key,
    required this.screenWidth,
    required this.screenHeight,
    required this.sendButtonPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: screenHeight * 0.03,
      right: screenWidth * 0.02,
      child: Align(
        alignment: Alignment.bottomRight,
        child: Tooltip(
          message: "Tænder den store skærm",
          child: ElevatedButton(
            onPressed: () {
              context
                  .read<SelectedIndexNotifier>()
                  .setSelectedIndex(previousIndex);
              sendButtonPress(1); // Special ID for "Turn On"
            },
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: EdgeInsets.all(screenHeight * 0.03),
              backgroundColor: Colors.black.withOpacity(0.7),
              shadowColor: Colors.greenAccent.withOpacity(0.4),
              elevation: 10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.power_settings_new,
                  size: screenHeight * 0.045, // Slightly smaller icon
                  color: Colors.greenAccent,
                ),
                const SizedBox(height: 2),
                Text(
                  "Tænd", // Keep text shorter
                  style: TextStyle(
                    fontSize: screenHeight * 0.02, // Reduce font size
                    fontWeight: FontWeight.bold,
                    fontFamily: 'RobotoCondensed', // More compact font
                    letterSpacing: 0.5, // Improve readability
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
