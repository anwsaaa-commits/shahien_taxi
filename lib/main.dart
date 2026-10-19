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
// 2. الواجهة الرئيسية نمط أوبر / كريم (Uber / Careem style)
// -------------------------------------------------------------
class TaxiHomeScreen extends StatefulWidget {
  const TaxiHomeScreen({super.key});

  @override
  State<TaxiHomeScreen> createState() => _TaxiHomeScreenState();
}

class _TaxiHomeScreenState extends State<TaxiHomeScreen> {
  bool _isOnline = true;
  bool _isTripActive = false;
  double _fare = 0.0;
  double _distanceKm = 0.0;

  void _toggleTrip() {
    setState(() {
      _isTripActive = !_isTripActive;
      if (!_isTripActive) {
        _fare = 0.0;
        _distanceKm = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أبو شاهين للمشاوير'),
        centerTitle: true,
        actions: [
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
      body: Column(
        children: [
          // شريط الحالة
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
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // خريطة / واجهة تفاعلية خفيفة
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E252B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFB703), width: 1.5),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.map_rounded,
                      size: 80,
                      color: Color(0xFFFFB703),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isTripActive ? 'المشوار جاري حالياً...' : 'جاهز لمشوار جديد',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (_isTripActive) ...[
                      Text(
                        'الأجرة الحالية: ${_fare.toStringAsFixed(0)} ريال',
                        style: const TextStyle(
                            fontSize: 26,
                            color: Color(0xFFFFB703),
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'المسافة المقطوعة: ${_distanceKm.toStringAsFixed(1)} كم',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // لوحة التحكم السفلية بالرحلة
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
                  onPressed: _isOnline ? _toggleTrip : null,
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
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
