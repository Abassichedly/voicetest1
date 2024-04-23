import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class Home extends StatefulWidget {
  const Home({Key? key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String txt = '1) Choose an options \n 2) Please say the name of the parameter and then the correct data';
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

  void listen() async {
    if (!isListening) {
      if (speech.isAvailable) {
        setState(() => isListening = true);
        speech.listen(
          onResult: (val) {
            setState(() {
              txt = val.recognizedWords;
              if (val.hasConfidenceRating && val.confidence > 0) {
                conf = val.confidence;
              }
            });

            if (_isReminder) {
              processReminderRecognizedWords(val.recognizedWords);
              if (allReminderVariablesCaptured()) {
                stopListening();
              }
            } else if (_isAppointment) {
              processAppointmentRecognizedWords(val.recognizedWords);
              if (allAppointmentVariablesCaptured()) {
                stopListening();
              }
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
      if (_isReminder) {
        setState(() {
          reminderVariableSpoken = List.filled(7, false);
        });
      } else if (_isAppointment) {
        setState(() {
          appointmentVariableSpoken = List.filled(4, false);
        });
      }
      setState(() => isListening = false);
      speech.stop();
    }
  }

  bool allReminderVariablesCaptured() {
    return reminderVariableSpoken.every((spoken) => spoken);
  }

  bool allAppointmentVariablesCaptured() {
    return appointmentVariableSpoken.every((spoken) => spoken);
  }

  void processReminderRecognizedWords(String recognizedWords) {
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

        String parameterData;
        int nextParameterIndex = (i + 1 < reminderVariables.length)
            ? recognizedWords.toLowerCase().indexOf(reminderVariables[i + 1].toLowerCase())
            : -1;

        if (nextParameterIndex == -1) {
          parameterData = recognizedWords.substring(parameterIndex + parameter.length).trim();
        } else {
          parameterData = recognizedWords.substring(parameterIndex + parameter.length, nextParameterIndex).trim();
        }

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
            entry['time'] = parameterData;
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

    if (allReminderVariablesCaptured()) {
      if (entry['type'] == 'medication') {
        setState(() {
          medicationEntries.add(entry);
        });
        print('Medication list : $medicationEntries');
      } else if (entry['type'] == 'advice') {
        setState(() {
          adviceEntries.add(entry);
        });
        print('Advice list : $adviceEntries');
      }

      setState(() {
        txt = recognizedWords;
      });

      print('Recognized words: $recognizedWords');
      print('Extracted data: $entry');
      print('-----------------------------------');
    }
  }

  void processAppointmentRecognizedWords(String recognizedWords) {
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
            entry['date'] = parameterData;
          } else if (parameter.toLowerCase() == 'doctor') {
            entry['doctor'] = parameterData;
          } else if (parameter.toLowerCase() == 'specialty') {
            entry['specialty'] = parameterData;
          } else if (parameter.toLowerCase() == 'time') {
            entry['time'] = parameterData;
          }
        }
      }
    }

    if (allAppointmentVariablesCaptured()) {
      setState(() {
        txt = recognizedWords;
      });

      print('Recognized words: $recognizedWords');
      print('Extracted data: $entry');
      print('-----------------------------------');
    }
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
              if (_isReminder || _isAppointment)
                ...List.generate(
                  _isReminder ? reminderVariables.length : appointmentVariables.length,
                  (index) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_isReminder ? reminderVariables[index] : appointmentVariables[index]}:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            // Highlight the variable name if spoken
                            color: _isReminder ? reminderVariableSpoken[index] ? Colors.green : Colors.black : appointmentVariableSpoken[index] ? Colors.green : Colors.black,
                          ),
                        ),
                        if (_isReminder)
                          if (reminderVariables[index] == 'Type') Text('Advice or medication'),
                          if (reminderVariables[index] == 'Title') Text('Enter a valid title'),
                          if (reminderVariables[index] == 'Description') Text('Enter a valid description'),
                          if (reminderVariables[index] == 'Date') Text('Say "Date" to set the date'),
                          if (reminderVariables[index] == 'Time') Text('Say "Time" to set the time'),
                          if (reminderVariables[index] == 'Alarm' || reminderVariables[index] == 'Notification')
                            Text('Yes or no'),
                        if (_isAppointment)
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
}
