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
  final TextEditingController rsuStorageCtrl = TextEditingController();

  DateTime startDate = DateTime.now();
  DateTime rsuStartDate = DateTime.now();
  Map<String, String?> activeConditions = {}; // Track active condition per category
  Map<String, int> startTimes = {}; // Track start time per category
  Timer? timer;
  int lastNotificationMinute = 0;
  
  // Session recording time
  DateTime? sessionStartTime;
  DateTime? sessionEndTime;
  bool isSessionActive = false;
  bool hasShown30MinNotification = false;

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
        _checkTimeNotification();
      }
    });
  }

  void _checkTimeNotification() {
    // Check actual session time (not sum of conditions)
    int sessionSeconds = _getSessionTime();
    int sessionMinutes = sessionSeconds ~/ 60;

    // Show notification at 30 minutes
    if (sessionMinutes >= 30 && !hasShown30MinNotification) {
      hasShown30MinNotification = true;
      _showTimeAlert(sessionMinutes);
    }
  }

  void _showTimeAlert(int minutes) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.alarm, color: Colors.black87, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '⏰ Session Time: $minutes Minutes Reached!',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.yellow.shade600,
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  int _calculateTotalSessionTime() {
    int total = 0;
    conditionData.forEach((category, conditions) {
      conditions.forEach((condition, time) {
        total += time;
      });
    });

    // Add current active recordings
    activeConditions.forEach((category, condition) {
      if (condition != null && startTimes.containsKey(category)) {
        final elapsed = ((DateTime.now().millisecondsSinceEpoch - startTimes[category]!) / 1000).floor();
        total += elapsed;
      }
    });

    return total;
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
      // Start session time if first recording
      if (!isSessionActive) {
        sessionStartTime = DateTime.now();
        sessionEndTime = null; // Clear previous end time
        isSessionActive = true;
        hasShown30MinNotification = false; // Reset notification flag
      }
      
      activeConditions[category] = condition;
      startTimes[category] = DateTime.now().millisecondsSinceEpoch;
    });
  }

  void _stopRecording(String category) {
    final condition = activeConditions[category];
    if (condition == null) return;
    
    final elapsed = ((DateTime.now().millisecondsSinceEpoch - startTimes[category]!) / 1000).floor();
    
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$category reset successfully')),
    );
  }

  void stopAll() {
    final categoriesToStop = activeConditions.keys.toList();
    for (var category in categoriesToStop) {
      _stopRecording(category);
    }
    
    setState(() {
      // Stop session recording and save end time
      if (isSessionActive && sessionStartTime != null) {
        sessionEndTime = DateTime.now();
      }
      isSessionActive = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All recording stopped')),
    );
  }

  void exportCSV() {
    final StringBuffer csv = StringBuffer();
    final totalSeconds = _getSessionTime();
    final totalMinutes = (totalSeconds / 60).toStringAsFixed(2);
    
    csv.writeln('DataLogger Report');
    csv.writeln('Driver,${driverCtrl.text}');
    csv.writeln('Annotator,${annotatorCtrl.text}');
    csv.writeln('Start Date,${DateFormat('yyyy-MM-dd').format(startDate)}');
    csv.writeln('RSU Start Date,${DateFormat('yyyy-MM-dd').format(rsuStartDate)}');
    csv.writeln('Vehicle,${vehicleCtrl.text}');
    csv.writeln('RSU No,${rsuNoCtrl.text}');
    csv.writeln('RSU Storage,${rsuStorageCtrl.text}%');
    csv.writeln('Drive ID,${driveIdCtrl.text}');
    csv.writeln('Overall Session Time,${_formatTime(totalSeconds)} ($totalMinutes minutes)');
    csv.writeln('Comments,"${commentsCtrl.text.replaceAll('"', '""')}"');
    csv.writeln('');
    csv.writeln('Category,Condition,Time (seconds),Time (minutes)');

    categories.forEach((category, conditions) {
      for (var condition in conditions) {
        int seconds = conditionData[category]![condition] ?? 0;
        
        // Add current elapsed if active
        if (activeConditions[category] == condition && startTimes.containsKey(category)) {
          final elapsed = ((DateTime.now().millisecondsSinceEpoch - startTimes[category]!) / 1000).floor();
          seconds += elapsed;
        }
        
        final minutes = (seconds / 60).toStringAsFixed(2);
        csv.writeln('$category,$condition,$seconds,$minutes');
      }
    });

    final filename = 'DataLogger_${DateFormat('yyyy-MM-dd').format(DateTime.now())}_${DateTime.now().millisecondsSinceEpoch}.csv';
    
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
  
  int _getSessionTime() {
    if (sessionStartTime == null) return 0;
    
    // If session is active, calculate up to now
    if (isSessionActive) {
      return DateTime.now().difference(sessionStartTime!).inSeconds;
    }
    
    // If session stopped, use stored end time
    if (sessionEndTime != null) {
      return sessionEndTime!.difference(sessionStartTime!).inSeconds;
    }
    
    return 0;
  }

  int _getCurrentTime(String category, String condition) {
    final baseTime = conditionData[category]![condition] ?? 0;
    if (activeConditions[category] == condition && startTimes.containsKey(category)) {
      final elapsed = ((DateTime.now().millisecondsSinceEpoch - startTimes[category]!) / 1000).floor();
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
      'rsuStorage': rsuStorageCtrl.text,
      'startDate': startDate.toIso8601String(),
      'rsuStartDate': rsuStartDate.toIso8601String(),
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
          rsuStorageCtrl.text = data['rsuStorage'] ?? '';
          commentsCtrl.text = data['comments'] ?? '';
          if (data['startDate'] != null) {
            startDate = DateTime.parse(data['startDate']);
          }
          if (data['rsuStartDate'] != null) {
            rsuStartDate = DateTime.parse(data['rsuStartDate']);
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
        title: const Text(
          '🚗 DataLogger',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        elevation: 4,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade600, Colors.indigo.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Details Card
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade50, Colors.blue.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.purple.shade600, Colors.indigo.shade600],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.settings, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'Session Details',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF667eea),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _buildTextField('Driver', driverCtrl),
                      _buildTextField('Annotator', annotatorCtrl),
                      _buildTextField('Vehicle', vehicleCtrl),
                      _buildTextField('RSU No', rsuNoCtrl),
                      _buildTextField('Drive ID', driveIdCtrl),
                      
                      // RSU Storage with icon
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          controller: rsuStorageCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'RSU Storage Used (%)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            isDense: true,
                            suffixText: '%',
                            prefixIcon: Icon(Icons.storage, color: Colors.purple.shade600),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (value) => _saveData(),
                        ),
                      ),
                      
                      // Start Date
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => startDate = picked);
                            _saveData();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.orange.shade400, Colors.deepOrange.shade500],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.shade300,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 24, color: Colors.white),
                              const SizedBox(width: 12),
                              Text(
                                'Start Date: ${DateFormat('yyyy-MM-dd').format(startDate)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // RSU Start Date
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: rsuStartDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => rsuStartDate = picked);
                            _saveData();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.teal.shade400, Colors.cyan.shade500],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.shade300,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 24, color: Colors.white),
                              const SizedBox(width: 12),
                              Text(
                                'RSU Start Date: ${DateFormat('yyyy-MM-dd').format(rsuStartDate)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recording Conditions Header - Colorful
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink.shade400, Colors.orange.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.play_circle_filled, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Recording Conditions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            ...categories.entries.map((entry) {
              final category = entry.key;
              final conditions = entry.value;
              
              // Assign unique gradient colors per category
              final Map<String, List<Color>> categoryColors = {
                'Weather': [Colors.blue.shade500, Colors.lightBlue.shade400],
                'Roadtype': [Colors.green.shade500, Colors.teal.shade400],
                'Lighting': [Colors.amber.shade500, Colors.orange.shade400],
                'Traffic': [Colors.red.shade500, Colors.pink.shade400],
                'Speed': [Colors.purple.shade500, Colors.deepPurple.shade400],
              };
              
              final colors = categoryColors[category] ?? [Colors.grey.shade500, Colors.grey.shade400];
              
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Header with gradient
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: colors,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => resetCategory(category),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reset'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: colors[0],
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Conditions List
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          ...conditions.map((condition) {
                    final isActive = activeConditions[category] == condition;
                    final timeInSeconds = _getCurrentTime(category, condition);
                    final displayTime = _formatTime(timeInSeconds);

                    return InkWell(
                      onTap: () => toggleCondition(category, condition),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.red.shade50 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive ? Colors.red.shade400 : Colors.grey.shade300,
                            width: isActive ? 2 : 1,
                          ),
                          boxShadow: isActive ? [
                            BoxShadow(
                              color: Colors.red.shade200,
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 3),
                            ),
                          ] : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                condition,
                                style: TextStyle(
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 16,
                                  color: isActive ? Colors.red.shade900 : Colors.black87,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                if (isActive)
                                  Icon(
                                    Icons.radio_button_checked,
                                    color: Colors.red.shade700,
                                    size: 20,
                                  ),
                                if (isActive) const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.red.shade100 : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isActive ? Colors.red.shade600 : Colors.grey.shade400,
                                      width: isActive ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    displayTime,
                                    style: TextStyle(
                                      color: isActive ? Colors.red.shade700 : Colors.grey.shade700,
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 15,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // Comments Section - Enhanced with gradient styling
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.cyan.shade50, Colors.blue.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.cyan.shade400, Colors.blue.shade500],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.comment, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Comments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: commentsCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Add your comments here...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.cyan.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.cyan.shade200, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.cyan.shade500, width: 2),
                        ),
                      ),
                      onChanged: (value) => _saveData(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Control Buttons - Colorful gradients
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade500, Colors.pink.shade500],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade300,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: stopAll,
                      icon: const Icon(Icons.stop_circle, size: 28),
                      label: const Text('Stop All', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade500, Colors.teal.shade500],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade300,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: exportCSV,
                      icon: const Icon(Icons.file_download, size: 28),
                      label: const Text('Export CSV', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
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
    rsuStorageCtrl.dispose();
    commentsCtrl.dispose();
    super.dispose();
  }
}
