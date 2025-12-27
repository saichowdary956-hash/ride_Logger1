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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF667eea)),
        useMaterial3: true,
      ),
      home: const DataLoggerHome(),
    );
  }
}

class DataLoggerHome extends StatefulWidget {
  const DataLoggerHome({Key? key}) : super(key: key);

  @override
  State<DataLoggerHome> createState() => _DataLoggerHomeState();
}

class _DataLoggerHomeState extends State<DataLoggerHome> {
  final TextEditingController driverCtrl = TextEditingController();
  final TextEditingController annotatorCtrl = TextEditingController();
  final TextEditingController vehicleCtrl = TextEditingController();
  final TextEditingController rsuNoCtrl = TextEditingController();
  final TextEditingController driveIdCtrl = TextEditingController();
  final TextEditingController commentsCtrl = TextEditingController();
  final TextEditingController rsuStorageCtrl = TextEditingController();

  DateTime? sessionStartTime;
  DateTime? sessionEndTime;
  bool isSessionActive = false;
  bool hasShown30MinNotification = false;

  final Map<String, List<String>> categories = {
    'Weather': ['Sunny', 'Low Sun', 'Cloudy', 'Rain', 'Fog', 'Snow'],
    'Roadtype': ['City', 'Country', 'Highway', 'Construction site', 'Tunnel'],
    'Lighting': ['Day', 'Dawn', 'Lit Night', 'Dark Night'],
    'Traffic': ['Flow', 'Jam'],
    'Speed': ['3-18mph', '19-37mph', '38-55mph', '56-80mph', '81-155mph']
  };

  Map<String, String?> activeConditions = {};
  Map<String, int> startTimes = {};
  Map<String, Map<String, int>> conditionData = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _checkTimeNotification();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    driverCtrl.dispose();
    annotatorCtrl.dispose();
    vehicleCtrl.dispose();
    rsuNoCtrl.dispose();
    driveIdCtrl.dispose();
    commentsCtrl.dispose();
    rsuStorageCtrl.dispose();
    super.dispose();
  }

  void _initializeData() {
    categories.forEach((category, conditions) {
      for (var condition in conditions) {
        conditionData['$category|$condition'] = {'time': 0};
      }
    });
  }

  void _startRecording(String category, String condition) {
    if (!isSessionActive) {
      sessionStartTime = DateTime.now();
      sessionEndTime = null;
      isSessionActive = true;
      hasShown30MinNotification = false;
    }

    setState(() {
      activeConditions[category] = condition;
      startTimes[category] = DateTime.now().millisecondsSinceEpoch;
    });
  }

  void _stopRecording(String category) {
    final condition = activeConditions[category];
    if (condition == null) return;

    final key = '$category|$condition';
    final elapsed = (DateTime.now().millisecondsSinceEpoch - startTimes[category]!) ~/ 1000;
    
    setState(() {
      conditionData[key]!['time'] = (conditionData[key]!['time'] ?? 0) + elapsed;
      activeConditions.remove(category);
      startTimes.remove(category);
    });
    _saveData();
  }

  void _toggleCondition(String category, String condition) {
    if (activeConditions[category] == condition) {
      _stopRecording(category);
    } else {
      if (activeConditions[category] != null) {
        _stopRecording(category);
      }
      _startRecording(category, condition);
    }
  }

  void _resetCategory(String category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: Text('Do you want to reset $category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (activeConditions[category] != null) {
        _stopRecording(category);
      }
      setState(() {
        for (var condition in categories[category]!) {
          conditionData['$category|$condition'] = {'time': 0};
        }
      });
      _saveData();
      _showSnackBar('$category reset successfully');
    }
  }

  void stopAll() {
    setState(() {
      activeConditions.keys.toList().forEach(_stopRecording);
      if (isSessionActive && sessionStartTime != null) {
        sessionEndTime = DateTime.now();
      }
      isSessionActive = false;
    });
  }

  int _getSessionTime() {
    if (sessionStartTime == null) return 0;
    if (isSessionActive) {
      return DateTime.now().difference(sessionStartTime!).inSeconds;
    }
    if (sessionEndTime != null) {
      return sessionEndTime!.difference(sessionStartTime!).inSeconds;
    }
    return 0;
  }

  void _checkTimeNotification() {
    int sessionMinutes = _getSessionTime() ~/ 60;
    if (sessionMinutes >= 30 && !hasShown30MinNotification) {
      hasShown30MinNotification = true;
      _showTimeAlert(sessionMinutes);
    }
  }

  void _showTimeAlert(int minutes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.yellow[100],
        title: const Text('⏰ Session Time Alert'),
        content: Text('Session Time: $minutes Minutes Reached!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('conditionData', jsonEncode(conditionData));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('conditionData');
    if (data != null) {
      setState(() {
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        conditionData = decoded.map((k, v) => 
          MapEntry(k, Map<String, int>.from(v as Map))
        );
      });
    }
  }

  Future<void> exportCSV() async {
    final totalSessionSeconds = _getSessionTime();
    final totalSessionTime = _formatTime(totalSessionSeconds);

    // Horizontal CSV format - all in one row
    String csv = 'Driver,Annotator,Date,Vehicle,RSU No,Drive ID,RSU Storage (%),Overall Session Time,Comments\n';
    csv += '"${driverCtrl.text}","${annotatorCtrl.text}","${DateFormat('yyyy-MM-dd').format(DateTime.now())}","${vehicleCtrl.text}","${rsuNoCtrl.text}","${driveIdCtrl.text}","${rsuStorageCtrl.text}","$totalSessionTime","${commentsCtrl.text.replaceAll('"', '""')}"\n';

    print('CSV Data:\n$csv');
    _showSnackBar('CSV exported successfully!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚗 DataLogger', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Session Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildInputField('Driver', driverCtrl),
                        _buildInputField('Annotator', annotatorCtrl),
                        _buildInputField('Vehicle', vehicleCtrl),
                        _buildInputField('RSU No', rsuNoCtrl),
                        _buildInputField('Drive ID', driveIdCtrl),
                        _buildInputField('RSU Storage (%)', rsuStorageCtrl, keyboardType: TextInputType.number),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recording Conditions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ...categories.entries.map((e) => _buildCategory(e.key, e.value)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: commentsCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Comments', border: OutlineInputBorder()),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: stopAll,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
                    child: const Text('⏹️ Stop All'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: exportCSV,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
                    child: const Text('📥 Export CSV'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController ctrl, {TextInputType? keyboardType}) {
    return SizedBox(
      width: 200,
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFFf39c12), fontWeight: FontWeight.w600),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildCategory(String category, List<String> conditions) {
    final gradients = {
      'Weather': [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      'Roadtype': [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
      'Lighting': [const Color(0xFFfa709a), const Color(0xFFfee140)],
      'Traffic': [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      'Speed': [const Color(0xFFa18cd1), const Color(0xFFfbc2eb)],
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradients[category]!,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _resetCategory(category),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFff9800),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    '🔄 Reset $category',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: conditions.map((c) => _buildConditionRow(category, c)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionRow(String category, String condition) {
    final key = '$category|$condition';
    final isActive = activeConditions[category] == condition;
    int time = conditionData[key]!['time'] ?? 0;
    
    if (isActive) {
      final elapsed = (DateTime.now().millisecondsSinceEpoch - startTimes[category]!) ~/ 1000;
      time += elapsed;
    }

    final color = isActive ? const Color(0xFFff6b6b) : const Color(0xFF51cf66);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => _toggleCondition(category, condition),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                minimumSize: const Size(10, 10),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: Colors.transparent,
              ),
              child: Text(
                isActive ? '🔴 $condition' : condition,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _formatTime(time),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier New',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
