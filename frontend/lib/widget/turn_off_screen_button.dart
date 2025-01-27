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
      child: Transform.translate(
        offset: Offset(-screenWidth * 0.01, screenHeight * 0.01),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Tooltip(
            message: "Slukker den store skærm",
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<SelectedIndexNotifier>().setSelectedIndex(-1);
                sendButtonPress(0); // Special ID for "Turn Off"
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white,
                  width: screenWidth * 0.002,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenHeight * 0.02),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.025,
                  horizontal: screenWidth * 0.03,
                ),
                elevation: 0,
              ),
              icon: Icon(
                Icons.power_settings_new,
                size: screenHeight * 0.06,
              ),
              label: Text(
                "Sluk Skærm",
                style: TextStyle(
                  fontSize: screenHeight * 0.03,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
