import 'dart:async';
import 'package:flutter/material.dart';

void main() {
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
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFFB703),
        scaffoldBackgroundColor: const Color(0xFF12161A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E252B),
          elevation: 0,
        ),
      ),
      home: const PhoneAuthScreen(),
    );
  }
}

// -------------------------------------------------------------
// 1. شاشة تسجيل الدخول برقم الجوال
// -------------------------------------------------------------
class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isCodeSent = false;
  final TextEditingController _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.local_taxi_rounded,
                size: 90,
                color: Color(0xFFFFB703),
              ),
              const SizedBox(height: 16),
              const Text(
                'تكسي الشاهين',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isCodeSent
                    ? 'أدخل رمز التحقق المرسل لرقمك'
                    : 'سجل برقم جوالك للبدء في استقبال المشاوير',
                style: const TextStyle(color: Colors.grey, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              if (!_isCodeSent) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'رقم الجوال',
                    hintText: '770000000',
                    prefixIcon: const Icon(Icons.phone, color: Color(0xFFFFB703)),
                    filled: true,
                    fillColor: const Color(0xFF1E252B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (_phoneController.text.isNotEmpty) {
                      setState(() {
                        _isCodeSent = true;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB703),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'إرسال رمز التحقق',
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
                    labelText: 'رمز التحقق (OTP)',
                    hintText: '123456',
                    filled: true,
                    fillColor: const Color(0xFF1E252B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TaxiHomeScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB703),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'تأكيد والدخول',
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
    );
  }
}

// -------------------------------------------------------------
// نموذج بيانات المشوار
// -------------------------------------------------------------
class TripItem {
  final String title;
  final double distanceKm;
  final double fare;
  final String time;

  TripItem({
    required this.title,
    required this.distanceKm,
    required this.fare,
    required this.time,
  });
}

// -------------------------------------------------------------
// 2. الواجهة الرئيسية مع العداد الحي والسجل
// -------------------------------------------------------------
class TaxiHomeScreen extends StatefulWidget {
  const TaxiHomeScreen({super.key});

  @override
  State<TaxiHomeScreen> createState() => _TaxiHomeScreenState();
}

class _TaxiHomeScreenState extends State<TaxiHomeScreen> {
  int _selectedNavIndex = 0;
  bool _isOnline = true;
  bool _isTripActive = false;

  // متغيرا العداد
  double _fare = 0.0;
  double _distanceKm = 0.0;
  int _elapsedSeconds = 0;
  Timer? _tripTimer;

  // قائمة السجل والأرباح
  final List<TripItem> _completedTrips = [];
  double _totalEarnings = 0.0;

  void _startTrip() {
    setState(() {
      _isTripActive = true;
      _fare = 500.0; // فتحة العداد الافتراضية
      _distanceKm = 0.0;
      _elapsedSeconds = 0;
    });

    _tripTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
        _distanceKm += 0.02; // زيادة تدريجية للمسافة
        _fare += 6.0; // زيادة الأجرة مع المسافة والوقت
      });
    });
  }

  void _stopAndSaveTrip() {
    _tripTimer?.cancel();
    final double finalFare = _fare;
    final double finalDistance = _distanceKm;

    setState(() {
      _isTripActive = false;
      if (finalFare > 0) {
        _completedTrips.insert(
          0,
          TripItem(
            title: 'مشوار رقم #${_completedTrips.length + 1}',
            distanceKm: finalDistance,
            fare: finalFare,
            time: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          ),
        );
        _totalEarnings += finalFare;
      }
      _fare = 0.0;
      _distanceKm = 0.0;
      _elapsedSeconds = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إنهاء المشوار وحفظ الأجرة: ${finalFare.toStringAsFixed(0)} ريال'),
        backgroundColor: Colors.green[800],
      ),
    );
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tripTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedNavIndex == 0 ? 'أبو شاهين للمشاوير' : 'سجل الرحلات والأرباح'),
        centerTitle: true,
        actions: [
          if (_selectedNavIndex == 0)
            Switch(
              value: _isOnline,
              activeColor: const Color(0xFFFFB703),
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

  // واجهة العداد واللوحة الرئيسية
  Widget _buildDashboardView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: _isOnline ? Colors.green[900] : Colors.red[900],
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
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E252B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isTripActive ? const Color(0xFFFFB703) : Colors.grey.shade800,
                width: 2,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isTripActive ? Icons.local_taxi : Icons.map_rounded,
                    size: 80,
                    color: const Color(0xFFFFB703),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isTripActive ? 'المشوار جاري حالياً...' : 'جاهز لبدء مشوار جديد',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  if (_isTripActive) ...[
                    Text(
                      '${_fare.toStringAsFixed(0)} ريال',
                      style: const TextStyle(
                        fontSize: 38,
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
                            const Text('المسافة', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              '${_distanceKm.toStringAsFixed(1)} كم',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('الوقت', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(_elapsedSeconds),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF1E252B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _isOnline
                    ? (_isTripActive ? _stopAndSaveTrip : _startTrip)
                    : null,
                icon: Icon(_isTripActive ? Icons.stop : Icons.play_arrow),
                label: Text(_isTripActive ? 'إنهاء المشوار وحفظ الأجرة' : 'بدء مشوار جديد'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isTripActive ? Colors.red[700] : const Color(0xFFFFB703),
                  foregroundColor: Colors.black,
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
      ],
    );
  }

  // واجهة سجل الرحلات والأرباح
  Widget _buildHistoryView() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E252B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFB703), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('إجمالي أرباح اليوم', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text(
                    '${_totalEarnings.toStringAsFixed(0)} ريال',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFB703),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('المشاوير المكتملة', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text(
                    '${_completedTrips.length}',
                    style: const TextStyle(
                      fontSize: 24,
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
          child: _completedTrips.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد رحلات محفوظة حتى الآن',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _completedTrips.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final trip = _completedTrips[index];
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
                          trip.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'المسافة: ${trip.distanceKm.toStringAsFixed(1)} كم | الوقت: ${trip.time}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        trailing: Text(
                          '${trip.fare.toStringAsFixed(0)} ريال',
                          style: const TextStyle(
                            color: Color(0xFFFFB703),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
