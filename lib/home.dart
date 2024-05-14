import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class Home extends StatefulWidget {
  const Home({Key? key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String txt =
      '1) Choose an options \n 2) Please say the name of the parameter and then the correct data';
  double conf = 1.0;
  late stt.SpeechToText speech;
  bool isListening = false;
  bool _isReminder = false;
  bool _isAppointment = false;
  bool _isDevice = false;
  List<Map<String, dynamic>> medicationEntries = [];
  List<Map<String, dynamic>> adviceEntries = [];
  List<Map<String, dynamic>> appointmentEntries = [];
  List<Map<String, dynamic>> deviceEntries = [];


  List<String> reminderVariables = [
    'Type',
    'Title',
    'Description',
    'Date',
    'Time',
    'Alarm',
    'Notification',
  ];

  List<String> appointmentVariables = [
    'Date',
    'Doctor',
    'Specialty',
    'Time',
  ];
 
  List<bool> reminderVariableSpoken = List.filled(7, false);
  List<bool> appointmentVariableSpoken = List.filled(4, false);

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
    initializeSpeech();
    fetchDevices();
  }

  void initializeSpeech() async {
    bool available = await speech.initialize(
      onError: (val) => print('onError : $val'),
      onStatus: (val) => print('onStatus : $val'),
    );
    if (!available) {
      print('Speech recognition not available');
    }
  }

Future<void> fetchDevices() async {
  // Fetch device data from the database
  final url = Uri.parse('http://192.168.180.239:5000/devices/user');
  final response = await http.get(
    url,
    headers: {'User-Agent': 'FlutterApp'}, // Set User-Agent header
  );

  if (response.statusCode == 200) {
    if (response.headers['content-type']!.contains('text/html')) {
      // Handle HTML response
      print('Received HTML response');
      // You can display an error message or do other handling here
    } else {
      // Handle JSON response
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      print('$responseData');
      setState(() {
        deviceEntries = List<Map<String, dynamic>>.from(responseData['devices']);
      });
    }
  } else {
    throw Exception('Failed to load devices');
  }
}
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Confidence: ${(conf * 100.0).toStringAsFixed(1)}%',
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AvatarGlow(
        animate: isListening,
        glowColor: Theme.of(context).primaryColor,
        duration: const Duration(milliseconds: 2000),
        repeat: true,
        child: FloatingActionButton(
          onPressed: _openOptionsList,
          child: Icon(isListening ? Icons.mic : Icons.mic_none),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(30, 30, 30, 150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                txt,
                style: const TextStyle(
                  fontSize: 30,
                  color: Colors.indigo,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if ((_isReminder || _isAppointment) && !_isAppointment)
                ...List.generate(
                  reminderVariables.length,
                  (index) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${reminderVariables[index]}:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            // Highlight the variable name if spoken
                            color: reminderVariableSpoken[index] ? Colors.green : Colors.black,
                          ),
                        ),
                        if (reminderVariables[index] == 'Type') const Text('Advice or medication'),
                        if (reminderVariables[index] == 'Title') const Text('Enter a valid title'),
                        if (reminderVariables[index] == 'Description') const Text('Enter a valid description'),
                        if (reminderVariables[index] == 'Date') const Text('Say "Date" to set the date'),
                        if (reminderVariables[index] == 'Time') const Text('Say "Time" to set the time'),
                        if (reminderVariables[index] == 'Alarm' ||
                            reminderVariables[index] == 'Notification') const Text('Yes or no'),
                        const SizedBox(height: 10),
                      ],
                    );
                  },
                ),
              if (_isAppointment)
                ...List.generate(
                  appointmentVariables.length,
                  (index) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${appointmentVariables[index]}:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            // Highlight the variable name if spoken
                            color: appointmentVariableSpoken[index] ? Colors.green : Colors.black,
                          ),
                        ),
                        if (appointmentVariables[index] == 'Date')
                          const Text('Say "Date" to set the date'),
                        if (appointmentVariables[index] == 'Doctor')
                          const Text('Say the name of the doctor'),
                        if (appointmentVariables[index] == 'Specialty')
                          const Text('Say the specialty'),
                        if (appointmentVariables[index] == 'Time')
                          const Text('Say "Time" to set the time'),
                        const SizedBox(height: 10),
                      ],
                    );
                  },
                ),
                if (_isDevice) // Display "Existing list" text only if _isDevice is true
  const Text(
    "Existing list",
    style: TextStyle(fontSize: 22, color: Colors.indigo, fontWeight: FontWeight.bold),
  ),
if (_isDevice && deviceEntries.isNotEmpty) // Display the device list only if _isDevice is true and deviceEntries is not empty
  ...deviceEntries.map((device) => Card(
        elevation: 3,
        child: ListTile(
          leading: Icon(
            device['status'] == 'connected' ? Icons.check_circle : Icons.cancel,
            color: device['status'] == 'connected' ? Colors.green : Colors.red,
          ),
          title: Text(device['name'] ?? ''),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${device['iddevice'] ?? ''}'), // Update key to 'iddevice'
              Text('Status: ${device['status'] ?? ''}'),
            ],
          ),
          trailing: const Icon(Icons.more_vert),
          onTap: () {
            // Handle tapping on a device card
            print('Tapped on ${device['name']}');
          },
        ),
      )),

            ],
          ),
        ),
      ),
    );
  }

  void _openOptionsList() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: const Text('Set Reminder'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _isReminder = true;
                  _isAppointment = false;
                  _isDevice=false;
                });
                listen(); // Start listening for speech input
              },
            ),
            ListTile(
              title: const Text('Set Appointment'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _isAppointment = true;
                  _isReminder = false;
                  _isDevice=false;
                });
                listen(); // Start listening for speech input
              },
            ),
            ListTile(
              title: const Text('Set Home Devices'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _isReminder = false;
                  _isAppointment = false;
                  _isDevice=true;
                });
                listen(); // Start listening for speech input
              },
            ),
            ListTile(
              title: const Text('Emergency Call'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _isReminder = false;
                  _isAppointment = false;
                  _isDevice=false;

                });
                listen(); // Start listening for speech input
              },
            ),
          ],
        );
      },
    );
  }

  void listen() async {
    if (!isListening) {
      if (speech.isAvailable) {
        setState(() => isListening = true);
        speech.listen(
          onResult: (val) {
            // Update the txt variable with the recognized words
            setState(() {
              txt = val.recognizedWords;
              if (val.hasConfidenceRating && val.confidence > 0) {
                conf = val.confidence;
              }
            });

            // Process recognized words
            processRecognizedWords(val.recognizedWords);
            
            // Check if all variables are captured and stop listeningif so
            if (!isListening ) {
              stopListening();
            }
          },
        );
      } else {
        print('Speech recognition not available');
      }
    }
  }

  void stopListening() {
    if (isListening) {
      // Reset variableSpoken list to false
      if (_isReminder) {
        reminderVariableSpoken = List.filled(7, false);
      } else if (_isAppointment) {
        appointmentVariableSpoken = List.filled(4, false);
      }
      setState(() => isListening = false);
      speech.stop();
    }
  }

  void processRecognizedWords(String recognizedWords) {
    if (_isReminder) {
    // Handle reminder-specific logic
    Map<String, dynamic> entry = {
      'type': null,
      'title': null,
      'description': null,
      'date': null,
      'time': null,
      'alarm': null,
      'notification': null,
    };
try{
    for (int i = 0; i < reminderVariables.length; i++) {
      String parameter = reminderVariables[i];
      int parameterIndex = recognizedWords.toLowerCase().indexOf(parameter.toLowerCase());

      if (parameterIndex != -1) {
        setState(() {
          reminderVariableSpoken[i] = true;
        });
        // Extract data for the parameter
        String parameterData;
        int nextParameterIndex = (i + 1 < reminderVariables.length)
            ? recognizedWords.toLowerCase().indexOf(reminderVariables[i + 1].toLowerCase())
            : -1;

        if (nextParameterIndex == -1) {
          // If no next parameter is found, use the rest of the recognized words
          parameterData = recognizedWords.substring(parameterIndex + parameter.length).trim();
        } else {
          // If a next parameter is found, use the substring up to the next parameter name
          parameterData = recognizedWords.substring(parameterIndex + parameter.length, nextParameterIndex).trim();
        }

        // Process the extracted data
        if (parameterData.isNotEmpty) {
          if (parameter.toLowerCase() == 'type') {
            entry['type'] = parameterData.toLowerCase();
          } else if (parameter.toLowerCase() == 'title') {
            entry['title'] = parameterData;
          } else if (parameter.toLowerCase() == 'description') {
            entry['description'] = parameterData;
          } else if (parameter.toLowerCase() == 'date') {
              entry['date'] = parameterData;
            
          } else if (parameter.toLowerCase() == 'time') {
            if (parameterData.toLowerCase() == 'now') {
              // Set time to current time
              entry['time'] = TimeOfDay.now().format(context);
            } else {
              entry['time'] = parameterData;
            }
          } else if (parameter.toLowerCase() == 'alarm') {
            if (parameterData.toLowerCase() == 'yes' || parameterData.toLowerCase() == 'no') {
              entry['alarm'] = parameterData.toLowerCase();
            }
          } else if (parameter.toLowerCase() == 'notification') {
            if (parameterData.toLowerCase() == 'yes' || parameterData.toLowerCase() == 'no') {
              entry['notification'] = parameterData.toLowerCase();
            }
          }
        }
      }
    }
}catch(e){print('process problem : $e');}
try{
      // Check if all required data is captured
      bool allDataCaptured = entry['type'] != null &&
          entry['title'] != null &&
          entry['description'] != null &&
          entry['date'] != null &&
          entry['time'] != null &&
          (entry['alarm'] == 'yes' || entry['alarm'] == 'no') &&
          (entry['notification'] == 'yes' || entry['notification'] == 'no');

      if (allDataCaptured) {
        
        if (entry['type'] == 'medication') {
          setState(() {
            medicationEntries.add(entry);
             });
          print('Medication list : $medicationEntries');
          // ... (your existing code)
        } else if (entry['type'] == 'advice') {
          if (adviceEntries.isNotEmpty) {
            setState(() {
              adviceEntries.last['date'] = entry['date'];
            });
            print('Advice list : $adviceEntries');
          }
        }

        // Replace the text with the recognized data
        setState(() {
          txt = recognizedWords;
        });

        // Print the recognized words and extracted data for debugging
        print('Recognized words: $recognizedWords');
        print('Extracted data: $entry');
        print('-----------------------------------');

        // Stop listening if all required data is captured
        stopListening();
        convertData();
      }
      }catch (e){print(" all data captured has a problem : $e");}
    }
     else if (_isAppointment) {
    Map<String, dynamic> entry = {
      'uid': null,
      'date': null,
      'doctor': null,
      'specialty': null,
      'time': null,
    };

    bool allDataCaptured = false;

    try {
      for (int i = 0; i < appointmentVariables.length && !allDataCaptured; i++) {
        String parameter = appointmentVariables[i];
        int parameterIndex = recognizedWords.toLowerCase().indexOf(parameter.toLowerCase());

        if (parameterIndex != -1) {
          setState(() {
            appointmentVariableSpoken[i] = true;
          });

          // Extract data for the parameter
          String parameterData;
          int nextParameterIndex;
          if (i < appointmentVariables.length - 1) {
            nextParameterIndex = recognizedWords.toLowerCase().indexOf(appointmentVariables[i + 1].toLowerCase(), parameterIndex + parameter.length);
          } else {
            nextParameterIndex = recognizedWords.length;
          }

          if (nextParameterIndex == parameterIndex + parameter.length) {
            // If the next parameter is not found, set the nextParameterIndex to the end of the recognizedWords string
            nextParameterIndex = recognizedWords.length;
          }

          if (nextParameterIndex == -1) {
            // If no next parameter is found, use the rest of the recognized words
            parameterData = recognizedWords.substring(parameterIndex + parameter.length).trim();
          } else {
            // If a next parameter is found, use the substring up to the next parameter name
            parameterData = recognizedWords.substring(parameterIndex + parameter.length, nextParameterIndex).trim();
          }

          // Process the extracted data
          if (parameterData.isNotEmpty) {
            if (parameter.toLowerCase() == 'date') {
              entry['date'] = parameterData.toLowerCase();
            } else if (parameter.toLowerCase() == 'doctor') {
              entry['doctor'] = parameterData;
            } else if (parameter.toLowerCase() == 'specialty') {
              entry['specialty'] = parameterData;
            } else if (parameter.toLowerCase() == 'time') {
              if (parameterData.toLowerCase() == 'now') {
                // Set time to current time
                entry['time'] = TimeOfDay.now().format(context);
              } else {
                entry['time'] = parameterData.toLowerCase();
              }
            }
          }

          // Check if all required data is captured
          allDataCaptured = 
              entry['date'] != null &&
              entry['doctor'] != null &&
              entry['specialty'] != null &&
              entry['time'] != null;

          if (allDataCaptured) {
            setState(() {
              appointmentEntries.add(entry);
            });
            print('Appoitment list : $appointmentEntries');
            txt = recognizedWords;
            stopListening();
            convertData();
          }
        }
      }
    } catch (e) {
      print('process problem : $e');
    }

    print('Recognized words: $recognizedWords');
    print('Extracted data: $entry');
    print('-----------------------------------');
  }
}

 void convertData() {
    convertEntries();
    printUpdatedLists();
  }

  void printUpdatedLists() {
    print('Updated Medication list : $medicationEntries');
    print('Updated Advice list : $adviceEntries');
    print('Updated Appointment list : $appointmentEntries');
  }

  void convertEntries() {
  medicationEntries.forEach((entry) {
    // Convert time and date if needed
    String timeText = entry['time'];
    entry['time'] = _convertTime(timeText);

    String dateText = entry['date'];
    entry['date'] = _convertDate(dateText);
  });

  adviceEntries.forEach((entry) {
    // Convert time and date if needed
    String timeText = entry['time'];
    entry['time'] = _convertTime(timeText);

    String dateText = entry['date'];
    entry['date'] = _convertDate(dateText);
  });

  appointmentEntries.forEach((entry) {
    // Convert time and date if needed
    String timeText = entry['time'];
    entry['time'] = _convertTime(timeText);

    String dateText = entry['date'];
    entry['date'] = _convertDate(dateText);
  });
}

DateTime _convertDate(String dateText) {
  final now = DateTime.now();

  if (dateText.toLowerCase() == 'today') {
    return DateTime(now.year, now.month, now.day);
  } else if (dateText.toLowerCase() == 'tomorrow') {
    return DateTime(now.year, now.month, now.day + 1);
  } else if (dateText.toLowerCase().startsWith('next ')) {
    final day = dateText.substring(5).toLowerCase();
    final dayOfWeekIndex = DateFormat('EEEE').parse(day).weekday;
    final daysUntilNext = DateTime.daysPerWeek - dayOfWeekIndex + DateFormat('EEEE').parse(day).weekday;
    return now.add(Duration(days: daysUntilNext));
  } else {
    final dateRegex = RegExp(r'(\d{1,2})-(\d{1,2})-(\d{4})');
    final match = dateRegex.firstMatch(dateText);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      return DateTime(year, month, day);
    }
  }

  throw FormatException('Invalid date format');
}


String _convertTime(String timeText) {
  final timeRegex = RegExp(r'(\d{1,2}):(\d{2}) (AM|PM)');
  final match = timeRegex.firstMatch(timeText);
  if (match != null) {
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!;
    if (period == 'AM' && hour == 12) {
      return '${hour - 12}:${minute.toString().padLeft(2, '0')}';
    } else if (period == 'PM' && hour < 12) {
      return '${hour + 12}:${minute.toString().padLeft(2, '0')}';
    } else {
      return '$hour:${minute.toString().padLeft(2, '0')}';
    }
  }

  final timeRegex24 = RegExp(r'(\d{1,2}):(\d{2})');
  final match24 = timeRegex24.firstMatch(timeText);
  if (match24 != null) {
    final hour = int.parse(match24.group(1)!);
    final minute = int.parse(match24.group(2)!);
    return '$hour:${minute.toString().padLeft(2, '0')}';
  }

  throw FormatException('Invalid time format');
}
}