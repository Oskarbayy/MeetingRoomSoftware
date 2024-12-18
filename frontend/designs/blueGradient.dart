import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            double screenWidth = constraints.maxWidth;
            double screenHeight = constraints.maxHeight;

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(255, 3, 46, 144),
                    Color.fromARGB(255, 2, 27, 84),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Image at the top (scaled)
                  Positioned(
                    top: screenHeight * 0.05, // 5% from top
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Image.asset(
                        'assets/images/vesterlogowhite.png',
                        height: screenHeight * 0.1,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // Centered buttons (scaled)
                  
                  Center(
                    child: Container(
                      width: screenWidth * 0.8,
                      height: screenHeight * .45,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(150, 0, 0, 0), // Background color
                        borderRadius: BorderRadius.circular(8),   // Optional: rounded corners
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5), 
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const ToggleButtonsWidget(),
                    ),
                  ),

                  // Turn Off Screen Button at the bottom right
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Tooltip(
                      message: "Slukker den store skærm",
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // No action yet - backend will handle this later
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red, // Stand-out red color
                          foregroundColor: Colors.white, // White icon and text
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                        ),
                        icon: const Icon(Icons.power_settings_new),
                        label: const Text("Sluk Skærm"),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class ToggleButtonsWidget extends StatefulWidget {
  const ToggleButtonsWidget({super.key});

  @override
  _ToggleButtonsWidgetState createState() => _ToggleButtonsWidgetState();
}

class _ToggleButtonsWidgetState extends State<ToggleButtonsWidget> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Expanded( // Ensures buttons share space evenly
          child: Padding(
            padding: EdgeInsets.all(screenHeight * 0.03), // Adjust padding for spacing
            child: AspectRatio(
              aspectRatio: 1, // Maintains 1:1 aspect ratio
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedIndex == index
                      ? const Color.fromARGB(255, 255, 191, 25)
                      : const Color.fromARGB(255, 255, 255, 255),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenHeight * 0.02),
                  ),
                ),
                child: Text('HDMI ${index + 1}'),
              ),
            ),
          ),
        );
      }),
    );
  }
}
