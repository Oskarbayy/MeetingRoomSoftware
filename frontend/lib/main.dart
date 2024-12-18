import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

Future<void> sendButtonPress(int buttonID) async {
  final url = Uri.parse('http://localhost:8080/api/button/$buttonID');

  try {
    final response = await http.post(url);
    if (response.statusCode == 200) {
      print('Button $buttonID sent successfully.');
    } else {
      print('Failed to send button: ${response.statusCode}');
    }
  } catch (e) {
    print('Error sending request: $e');
  }
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

            return Stack(
              children: [
                // Background Image
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/VestergaardSnow.png'),
                      fit: BoxFit.cover, // Ensures the image covers the full screen
                    ),
                  ),
                ),
                // Gradient Overlay
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black54, // Slightly darker at the top
                        Colors.transparent, // Fades to transparent
                        Colors.black54, // Slightly darker at the bottom
                      ],
                      stops: [0.0, 0.5, 1.0], // Control gradient stops
                    ),
                  ),
                ),

                // Stack Content
                Stack(
                  children: [
                    // Image at the top (scaled)
                    Positioned(
                      top: screenHeight * 0.05,
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
                    // Centered buttons
                    Center(
                      child: Container(
                        width: screenWidth * 0.8,
                        height: screenHeight * 0.5, // Increased height for the title
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02, // Padding inside container
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(150, 0, 0, 0),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Title
                            Text(
                              "Select source for presentation:",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: screenHeight * 0.0475, // Increased font size
                                fontWeight: FontWeight.w700, // Extra bold
                                color: Colors.white, // White text for visibility
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02), // Spacing below title
                            // Toggle Buttons
                            const Expanded(
                              child: ToggleButtonsWidget(
                                imagePaths: [
                                  'assets/images/clickshare.png',
                                  'assets/images/webcam.png',
                                  'assets/images/HDMI.png',
                                  'assets/images/HDMItoHDMI2.png',
                                ],
                                buttonTexts: [
                                  "Laptop PC Wireless",
                                  "Meeting room PC with webcam",
                                  "Other AV Devices",
                                  "Laptop PC cable",
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Turn Off Screen Button at the bottom right
                    Positioned(
                      bottom: screenHeight * 0.03, // Scaled from screen height
                      right: screenWidth * 0.02,   // Scaled from screen width
                      child: Tooltip(
                        message: "Slukker den store skærm",
                        child: ElevatedButton.icon(
                          onPressed: () {
                            sendButtonPress(0); // Special ID for "Turn Off"
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent, // Transparent background
                            foregroundColor: Colors.white, // White text and icon color
                            side: BorderSide(
                              color: Colors.white, // White border
                              width: screenWidth * 0.002, // Thin border scaled with screen width
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(screenHeight * 0.02), // Scaled corner radius
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.0175, // Scaled vertical padding
                              horizontal: screenWidth * 0.02, // Scaled horizontal padding
                            ),
                            elevation: 0, // No shadow for a clean look
                          ),
                          icon: Icon(
                            Icons.power_settings_new,
                            size: screenHeight * 0.04, // Scaled icon size
                          ),
                          label: Text(
                            "Sluk Skærm",
                            style: TextStyle(
                              fontSize: screenHeight * 0.02, // Scaled font size
                              fontWeight: FontWeight.bold, // Bold text
                            ),
                          ),
                        ),
                      ),
                    ),


                  ],
                ),
              ],
            );

          },
        ),
      ),
    );
  }
}

class ToggleButtonsWidget extends StatefulWidget {
  final List<String> imagePaths;
  final List<String> buttonTexts;

  const ToggleButtonsWidget({
    super.key,
    required this.imagePaths,
    required this.buttonTexts,
  });

  @override
  _ToggleButtonsWidgetState createState() => _ToggleButtonsWidgetState();
}

class _ToggleButtonsWidgetState extends State<ToggleButtonsWidget> {
  int selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.imagePaths.length, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.all(screenHeight * 0.02), // Consistent padding
            child: AspectRatio(
              aspectRatio: 1, // Ensures square buttons
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedIndex = index;
                  });
                  sendButtonPress(index + 1); // Button IDs start from 1
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedIndex == index
                      ? const Color(0xFFFDC830) // Golden-yellow when selected
                      : Colors.white, // Default background
                  foregroundColor: Colors.black, // Text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // Smooth edges
                  ),
                  elevation: 4, // Button shadow for depth
                  shadowColor: Colors.black54,
                  side: BorderSide(
                    color: selectedIndex == index
                        ? const Color(0xFFE4A411) // Gold border when selected
                        : Colors.black12, // Subtle gray border for others
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 2, // Image area
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          widget.imagePaths[index],
                          fit: BoxFit.contain,
                          color: selectedIndex == index
                              ? Colors.white // Slight tint for selected
                              : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      flex: 1, // Text area
                      child: Text(
                        widget.buttonTexts[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: screenHeight * 0.03, // Responsive font
                          fontWeight: FontWeight.w600, // Semi-bold
                          color: selectedIndex == index
                              ? Colors.black87 // Darker text when selected
                              : Colors.black54, // Subtle gray otherwise
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
