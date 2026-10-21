import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ShahienTaxiApp());
}

class ShahienTaxiApp extends StatelessWidget {
  const ShahienTaxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تكسي الشاهين',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFFFFC107),
        fontFamily: 'Roboto',
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _codeSent = false;

  void _submit() {
    if (!_codeSent) {
      if (_phoneController.text.trim().isNotEmpty) {
        setState(() => _codeSent = true);
      }
    } else {
      if (_otpController.text.trim() == "123456" || _otpController.text.trim().isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E222A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_taxi, size: 80, color: Color(0xFFFFC107)),
              ),
              const SizedBox(height: 24),
              const Text(
                'تكسي الشاهين',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E222A)),
              ),
              const SizedBox(height: 8),
              Text(
                _codeSent ? 'أدخل رمز التحقق (123456)' : 'أدخل رقم الجوال للبدء',
                style: const TextStyle(fontSize: 16, color: Colors.black80),
              ),
              const SizedBox(height: 32),
              Card(
                color: const Color(0xFF1E222A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      if (!_codeSent)
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'رقم الجوال',
                            labelStyle: TextStyle(color: Colors.amber),
                            prefixIcon: Icon(Icons.phone, color: Colors.amber),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                          ),
                        )
                      else
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 4),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            hintText: '123456',
                            hintStyle: TextStyle(color: Colors.white38),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                          ),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC107),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _submit,
                          child: Text(
                            _codeSent ? 'تأكيد الكود والدخول' : 'إرسال رمز التحقق',
                            style: const TextStyle(color: Color(0xFF1E222A), fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      if (_codeSent)
                        TextButton(
                          onPressed: () => setState(() => _codeSent = false),
                          child: const Text('تعديل رقم الجوال', style: TextStyle(color: Colors.amber)),
                        )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double baseFare = 1000.0;
  double perKmFare = 500.0;
  double perMinFare = 100.0;

  bool isTripActive = false;
  bool isPaused = false;

  double totalDistanceMeters = 0.0;
  int elapsedSeconds = 0;
  double currentFare = 0.0;

  StreamSubscription<Position>? _positionStream;
  Timer? _tripTimer;
  Position? _lastPosition;

  List<String> _tripHistory = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      baseFare = prefs.getDouble('baseFare') ?? 1000.0;
      perKmFare = prefs.getDouble('perKmFare') ?? 500.0;
      perMinFare = prefs.getDouble('perMinFare') ?? 100.0;
      _tripHistory = prefs.getStringList('tripHistory') ?? [];
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('baseFare', baseFare);
    await prefs.setDouble('perKmFare', perKmFare);
    await prefs.setDouble('perMinFare', perMinFare);
  }

  void _calculateFare() {
    double distanceKm = totalDistanceMeters / 1000.0;
    double minutes = elapsedSeconds / 60.0;
    setState(() {
      currentFare = baseFare + (distanceKm * perKmFare) + (minutes * perMinFare);
    });
  }

  Future<void> _startTrip() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تفعيل الـ GPS')));
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    setState(() {
      isTripActive = true;
      isPaused = false;
      totalDistanceMeters = 0.0;
      elapsedSeconds = 0;
      currentFare = baseFare;
      _lastPosition = null;
    });

    _tripTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPaused) {
        setState(() {
          elapsedSeconds++;
          _calculateFare();
        });
      }
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (!isPaused) {
        if (_lastPosition != null) {
          double dist = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          if (dist > 2.0) {
            totalDistanceMeters += dist;
          }
        }
        _lastPosition = position;
        _calculateFare();
      }
    });
  }

  void _togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
  }

  Future<void> _endTrip() async {
    _positionStream?.cancel();
    _tripTimer?.cancel();

    double finalDistanceKm = totalDistanceMeters / 1000.0;
    String record = "مشوار: ${finalDistanceKm.toStringAsFixed(2)} كم - المبلغ: ${currentFare.toStringAsFixed(0)} ريال - الوقت: ${(elapsedSeconds ~/ 60)} د";

    final prefs = await SharedPreferences.getInstance();
    _tripHistory.insert(0, record);
    await prefs.setStringList('tripHistory', _tripHistory);

    setState(() {
      isTripActive = false;
      isPaused = false;
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1E222A),
          title: const Text('تم إنهاء المشوار 🏁', style: TextStyle(color: Colors.amber), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('المسافة: ${finalDistanceKm.toStringAsFixed(2)} كم', style: const TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 8),
              Text('الأجرة الإجمالية: ${currentFare.toStringAsFixed(0)} ريال', style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () => Navigator.pop(context),
              child: const Text('تم', style: TextStyle(color: Colors.black)),
            )
          ],
        ),
      );
    }
  }

  void _openSettingsDialog() {
    TextEditingController baseCtrl = TextEditingController(text: baseFare.toStringAsFixed(0));
    TextEditingController kmCtrl = TextEditingController(text: perKmFare.toStringAsFixed(0));
    TextEditingController minCtrl = TextEditingController(text: perMinFare.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E222A),
        title: const Text('إعدادات التسعيرة ⚙️', style: TextStyle(color: Colors.amber), textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: baseCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'فتحة العداد (ريال)', labelStyle: TextStyle(color: Colors.amber)),
              ),
              TextField(
                controller: kmCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'سعر الكيلومتر (ريال)', labelStyle: TextStyle(color: Colors.amber)),
              ),
              TextField(
                controller: minCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'سعر دقيقة الانتظار (ريال)', labelStyle: TextStyle(color: Colors.amber)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              setState(() {
                baseFare = double.tryParse(baseCtrl.text) ?? baseFare;
                perKmFare = double.tryParse(kmCtrl.text) ?? perKmFare;
                perMinFare = double.tryParse(minCtrl.text) ?? perMinFare;
              });
              _saveSettings();
              Navigator.pop(context);
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.black)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double distanceKm = totalDistanceMeters / 1000.0;
    int minutes = elapsedSeconds ~/ 60;
    int seconds = elapsedSeconds % 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تكسي الشاهين 🦅', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black, size: 28),
            onPressed: isTripActive ? null : _openSettingsDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                color: const Color(0xFF1E222A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text('الأجرة الحالية', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        '${currentFare.toStringAsFixed(0)} YER',
                        style: const TextStyle(color: Colors.amber, fontSize: 44, fontWeight: FontWeight.bold),
                      ),
                      const Divider(color: Colors.white24, height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.speed, color: Colors.amber),
                              const SizedBox(height: 4),
                              Text('${distanceKm.toStringAsFixed(2)} كم', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              const Text('المسافة', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                          Column(
                            children: [
                              const Icon(Icons.timer, color: Colors.amber),
                              const SizedBox(height: 4),
                              Text('$minutes:${seconds.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              const Text('الوقت', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (!isTripActive)
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E222A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.play_arrow, color: Colors.amber, size: 32),
                    label: const Text('بدء المشوار', style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold)),
                    onPressed: _startTrip,
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPaused ? Colors.green : Colors.orange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white),
                          label: Text(isPaused ? 'استئناف' : 'إيقاف مؤقت', style: const TextStyle(color: Colors.white, fontSize: 16)),
                          onPressed: _togglePause,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.stop, color: Colors.white),
                          label: const Text('إنهاء المشوار', style: TextStyle(color: Colors.white, fontSize: 16)),
                          onPressed: _endTrip,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('سجل المشاوير اليومية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E222A))),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _tripHistory.isEmpty
                    ? const Center(child: Text('لا توجد مشاوير مسجلة اليوم', style: TextStyle(color: Colors.black54)))
                    : ListView.builder(
                        itemCount: _tripHistory.length,
                        itemBuilder: (ctx, idx) => Card(
                          color: const Color(0xFF1E222A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Icon(Icons.history, color: Colors.amber),
                            title: Text(_tripHistory[idx], style: const TextStyle(color: Colors.white, fontSize: 14)),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
