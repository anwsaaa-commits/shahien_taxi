import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShahienTaxiApp());
}

class ShahienTaxiApp extends StatelessWidget {
  const ShahienTaxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تكسي الشاهين',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFFFB703),
        scaffoldBackgroundColor: const Color(0xFFFFC300),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFB703),
          foregroundColor: Colors.black,
          elevation: 2,
        ),
      ),
      home: const PhoneAuthScreen(),
    );
  }
}

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isCodeSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFC300),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              color: const Color(0xFF1E252B),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.local_taxi_rounded,
                      size: 80,
                      color: Color(0xFFFFB703),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'تكسي الشاهين',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isCodeSent
                          ? 'أدخل رمز التحقق (OTP) المرسل لجوّالك'
                          : 'أدخل رقم جوالك لتأكيد الهوية والدخول',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (!_isCodeSent) ...[
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        decoration: InputDecoration(
                          labelText: 'رقم الجوال',
                          labelStyle: const TextStyle(color: Color(0xFFFFB703)),
                          hintText: '770000000',
                          prefixIcon: const Icon(Icons.phone, color: Color(0xFFFFB703)),
                          filled: true,
                          fillColor: const Color(0xFF12161A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_phoneController.text.trim().isNotEmpty) {
                            setState(() {
                              _isCodeSent = true;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB703),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'إرسال كود التحقق',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 24, letterSpacing: 8),
                        decoration: InputDecoration(
                          labelText: 'رمز التأكيد',
                          labelStyle: const TextStyle(color: Color(0xFFFFB703)),
                          hintText: '123456',
                          filled: true,
                          fillColor: const Color(0xFF12161A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_otpController.text.trim().length >= 4) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const TaxiHomeScreen()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('يرجى إدخال كود تحقق صحيح مكون من 4 إلى 6 أرقام'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB703),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'تأكيد الكود والدخول',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isCodeSent = false;
                          });
                        },
                        child: const Text(
                          'تعديل رقم الجوال',
                          style: TextStyle(color: Color(0xFFFFB703)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TaxiHomeScreen extends StatefulWidget {
  const TaxiHomeScreen({super.key});

  @override
  State<TaxiHomeScreen> createState() => _TaxiHomeScreenState();
}

class _TaxiHomeScreenState extends State<TaxiHomeScreen> {
  int _selectedNavIndex = 0;
  bool _isOnline = true;
  bool _isTripActive = false;
  bool _isPaused = false;

  double _fare = 0.0;
  double _distanceKm = 0.0;
  int _elapsedSeconds = 0;
  Timer? _tripTimer;

  Position? _lastPosition;
  StreamSubscription<Position>? _positionStream;

  List<String> _tripHistoryList = [];
  double _totalEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalEarnings = prefs.getDouble('total_earnings') ?? 0.0;
      _tripHistoryList = prefs.getStringList('trip_history') ?? [];
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('total_earnings', _totalEarnings);
    await prefs.setStringList('trip_history', _tripHistoryList);
  }

  Future<void> _startTrip() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    setState(() {
      _isTripActive = true;
      _isPaused = false;
      _fare = 500.0;
      _distanceKm = 0.0;
      _elapsedSeconds = 0;
      _lastPosition = null;
    });

    _tripTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (_isTripActive && !_isPaused) {
        if (_lastPosition != null) {
          double distanceInMeters = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          setState(() {
            _distanceKm += (distanceInMeters / 1000.0);
            _fare += (distanceInMeters / 1000.0) * 300;
          });
        }
        _lastPosition = position;
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _stopAndSaveTrip() {
    _tripTimer?.cancel();
    _positionStream?.cancel();

    final double finalFare = _fare;
    final double finalDistance = _distanceKm;

    if (finalFare > 0) {
      String tripEntry =
          'مشوار رقم #${_tripHistoryList.length + 1} | المسافة: ${finalDistance.toStringAsFixed(1)} كم | الأجرة: ${finalFare.toStringAsFixed(0)} ريال';
      setState(() {
        _tripHistoryList.insert(0, tripEntry);
        _totalEarnings += finalFare;
        _isTripActive = false;
        _isPaused = false;
        _fare = 0.0;
        _distanceKm = 0.0;
        _elapsedSeconds = 0;
      });
      _saveData();
    }
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tripTimer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFC300),
      appBar: AppBar(
        title: Text(
          _selectedNavIndex == 0 ? 'أبو شاهين للمشاوير' : 'سجل الرحلات والأرباح',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_selectedNavIndex == 0)
            Switch(
              value: _isOnline,
              activeColor: Colors.black,
              onChanged: (val) {
                setState(() {
                  _isOnline = val;
                });
              },
            ),
        ],
      ),
      body: _selectedNavIndex == 0 ? _buildDashboardView() : _buildHistoryView(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        backgroundColor: const Color(0xFF1E252B),
        selectedItemColor: const Color(0xFFFFB703),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.speed_rounded),
            label: 'العداد والمشوار',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'سجل الرحلات',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: _isOnline ? Colors.green[800] : Colors.red[800],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isOnline ? Icons.check_circle : Icons.offline_bolt,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isOnline ? 'أنت الآن متاح للرحلات (أونلاين)' : 'أنت غير متاح (أوفلاين)',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E252B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFFFB703),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isTripActive ? Icons.local_taxi : Icons.map_rounded,
                  size: 70,
                  color: const Color(0xFFFFB703),
                ),
                const SizedBox(height: 12),
                Text(
                  _isTripActive
                      ? (_isPaused ? 'المشوار متوقف مؤقتاً...' : 'المشوار جاري (تتبع الـ GPS)...')
                      : 'جاهز لبدء مشوار جديد',
                  style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_isTripActive) ...[
                  Text(
                    '${_fare.toStringAsFixed(0)} ريال',
                    style: const TextStyle(
                      fontSize: 36,
                      color: Color(0xFFFFB703),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Text('المسافة (GPS)', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            '${_distanceKm.toStringAsFixed(1)} كم',
                            style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('الوقت', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(_elapsedSeconds),
                            style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isTripActive) ...[
                  ElevatedButton.icon(
                    onPressed: _togglePause,
                    icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(_isPaused ? 'استئناف المشوار' : 'إيقاف مؤقت'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPaused ? Colors.blue[700] : Colors.orange[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                ElevatedButton.icon(
                  onPressed: _isOnline
                      ? (_isTripActive ? _stopAndSaveTrip : _startTrip)
                      : null,
                  icon: Icon(_isTripActive ? Icons.stop : Icons.play_arrow),
                  label: Text(_isTripActive ? 'إنهاء المشوار وحفظ الأجرة' : 'بدء مشوار جديد'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTripActive ? Colors.red[700] : const Color(0xFF1E252B),
                    foregroundColor: const Color(0xFFFFB703),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E252B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFB703), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('إجمالي أرباحك المحفوظة', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text(
                    '${_totalEarnings.toStringAsFixed(0)} ريال',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFB703),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('المشاوير', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text(
                    '${_tripHistoryList.length}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _tripHistoryList.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد رحلات محفوظة حتى الآن',
                    style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )
              : ListView.builder(
                  itemCount: _tripHistoryList.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    return Card(
                      color: const Color(0xFF1E252B),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFFB703),
                          child: Icon(Icons.check, color: Colors.black),
                        ),
                        title: Text(
                          _tripHistoryList[index],
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
