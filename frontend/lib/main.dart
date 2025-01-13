import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/services.dart'; // For keyboard events
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

bool fullscreen = false;
bool _onKey(KeyEvent event) {
  if (event is KeyDownEvent) {
    if (event.logicalKey == LogicalKeyboardKey.f11) {
      if (fullscreen == true) {
        windowManager.setFullScreen(false);
        print('Exiting full-screen mode');
        fullscreen = false;
      } else {
        windowManager.setFullScreen(true);
        print('Entering full-screen mode');
        fullscreen = true;
      }
    }
  }
  return false;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  
  windowManager.setFullScreen(true);
  print('Entering automatic full-screen mode');
  fullscreen = true;

  await loadConfig();
  runApp(
    ChangeNotifierProvider(
      create: (context) => SelectedIndexNotifier(),
      child: MyApp(),
    ),
  );

  ServicesBinding.instance.keyboard.addHandler(_onKey);
}

int previousIndex = -1;
class SelectedIndexNotifier extends ChangeNotifier {
  int _selectedIndex = -1;

  int get selectedIndex => _selectedIndex;

  int readSelectedIndex() {
    return _selectedIndex;
  }

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}

Process? serverProcess;
bool isServerStarting = false;
bool isServerStopping = false;

Future<void> startGoServer() async {
  if (isServerStarting || serverProcess != null) return;
  isServerStarting = true;

  try {
    // Get the path to the running .exe, then derive the .exe directory
    final exePath = Platform.resolvedExecutable;
    final exeDir = p.dirname(exePath);

    final serverPath = p.join(exeDir, 'server.exe');
    final logFilePath = p.join(exeDir, 'log.txt');
    final logFile = File(logFilePath);

    if (!await logFile.exists()) {
      await logFile.create();
    }

    await logFile.writeAsString('Server path: $serverPath\n', mode: FileMode.append);

    if (!File(serverPath).existsSync()) {
      final errorMsg = 'Error: $serverPath does not exist.';
      print(errorMsg);
      await logFile.writeAsString('$errorMsg\n', mode: FileMode.append);
      return;
    }

    serverProcess = await Process.start(
      serverPath,
      [],
      workingDirectory: exeDir, // ensure it runs in the same dir as server.exe
      runInShell: true,
    );

    serverProcess?.stdout.transform(SystemEncoding().decoder).listen((data) async {
      print('Server stdout: $data');
      await logFile.writeAsString('Server stdout: $data\n', mode: FileMode.append);
    });

    serverProcess?.stderr.transform(SystemEncoding().decoder).listen((data) async {
      print('Server stderr: $data');
      await logFile.writeAsString('Server stderr: $data\n', mode: FileMode.append);
    });

    print('Go server started.');
    await logFile.writeAsString('Go server started.\n', mode: FileMode.append);
  } catch (e) {
    print('Error starting Go server: $e');

    final exePath = Platform.resolvedExecutable;
    final exeDir = p.dirname(exePath);
    final logFilePath = p.join(exeDir, 'log.txt');
    final logFile = File(logFilePath);

    await logFile.writeAsString('Error starting Go server: $e\n', mode: FileMode.append);
  } finally {
    isServerStarting = false;
  }
}

Future<void> stopGoServer() async {
  if (isServerStopping || serverProcess == null) return;
  isServerStopping = true;

  try {
    print("Stopping Go server...");
    // Using taskkill by process name does not need an absolute path
    await Process.run('taskkill', ['/F', '/IM', 'server.exe']);
    print('All server.exe processes terminated.');

    // Wait for the current serverProcess to fully exit
    await serverProcess?.exitCode;
    print('Exit code: ${await serverProcess?.exitCode}');

    serverProcess = null;
    print('Go server stopped.');
  } catch (e) {
    print('Error stopping Go server: $e');
  } finally {
    isServerStopping = false;
  }
}

Map<String, dynamic>? appConfig;

Future<void> loadConfig() async {
  try {
    // Get the path of the running .exe, then derive the directory
    final exePath = Platform.resolvedExecutable;
    final exeDir = p.dirname(exePath);

    // Create absolute path for config.json
    final configFilePath = p.join(exeDir, 'config.json');

    if (!File(configFilePath).existsSync()) {
      print('Config file not found at $configFilePath');
      return;
    }

    final configContent = await File(configFilePath).readAsString();
    appConfig = jsonDecode(configContent);
    print('Config loaded: $appConfig');
  } catch (e) {
    print('Error loading config: $e');
  }
}

Future<void> sendButtonPress(int buttonID) async {
  if (appConfig == null) {
    print('Config not loaded. Cannot send button press.');
    return;
  }

  final serverPort = appConfig?['server_port'] ?? 8080;
  final url = Uri.parse('http://localhost:$serverPort/api/button/$buttonID');

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
    startGoServer();
  }

  @override
  void dispose() {
    super.dispose();
    stopGoServer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(state);
    if (state == AppLifecycleState.inactive) {
      print('App is inactive. Stopping server...');
      stopGoServer();
    } else if (state == AppLifecycleState.resumed) {
      loadConfig();
      startGoServer();
      print('App is resumed - server started.');
    } else if (state == AppLifecycleState.paused) {
      print('App is paused.');
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
                  
                  // Turn On Screen Button at the bottom right
                  Positioned(
                    bottom: screenHeight * 0.03,
                    right: screenWidth * 0.02,
                    child: Transform.translate(
                      offset: Offset(screenWidth * 0.01, screenHeight * 0.01), // Adjust the offset as needed
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Tooltip(
                          message: "Tænder den store skærm",
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.read<SelectedIndexNotifier>().setSelectedIndex(previousIndex);
                              sendButtonPress(1); // Special ID for "Turn On"
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
                                vertical: screenHeight * 0.025, // Increased padding
                                horizontal: screenWidth * 0.03, // Increased padding
                              ),
                              elevation: 0,
                            ),
                            icon: Icon(
                              Icons.power_settings_new,
                              size: screenHeight * 0.06, // Increased icon size
                            ),
                            label: Text(
                              "Tænd Skærm",
                              style: TextStyle(
                                fontSize: screenHeight * 0.03, // Increased font size
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Turn Off Screen Button at the bottom left
                  Positioned(
                    bottom: screenHeight * 0.03,
                    left: screenWidth * 0.02,
                    child: Transform.translate(
                      offset: Offset(-screenWidth * 0.01, screenHeight * 0.01), // Adjust the offset as needed
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
                                vertical: screenHeight * 0.025, // Increased padding
                                horizontal: screenWidth * 0.03, // Increased padding
                              ),
                              elevation: 0,
                            ),
                            icon: Icon(
                              Icons.power_settings_new,
                              size: screenHeight * 0.06, // Increased icon size
                            ),
                            label: Text(
                              "Sluk Skærm",
                              style: TextStyle(
                                fontSize: screenHeight * 0.03, // Increased font size
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

class ToggleButtonsWidget extends StatelessWidget {
  final List<String> imagePaths;
  final List<String> buttonTexts;

  const ToggleButtonsWidget({
    super.key,
    required this.imagePaths,
    required this.buttonTexts,
  });

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: List.generate(imagePaths.length, (index) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(screenHeight * 0.02),
        child: AspectRatio(
          aspectRatio: 1,
          child: Consumer<SelectedIndexNotifier>(
            builder: (context, selectedIndexNotifier, child) {
              return ElevatedButton(
                onPressed: () {
                  selectedIndexNotifier.setSelectedIndex(index);
                  previousIndex = context.read<SelectedIndexNotifier>().readSelectedIndex();
                  sendButtonPress(index + 2); // Button IDs start from 2 since turn off and on is on id 0 and 1
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedIndexNotifier.selectedIndex == index
                      ? const Color(0xFFFDC830)
                      : Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: Colors.black54,
                  side: BorderSide(
                    color: selectedIndexNotifier.selectedIndex == index
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
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromRGBO(0, 0, 0, 0.2),
                                blurRadius: 50,
                                spreadRadius: -15,
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            imagePaths[index],
                            fit: BoxFit.contain,
                            color: selectedIndexNotifier.selectedIndex == index
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      flex: 1,
                      child: Text(
                        buttonTexts[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: screenHeight * 0.0275,
                          fontWeight: FontWeight.w600,
                          color: selectedIndexNotifier.selectedIndex == index
                              ? Colors.black87
                              : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }),
);
  }
}