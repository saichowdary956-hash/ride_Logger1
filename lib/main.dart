import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

void main() {
  runApp(const DataLoggerApp());
}

class DataLoggerApp extends StatelessWidget {
  const DataLoggerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DataLogger',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667eea),
          brightness: Brightness.light,
        ),
      ),
      home: const LoggerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoggerScreen extends StatefulWidget {
  const LoggerScreen({Key? key}) : super(key: key);

  @override
  State<LoggerScreen> createState() => _LoggerScreenState();
}

class _LoggerScreenState extends State<LoggerScreen> {
  final TextEditingController driverCtrl = TextEditingController();
  final TextEditingController annotatorCtrl = TextEditingController();
  final TextEditingController vehicleCtrl = TextEditingController();
  final TextEditingController rsuNoCtrl = TextEditingController();
  final TextEditingController driveIdCtrl = TextEditingController();
  final TextEditingController commentsCtrl = TextEditingController();

  DateTime selectedDate = DateTime.now();
  String? activeCondition;
  String? activeCategory;
  int startTime = 0;
  Timer? timer;

  final Map<String, List<String>> categories = {
    'Weather': ['Sunny', 'Low Sun', 'Cloudy', 'Rain', 'Snow', 'Fog'],
    'Roadtype': ['City', 'Country', 'Highway', 'Construction site', 'Tunnel'],
    'Lighting': ['Day', 'Dawn', 'Dusk', 'Lit Night', 'Dark Night'],
    'Traffic': ['Flow', 'Jam'],
    'Speed': ['0-2mph', '3-18mph', '19-37mph', '38-55mph', '56-80mph', '81-155mph'],
  };

  Map<String, Map<String, int>> conditionData = {};

  @override
  void initState() {
    super.initState();
    _initializeConditions();
    _loadData();
  }

  void _initializeConditions() {
    categories.forEach((category, conditions) {
      conditionData[category] = {};
      for (var condition in conditions) {
        conditionData[category]![condition] = 0;
      }
    });
  }

  void toggleCondition(String category, String condition) {
    final isActive = activeCategory == category && activeCondition == condition;
    
    if (isActive) {
      _stopRecording();
    } else {
      if (activeCondition != null) {
        _stopRecording();
      }
      _startRecording(category, condition);
    }
  }

  void _startRecording(String category, String condition) {
    setState(() {
      activeCategory = category;
      activeCondition = condition;
      startTime = DateTime.now().millisecondsSinceEpoch;
    });
    
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _stopRecording() {
    if (activeCondition == null || activeCategory == null) return;
    
    timer?.cancel();
    final elapsed = ((DateTime.now().millisecondsSinceEpoch - startTime) / 1000).floor();
    
    setState(() {
      conditionData[activeCategory!]![activeCondition!] = 
          (conditionData[activeCategory!]![activeCondition!] ?? 0) + elapsed;
      activeCategory = null;
      activeCondition = null;
    });
    
    _saveData();
  }

  void resetCategory(String category) {
    if (activeCategory == category) {
      _stopRecording();
    }
    
    setState(() {
      categories[category]!.forEach((condition) {
        conditionData[category]![condition] = 0;
      });
    });
    
    _saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$category reset successfully')),
    );
  }

  void stopAll() {
    _stopRecording();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All recording stopped')),
    );
  }

  void exportCSV() {
    final StringBuffer csv = StringBuffer();
    csv.writeln('DataLogger Report');
    csv.writeln('Driver,${driverCtrl.text}');
    csv.writeln('Annotator,${annotatorCtrl.text}');
    csv.writeln('Date,${DateFormat('yyyy-MM-dd').format(selectedDate)}');
    csv.writeln('Vehicle,${vehicleCtrl.text}');
    csv.writeln('RSU No,${rsuNoCtrl.text}');
    csv.writeln('Drive ID,${driveIdCtrl.text}');
    csv.writeln('Comments,"${commentsCtrl.text.replaceAll('"', '""')}"');
    csv.writeln('');
    csv.writeln('Category,Condition,Time (seconds),Time (minutes)');

    categories.forEach((category, conditions) {
      for (var condition in conditions) {
        final seconds = conditionData[category]![condition] ?? 0;
        final minutes = (seconds / 60).toStringAsFixed(2);
        csv.writeln('$category,$condition,$seconds,$minutes');
      }
    });

    final filename = 'DataLogger_${DateFormat('yyyy-MM-dd').format(selectedDate)}_${DateTime.now().millisecondsSinceEpoch}.csv';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV exported: $filename'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}m ${secs}s';
  }

  int _getCurrentTime(String category, String condition) {
    final baseTime = conditionData[category]![condition] ?? 0;
    if (activeCategory == category && activeCondition == condition) {
      final elapsed = ((DateTime.now().millisecondsSinceEpoch - startTime) / 1000).floor();
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
      'comments': commentsCtrl.text,
      'conditionData': conditionData.map((cat, conditions) => 
        MapEntry(cat, conditions.map((cond, time) => MapEntry(cond, time)))),
    };
    await prefs.setString('dataLoggerData', jsonEncode(data));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('dataLoggerData');
    if (stored != null) {
      try {
        final data = jsonDecode(stored) as Map<String, dynamic>;
        setState(() {
          driverCtrl.text = data['driver'] ?? '';
          annotatorCtrl.text = data['annotator'] ?? '';
          vehicleCtrl.text = data['vehicle'] ?? '';
          rsuNoCtrl.text = data['rsuNo'] ?? '';
          driveIdCtrl.text = data['driveId'] ?? '';
          commentsCtrl.text = data['comments'] ?? '';
          if (data['date'] != null) {
            selectedDate = DateTime.parse(data['date']);
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
        title: const Text('🚗 DataLogger'),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Details Card
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Session Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildTextField('Driver', driverCtrl),
                    _buildTextField('Annotator', annotatorCtrl),
                    _buildTextField('Vehicle', vehicleCtrl),
                    _buildTextField('RSU No', rsuNoCtrl),
                    _buildTextField('Drive ID', driveIdCtrl),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                          _saveData();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Recording Conditions
            const Text('Recording Conditions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            ...categories.entries.map((entry) {
              final category = entry.key;
              final conditions = entry.value;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF667eea),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => resetCategory(category),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Reset'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...conditions.map((condition) {
                    final isActive = activeCategory == category && activeCondition == condition;
                    final timeInSeconds = _getCurrentTime(category, condition);
                    final displayTime = _formatTime(timeInSeconds);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: isActive ? 4 : 1,
                      color: isActive ? Colors.red.shade50 : null,
                      child: ListTile(
                        dense: true,
                        title: Text(
                          condition,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          displayTime,
                          style: TextStyle(
                            color: isActive ? Colors.red.shade700 : Colors.grey.shade700,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => toggleCondition(category, condition),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isActive ? Colors.red : const Color(0xFF667eea),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Text(isActive ? 'Stop' : 'Start'),
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),

            // Comments
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Comments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: commentsCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Enter comments here...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _saveData(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Control Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: stopAll,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: exportCSV,
                    icon: const Icon(Icons.download),
                    label: const Text('Export CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
        ),
        onChanged: (value) => _saveData(),
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
    commentsCtrl.dispose();
    super.dispose();
  }
}
