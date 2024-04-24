import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
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
  List<Map<String, dynamic>> medicationEntries = [];
  List<Map<String, dynamic>> adviceEntries = [];

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
        duration: Duration(milliseconds: 2000),
        repeat: true,
        child: FloatingActionButton(
          onPressed: _openOptionsList,
          child: Icon(isListening ? Icons.mic : Icons.mic_none),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.fromLTRB(30, 30, 30, 150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                txt,
                style: TextStyle(
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
                        if (reminderVariables[index] == 'Type') Text('Advice or medication'),
                        if (reminderVariables[index] == 'Title') Text('Enter a valid title'),
                        if (reminderVariables[index] == 'Description') Text('Enter a valid description'),
                        if (reminderVariables[index] == 'Date') Text('Say "Date" to set the date'),
                        if (reminderVariables[index] == 'Time') Text('Say "Time" to set the time'),
                        if (reminderVariables[index] == 'Alarm' || reminderVariables[index] == 'Notification')
                          Text('Yes or no'),
                        SizedBox(height: 10),
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
                        if (appointmentVariables[index] == 'Date') Text('Say "Date" to set the date'),
                        if (appointmentVariables[index] == 'Doctor') Text('Say the name of the doctor'),
                        if (appointmentVariables[index] == 'Specialty') Text('Say the specialty'),
                        if (appointmentVariables[index] == 'Time') Text('Say "Time" to set the time'),
                        SizedBox(height: 10),
                      ],
                    );
                  },
                ),
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
              title: Text('Set Reminder'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _isReminder = true;
                  _isAppointment = false;
                });
                listen(); // Start listening for speech input
              },
            ),
            ListTile(
              title: Text('Set Appointment'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _isAppointment = true;
                  _isReminder = false;
                });
                listen(); // Start listening for speech input
              },
            ),
            ListTile(
              title: Text('Set Home Devices'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _isReminder = false;
                  _isAppointment = false;
                });
                listen(); // Start listening for speech input
              },
            ),
            ListTile(
              title: Text('Emergency Call'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _isReminder = false;
                  _isAppointment = false;
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

            // Stop listening if all required data is captured
            if ((_isReminder || _isAppointment) && allVariablesCaptured()) {
              stopListening();
            }
          },
          localeId: 'en_US', // Set language to English
        );
      } else {
        print('Speech recognition not available');
      }
    } else {
      setState(() => isListening = false);
      speech.stop();
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

  bool allVariablesCaptured() {
    // Check if all reminder or appointment variables have been captured
    if (_isReminder) {
      return reminderVariableSpoken.every((spoken) => spoken);
    } else if (_isAppointment) {
      return appointmentVariableSpoken.every((spoken) => spoken);
    }
    return false;
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
            if (parameterData.toLowerCase() == 'date') {
              if (adviceEntries.isNotEmpty) {
                _selectDate();
              }
              return; // Stop processing other parameters until the date is selected
            } else {
              entry['date'] = parameterData;
            }
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

    // Check if all required data is captured
    if (allVariablesCaptured()) {
      // Add entry to the medication or advice list based on type
      if (entry['type'] == 'medication') {
        setState(() {
          medicationEntries.add(entry);
        });
        print('Medication list : $medicationEntries');
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
    }
  } else if (_isAppointment) {
    // Handle appointment-specific logic
    Map<String, dynamic> entry = {
      'date': null,
      'doctor': null,
      'specialty': null,
      'time': null,
    };

    for (int i = 0; i < appointmentVariables.length; i++) {
      String parameter = appointmentVariables[i];
      int parameterIndex = recognizedWords.toLowerCase().indexOf(parameter.toLowerCase());

      if (parameterIndex != -1) {
        setState(() {
          appointmentVariableSpoken[i] = true;
        });

        String parameterData;
        int nextParameterIndex = (i + 1 < appointmentVariables.length)
            ? recognizedWords.toLowerCase().indexOf(appointmentVariables[i + 1].toLowerCase())
            : -1;

        if (nextParameterIndex == -1) {
          parameterData = recognizedWords.substring(parameterIndex + parameter.length).trim();
        } else {
          parameterData = recognizedWords.substring(parameterIndex + parameter.length, nextParameterIndex).trim();
        }

        if (parameterData.isNotEmpty) {
          if (parameter.toLowerCase() == 'date') {
            if (parameterData.toLowerCase() == 'date') {
              _selectDate();
              return; // Stop processing other parameters until the date is selected
            } else {
              entry['date'] = parameterData;
            }
          } else if (parameter.toLowerCase() == 'doctor' || parameter.toLowerCase() == 'dr') {
            entry['doctor'] = parameterData;
          } else if (parameter.toLowerCase() == 'specialty') {
            entry['specialty'] = parameterData;
          } else if (parameter.toLowerCase() == 'time') {
            if (parameterData.toLowerCase() == 'now') {
              // Set time to current time
              entry['time'] = TimeOfDay.now().format(context);
            } else {
              entry['time'] = parameterData;
            }
          }
        }
      }
    }

    // Check if all required data is captured
    if (allVariablesCaptured()) {
      setState(() {
        txt = recognizedWords;
      });

      print('Recognized words: $recognizedWords');
      print('Extracted data: $entry');
      print('-----------------------------------');

      stopListening();
    }
  }
}

  Future<void> _selectDate() async {
  DateTime? pickedDate;
  TimeOfDay? pickedTime;
  String command = '';

  // Check if the user spoke a command related to the date
  if (_isReminder) {
    int commandIndex = reminderVariables.indexOf('Date');
    if (commandIndex != -1 && reminderVariableSpoken[commandIndex]) {
      String recognizedWords = txt.toLowerCase();
      int commandStartIndex = recognizedWords.indexOf('date') + 4;
      int commandEndIndex = recognizedWords.indexOf('to');
      if (commandEndIndex == -1) {
        commandEndIndex = recognizedWords.length;
      }
      command = recognizedWords.substring(commandStartIndex, commandEndIndex).trim();
    }
  }

  // Determine the initial date based on the spoken command
  if (command.contains('today')) {
    pickedDate = DateTime.now();
  } else if (command.contains('tomorrow')) {
    pickedDate = DateTime.now().add(Duration(days: 1));
  } else if (command.contains('next')) {
    // Logic for picking the next day of the week
    // ...
  } else {
    pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
    );
  }

  // If the user selected a date, prompt for time selection
  if (pickedDate != null) {
    pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
  }

  // If the user selected both date and time, update the UI and spoken variables
  if (pickedDate != null && pickedTime != null) {
    // Combine date and time
    pickedDate = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      // Format date as yyyy-MM-dd
      String formattedDate = '${pickedDate!.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
      txt = 'Date selected: $formattedDate, Time selected: ${pickedTime!.format(context)}';
      if (_isReminder) {
        medicationEntries.last['date'] = formattedDate;
        medicationEntries.last['time'] = pickedTime.format(context);
        reminderVariableSpoken[3] = true; // Date
        reminderVariableSpoken[4] = true; // Time
      } else if (_isAppointment) {
        adviceEntries.last['date'] = formattedDate;
        adviceEntries.last['time'] = pickedTime.format(context);
        appointmentVariableSpoken[0] = true; // Date
        appointmentVariableSpoken[3] = true; // Time
      }
    });

    // Print the selected date and time and the updated list
    print('Selected date: $pickedDate, Selected time: $pickedTime');
    print('Medication entries: $medicationEntries');
    print('Advice entries: $adviceEntries');
  }
}


  DateTime _getNextDay(String command) {
    DateTime now = DateTime.now();
    int dayIndex = -1;

    if (command.contains('monday')) {
      dayIndex = 1;
    } else if (command.contains('tuesday')) {
      dayIndex = 2;
    } else if (command.contains('wednesday')) {
      dayIndex = 3;
    } else if (command.contains('thursday')) {
      dayIndex = 4;
    } else if (command.contains('friday')) {
      dayIndex = 5;
    } else if (command.contains('saturday')) {
      dayIndex = 6;
    } else if (command.contains('sunday')) {
      dayIndex = 7;
    }

    int daysUntilNext = dayIndex - now.weekday;
    if (daysUntilNext <= 0) {
      daysUntilNext += 7;
    }

    return now.add(Duration(days: daysUntilNext));
  }

  String _formatTime(int hour, int minute) {
    String hourStr = hour.toString().padLeft(2, '0');
    String minuteStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }
}
