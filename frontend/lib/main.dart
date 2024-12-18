import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

void main() {
  runApp(const MyApp());
}

Process? serverProcess;

void startGoServer() async {
  try {
    // problems with the paths so mega ultra hardcoded, until it worked.
    final currentDir = Directory.current.path;
    final serverPath = '$currentDir/assets/server/server.exe';
    final serverWorkingDir = '$currentDir/assets/server';

    if (!File(serverPath).existsSync()) {
      print('Error: $serverPath does not exist.');
      return;
    }

    serverProcess = await Process.start(
      serverPath,
      [],
      workingDirectory: serverWorkingDir,
      runInShell: true,
    );

    serverProcess?.stdout.transform(SystemEncoding().decoder).listen((data) {
      print('Server stdout: $data');
    });

    serverProcess?.stderr.transform(SystemEncoding().decoder).listen((data) {
      print('Server stderr: $data');
    });

    print('Go server started.');
  } catch (e) {
    print('Error starting Go server: $e');
  }
}


void stopGoServer() {
  try {
    serverProcess?.kill();
    print('Go server stopped.');
  } catch (e) {
    print('Error stopping Go server: $e');
  }
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
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    startGoServer(); // Start the Go server when the app initializes
  }

  @override
  void dispose() {
    stopGoServer(); // Stop the Go server when the app is dead
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      stopGoServer(); // Stop the Go server if the app is detached
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    fit: BoxFit.cover,
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
                      Colors.black54,
                      Colors.transparent,
                      Colors.black54,
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
                              fontSize: screenHeight * 0.0475,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
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
                    bottom: screenHeight * 0.03,
                    right: screenWidth * 0.02,
                    child: Tooltip(
                      message: "Slukker den store skærm",
                      child: ElevatedButton.icon(
                        onPressed: () {
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
                            vertical: screenHeight * 0.0175,
                            horizontal: screenWidth * 0.02,
                          ),
                          elevation: 0,
                        ),
                        icon: Icon(
                          Icons.power_settings_new,
                          size: screenHeight * 0.04,
                        ),
                        label: Text(
                          "Sluk Skærm",
                          style: TextStyle(
                            fontSize: screenHeight * 0.02,
                            fontWeight: FontWeight.bold,
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
            padding: EdgeInsets.all(screenHeight * 0.02),
            child: AspectRatio(
              aspectRatio: 1,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedIndex = index;
                  });
                  sendButtonPress(index + 1); // Button IDs start from 1
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedIndex == index
                      ? const Color(0xFFFDC830)
                      : Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: Colors.black54,
                  side: BorderSide(
                    color: selectedIndex == index
                        ? const Color(0xFFE4A411)
                        : Colors.black12,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 2,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          widget.imagePaths[index],
                          fit: BoxFit.contain,
                          color: selectedIndex == index
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      flex: 1,
                      child: Text(
                        widget.buttonTexts[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: screenHeight * 0.03,
                          fontWeight: FontWeight.w600,
                          color: selectedIndex == index
                              ? Colors.black87
                              : Colors.black54,
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
