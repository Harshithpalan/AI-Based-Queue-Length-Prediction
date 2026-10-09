import 'package:flutter/material.dart';
import 'queue_prediction_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Queue Length Prediction',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const QueuePredictionScreen(),
    );
  }
}

class QueuePredictionScreen extends StatefulWidget {
  const QueuePredictionScreen({super.key});

  @override
  State<QueuePredictionScreen> createState() => _QueuePredictionScreenState();
}

class _QueuePredictionScreenState extends State<QueuePredictionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceCountController = TextEditingController();
  final _avgServiceTimeController = TextEditingController();
  final _arrivalRateController = TextEditingController();
  final _timeOfDayController = TextEditingController();
  
  final QueuePredictionService _predictionService = QueuePredictionService();
  
  PredictionResult? _predictionResult;
  bool _isLoading = false;

  @override
  void dispose() {
    _serviceCountController.dispose();
    _avgServiceTimeController.dispose();
    _arrivalRateController.dispose();
    _timeOfDayController.dispose();
    super.dispose();
  }

  Future<void> _predictQueueLength() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final input = QueueInput(
        serviceCount: int.parse(_serviceCountController.text),
        avgServiceTime: double.parse(_avgServiceTimeController.text),
        arrivalRate: double.parse(_arrivalRateController.text),
        timeOfDay: _timeOfDayController.text,
      );

      try {
        final result = await _predictionService.predictQueueLength(input);
        setState(() {
          _predictionResult = result;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Queue Length Prediction'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter Queue Parameters',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _serviceCountController,
                decoration: const InputDecoration(
                  labelText: 'Number of Service Counters',
                  hintText: 'e.g., 5',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the number of service counters';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _avgServiceTimeController,
                decoration: const InputDecoration(
                  labelText: 'Average Service Time (minutes)',
                  hintText: 'e.g., 5.5',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter average service time';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _arrivalRateController,
                decoration: const InputDecoration(
                  labelText: 'Arrival Rate (customers/minute)',
                  hintText: 'e.g., 2.5',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter arrival rate';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeOfDayController,
                decoration: const InputDecoration(
                  labelText: 'Time of Day',
                  hintText: 'e.g., 14:30 (2:30 PM)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter time of day';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _predictQueueLength,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Predict Queue Length'),
              ),
              const SizedBox(height: 24),
              if (_predictionResult != null) _buildPredictionResult(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionResult() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prediction Results',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildResultRow('Predicted Queue Length', 
                '${_predictionResult!.predictedQueueLength.toStringAsFixed(2)} customers'),
            _buildResultRow('Average Wait Time', 
                '${_predictionResult!.avgWaitTime.toStringAsFixed(2)} minutes'),
            _buildResultRow('Service Utilization', 
                '${(_predictionResult!.utilization * 100).toStringAsFixed(1)}%'),
            _buildResultRow('Confidence', 
                '${(_predictionResult!.confidence * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _predictionResult!.utilization,
              backgroundColor: Colors.grey[300],
              color: _predictionResult!.utilization > 0.8 
                  ? Colors.red 
                  : _predictionResult!.utilization > 0.6 
                      ? Colors.orange 
                      : Colors.green,
            ),
            const SizedBox(height: 8),
            Text(
              _predictionResult!.utilization > 0.8 
                  ? 'High Utilization - Consider adding more counters'
                  : _predictionResult!.utilization > 0.6 
                      ? 'Moderate Utilization'
                      : 'Low Utilization - System is efficient',
              style: TextStyle(
                color: _predictionResult!.utilization > 0.8 
                    ? Colors.red 
                    : _predictionResult!.utilization > 0.6 
                        ? Colors.orange 
                        : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Model Configuration',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.psychology),
            title: const Text('AI Model'),
            subtitle: const Text('QueueML-2.0 (Default)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.data_usage),
            title: const Text('Data Source'),
            subtitle: const Text('Historical Database'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.update),
            title: const Text('Update Frequency'),
            subtitle: const Text('Every 5 minutes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Display Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Show Confidence Interval'),
            subtitle: const Text('Display prediction confidence range'),
            value: true,
            onChanged: (value) {},
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: false,
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }
}
