import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

void main() {
  runApp(const RideLoggerApp());
}

class RideLoggerApp extends StatelessWidget {
  const RideLoggerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '🚗 Ride Data Logger',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667eea),
          brightness: Brightness.light,
        ),
      ),
      home: const RideLoggerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RideLoggerScreen extends StatefulWidget {
  const RideLoggerScreen({Key? key}) : super(key: key);

  @override
  State<RideLoggerScreen> createState() => _RideLoggerScreenState();
}

class _RideLoggerScreenState extends State<RideLoggerScreen> {
  final TextEditingController driverCtrl = TextEditingController();
  final TextEditingController annotatorCtrl = TextEditingController();
  final TextEditingController vehicleCtrl = TextEditingController();
  final TextEditingController rsuNoCtrl = TextEditingController();
  final TextEditingController driveIdCtrl = TextEditingController();

  DateTime selectedDate = DateTime.now();
  DateTime? rsuStartDate;
  
  Map<String, String?> activeConditions = {};
  Map<String, int> startTimes = {};
  int? sessionStartTime;
  Timer? timer;
  bool notified30 = false;
  bool notified40 = false;

  final Map<String, List<String>> categories = {
    'Weather': ['Sunny', 'Low Sun', 'Cloudy', 'Rain', 'Fog', 'Snow'],
    'Road Type': ['City', 'Country', 'Highway', 'Construction Site', 'Tunnel'],
    'Lighting': ['Day', 'Dawn', 'Lit Night', 'Dark Night'],
    'Traffic': ['Flow', 'Jam'],
    'Speed': ['0-2 mph', '3-18 mph', '19-37 mph', '38-55 mph', '56-80 mph', '81-155 mph'],
  };

  Map<String, Map<String, int>> conditionData = {};

  @override
  void initState() {
    super.initState();
    _initializeConditions();
    _loadData();
    _startTimer();
  }

  void _initializeConditions() {
    categories.forEach((category, conditions) {
      conditionData[category] = {};
      for (var condition in conditions) {
        conditionData[category]![condition] = 0;
      }
    });
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted && activeConditions.isNotEmpty) {
        setState(() {});
        _checkNotifications();
      }
    });
  }

  void _checkNotifications() {
    if (sessionStartTime == null) return;

    final sessionMinutes = ((DateTime.now().millisecondsSinceEpoch - sessionStartTime!) / 60000).floor();

    if (sessionMinutes >= 30 && !notified30) {
      notified30 = true;
      _showNotification('⏰ 30 minutes reached!', Colors.yellow.shade700);
    }

    if (sessionMinutes >= 40 && !notified40) {
      notified40 = true;
      _showNotification('⏰ 40 minutes reached!', Colors.red);
    }
  }

  void _showNotification(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void toggleCondition(String category, String condition) {
    final isActive = activeConditions[category] == condition;
    
    if (isActive) {
      _stopRecording(category);
    } else {
      if (activeConditions[category] != null) {
        _stopRecording(category);
      }
      _startRecording(category, condition);
    }
  }

  void _startRecording(String category, String condition) {
    setState(() {
      activeConditions[category] = condition;
      startTimes[category] = DateTime.now().millisecondsSinceEpoch;
      
      if (sessionStartTime == null) {
        sessionStartTime = DateTime.now().millisecondsSinceEpoch;
      }
    });
  }

  void _stopRecording(String category) {
    final condition = activeConditions[category];
    if (condition == null) return;
    
    final elapsed = DateTime.now().millisecondsSinceEpoch - startTimes[category]!;
    
    setState(() {
      conditionData[category]![condition] = 
          (conditionData[category]![condition] ?? 0) + elapsed;
      activeConditions.remove(category);
      startTimes.remove(category);
    });
    
    _saveData();
  }

  void resetCategory(String category) {
    if (activeConditions.containsKey(category)) {
      _stopRecording(category);
    }
    
    setState(() {
      categories[category]!.forEach((condition) {
        conditionData[category]![condition] = 0;
      });
    });
    
    _saveData();
  }

  void stopAll() {
    final categoriesToStop = activeConditions.keys.toList();
    for (var category in categoriesToStop) {
      _stopRecording(category);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All recording stopped')),
    );
  }

  void exportCSV() {
    final StringBuffer csv = StringBuffer();
    
    csv.writeln('Ride Data Logger Report');
    csv.writeln('');
    csv.writeln('Driver,${driverCtrl.text}');
    csv.writeln('Annotator,${annotatorCtrl.text}');
    csv.writeln('Date,${DateFormat('yyyy-MM-dd').format(selectedDate)}');
    csv.writeln('Vehicle,${vehicleCtrl.text}');
    csv.writeln('RSU NO,${rsuNoCtrl.text}');
    csv.writeln('R S U Start Date,${rsuStartDate != null ? DateFormat('yyyy-MM-dd').format(rsuStartDate!) : ''}');
    csv.writeln('Drive Id,${driveIdCtrl.text}');
    csv.writeln('');
    csv.writeln('Category,Condition,Time (mm:ss),Time (seconds)');

    categories.forEach((category, conditions) {
      for (var condition in conditions) {
        int ms = conditionData[category]![condition] ?? 0;
        
        if (activeConditions[category] == condition && startTimes.containsKey(category)) {
          final elapsed = DateTime.now().millisecondsSinceEpoch - startTimes[category]!;
          ms += elapsed;
        }
        
        final seconds = (ms / 1000).floor();
        csv.writeln('$category,$condition,${_formatTime(ms)},$seconds');
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV data ready (clipboard copy feature pending)'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  String _formatTime(int ms) {
    final totalSeconds = (ms / 1000).floor();
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  int _getCurrentTime(String category, String condition) {
    final baseTime = conditionData[category]![condition] ?? 0;
    if (activeConditions[category] == condition && startTimes.containsKey(category)) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - startTimes[category]!;
      return baseTime + elapsed;
    }
    return baseTime;
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'driver': driverCtrl.text,
      'annotator': annotatorCtrl.text,
      'vehicle': vehicleCtrl.text,
      'rsuNo': rsuNoCtrl.text,
      'driveId': driveIdCtrl.text,
      'date': selectedDate.toIso8601String(),
      'rsuStartDate': rsuStartDate?.toIso8601String(),
      'sessionStartTime': sessionStartTime,
      'conditionData': conditionData.map((cat, conditions) => 
        MapEntry(cat, conditions.map((cond, time) => MapEntry(cond, time)))),
    };
    await prefs.setString('rideLoggerData', jsonEncode(data));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('rideLoggerData');
    if (stored != null) {
      try {
        final data = jsonDecode(stored) as Map<String, dynamic>;
        setState(() {
          driverCtrl.text = data['driver'] ?? '';
          annotatorCtrl.text = data['annotator'] ?? '';
          vehicleCtrl.text = data['vehicle'] ?? '';
          rsuNoCtrl.text = data['rsuNo'] ?? '';
          driveIdCtrl.text = data['driveId'] ?? '';
          
          if (data['date'] != null) {
            selectedDate = DateTime.parse(data['date']);
          }
          if (data['rsuStartDate'] != null) {
            rsuStartDate = DateTime.parse(data['rsuStartDate']);
          }
          if (data['sessionStartTime'] != null) {
            sessionStartTime = data['sessionStartTime'];
          }
          if (data['conditionData'] != null) {
            final savedData = data['conditionData'] as Map<String, dynamic>;
            savedData.forEach((cat, conditions) {
              if (conditionData.containsKey(cat)) {
                (conditions as Map<String, dynamic>).forEach((cond, time) {
                  conditionData[cat]![cond] = time as int;
                });
              }
            });
          }
        });
      } catch (e) {
        debugPrint('Error loading data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚗 Ride Data Logger'),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTextField('Driver', driverCtrl),
                    _buildTextField('Annotator', annotatorCtrl),
                    _buildDateField('Date', selectedDate, (date) {
                      setState(() => selectedDate = date);
                      _saveData();
                    }),
                    _buildTextField('Vehicle', vehicleCtrl),
                    _buildTextField('RSU NO', rsuNoCtrl),
                    _buildDateField('R S U Start Date', rsuStartDate ?? DateTime.now(), (date) {
                      setState(() => rsuStartDate = date);
                      _saveData();
                    }),
                    _buildTextField('Drive Id', driveIdCtrl),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Data Table
            Card(
              elevation: 3,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    const Color(0xFF667eea).withOpacity(0.9),
                  ),
                  columns: const [
                    DataColumn(label: Text('Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Condition', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ],
                  rows: _buildTableRows(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Control Buttons
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ...categories.keys.map((cat) => ElevatedButton(
                  onPressed: () => resetCategory(cat),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Reset $cat'),
                )),
                ElevatedButton.icon(
                  onPressed: stopAll,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: exportCSV,
                  icon: const Icon(Icons.folder),
                  label: const Text('Export CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<DataRow> _buildTableRows() {
    List<DataRow> rows = [];
    
    categories.forEach((category, conditions) {
      for (var condition in conditions) {
        final isActive = activeConditions[category] == condition;
        final timeMs = _getCurrentTime(category, condition);
        
        rows.add(DataRow(
          color: MaterialStateProperty.all(
            isActive ? Colors.yellow.shade100 : Colors.white,
          ),
          cells: [
            DataCell(Text(
              category,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF667eea)),
            )),
            DataCell(Text(condition)),
            DataCell(Text(
              _formatTime(timeMs),
              style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold),
            )),
            DataCell(ElevatedButton(
              onPressed: () => toggleCondition(category, condition),
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? Colors.red : const Color(0xFF667eea),
                foregroundColor: Colors.white,
              ),
              child: Text(isActive ? 'Stop' : 'Start'),
            )),
          ],
        ));
      }
    });
    
    return rows;
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (value) => _saveData(),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime date, Function(DateTime) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2000),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) {
            onChanged(picked);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 20),
              const SizedBox(width: 8),
              Text('$label: ${DateFormat('yyyy-MM-dd').format(date)}'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    driverCtrl.dispose();
    annotatorCtrl.dispose();
    vehicleCtrl.dispose();
    rsuNoCtrl.dispose();
    driveIdCtrl.dispose();
    super.dispose();
  }
}
