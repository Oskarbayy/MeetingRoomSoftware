import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:provider/provider.dart'; // Assuming you're using Provider for SelectedIndexNotifier

class TurnOffScreenButton extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final Function sendButtonPress;

  const TurnOffScreenButton({
    Key? key,
    required this.screenWidth,
    required this.screenHeight,
    required this.sendButtonPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: screenHeight * 0.03,
      left: screenWidth * 0.02,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Tooltip(
          message: "Slukker den store skærm",
          child: ElevatedButton(
            onPressed: () {
              context.read<SelectedIndexNotifier>().setSelectedIndex(-1);
              sendButtonPress(0); // Special ID for "Turn Off"
            },
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: EdgeInsets.all(screenHeight * 0.03),
              backgroundColor: Colors.black.withOpacity(0.7),
              shadowColor: Colors.redAccent.withOpacity(0.4),
              elevation: 10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.power_settings_new,
                  size: screenHeight * 0.045, // Slightly smaller icon
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 2),
                Text(
                  "Sluk", // Shortened text to fit better
                  style: TextStyle(
                    fontSize: screenHeight * 0.02, // Reduced font size
                    fontWeight: FontWeight.bold,
                    fontFamily: 'RobotoCondensed', // Compact and professional
                    letterSpacing: 0.5, // Better readability
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
