import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
      title: 'عداد التاكسي - الشاهين',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        primaryColor: const Color(0xFFFFC107),
        cardColor: const Color(0xFF161B22),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: const Color(0xFF0D1117),
          selectedItemColor: const Color(0xFFFFC107),
          unselectedItemColor: Colors.white54,
          selectedFontSize: 14,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.local_taxi_rounded),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// الشاشة الرئيسية (عداد التاكسي + الخريطة الحية)
// ---------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // موقع افتراضي (المكلا / فُوَة) لحين جلب الـ GPS
  LatLng _currentLocation = const LatLng(14.5388, 49.1242);
  final MapController _mapController = MapController();

  bool _isTripActive = false;
  double _currentFare = 0.0;
  double _totalDistanceKm = 0.0;
  double _currentSpeed = 0.0;
  int _elapsedSeconds = 0;

  double _baseFare = 1000.0;
  double _perKmRate = 500.0;

  Timer? _timer;
  StreamSubscription<Position>? _positionStream;
  Position? _lastPosition;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initLocation();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _baseFare = prefs.getDouble('baseFare') ?? 1000.0;
      _perKmRate = prefs.getDouble('perKmRate') ?? 500.0;
    });
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position pos = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(pos.latitude, pos.longitude);
      _mapController.move(_currentLocation, 15.0);
    });
  }

  void _toggleTrip() {
    if (_isTripActive) {
      // إيقاف المشوار
      _timer?.cancel();
      _positionStream?.cancel();
      setState(() {
        _isTripActive = false;
      });
      _showTripSummary();
    } else {
      // بدء المشوار
      setState(() {
        _isTripActive = true;
        _currentFare = _baseFare;
        _totalDistanceKm = 0.0;
        _elapsedSeconds = 0;
        _lastPosition = null;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _elapsedSeconds++;
        });
      });

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        ),
      ).listen((Position position) {
        LatLng newPos = LatLng(position.latitude, position.longitude);
        _mapController.move(newPos, 16.0);

        if (_lastPosition != null) {
          double distMeters = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );

          if (distMeters > 2.0) {
            setState(() {
              _totalDistanceKm += (distMeters / 1000.0);
              _currentSpeed = (position.speed * 3.6); // تحويل م/ث إلى كم/س
              _currentFare = _baseFare + (_totalDistanceKm * _perKmRate);
              _currentLocation = newPos;
            });
          }
        }
        _lastPosition = position;
      });
    }
  }

  void _showTripSummary() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('اكتمل المشوار 🏁', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFC107))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المسافة القطوعة: ${_totalDistanceKm.toStringAsFixed(2)} كم', style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            Text('الزمن: ${(_elapsedSeconds ~/ 60)} دقيقة', style: const TextStyle(color: Colors.white, fontSize: 16)),
            const Divider(color: Colors.white24, height: 24),
            Text('إجمالي الأجرة: ${_currentFare.toStringAsFixed(0)} ريال', style: const TextStyle(color: Color(0xFFFFC107), fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107)),
            onPressed: () => Navigator.pop(context),
            child: const Text('تم', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int minutes = _elapsedSeconds ~/ 60;
    int seconds = _elapsedSeconds % 60;
    String timeStr = "$minutes:${seconds.toString().padLeft(2, '0')}";

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 1. الخريطة الحية خلف كل شيء
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.shahien.taxi',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation,
                      width: 50,
                      height: 50,
                      child: const Icon(Icons.navigation, color: Colors.amber, size: 40),
                    ),
                  ],
                ),
              ],
            ),

            // 2. العناصر العلوية المترابطة مع الشاشة (Header Stats & Fare)
            Column(
              children: [
                // الشريط العلوي (العنوان والسرعة والمسافة والوقت)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xEE0D1117),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.local_taxi, color: Color(0xFFFFC107), size: 30),
                              SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('عداد التاكسي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                  Text('رحلتك بأمان .. وبدون قلق', style: TextStyle(fontSize: 11, color: Colors.white54)),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                            child: IconButton(
                              icon: const Icon(Icons.settings, color: Color(0xFFFFC107)),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // الإحصائيات (السرعة - المسافة - الوقت)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildHeaderStat('السرعة', '${_currentSpeed.toStringAsFixed(0)} كم/س', Icons.speed),
                          _buildHeaderStat('المسافة', '${_totalDistanceKm.toStringAsFixed(1)} كم', Icons.add_location_alt_outlined),
                          _buildHeaderStat('الوقت', timeStr, Icons.access_time),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // بطاقة الأجرة الحالية الذهبية
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFA161B22),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFC107), width: 1.5),
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        const Text('الأجرة الحالية', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _currentFare.toStringAsFixed(2),
                              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Color(0xFFFFC107)),
                            ),
                            const SizedBox(width: 8),
                            const Text('ريال', style: TextStyle(fontSize: 18, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.payments_outlined, color: Color(0xFFFFC107), size: 16),
                            const SizedBox(width: 4),
                            Text('التسعيرة الأساسية: ${_perKmRate.toStringAsFixed(0)} ريال / كم', style: const TextStyle(fontSize: 12, color: Colors.white60)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 3. العناصر السفلى (الوجهة + زر بدء المشوار الضخم)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  // بطاقة تحديد الوجهة
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xEE161B22),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.location_on, color: Colors.greenAccent),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('وجهتك الحالية', style: TextStyle(color: Colors.white54, fontSize: 11)),
                              Text('إلى: فُوَة المتضررين - المكلا', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // زر بدء/إيقاف المشوار الفاخر
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTripActive ? Colors.redAccent : const Color(0xFFFFC107),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 8,
                      ),
                      onPressed: _toggleTrip,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isTripActive ? Icons.stop_circle : Icons.play_circle_fill, color: Colors.black, size: 36),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isTripActive ? 'إيقاف المشوار' : 'ابدأ المشوار',
                                style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _isTripActive ? 'انقر لإتمام الحساب' : 'سيتم احتساب الأجرة تلقائياً',
                                style: const TextStyle(color: Colors.black87, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFFC107), size: 20),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
      ],
    );
  }
}

// ---------------------------------------------------------
// واجهة إعدادات التطبيق (المطابقة تماماً للصورة)
// ---------------------------------------------------------
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        title: const Text('إعدادات التطبيق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // رأس الإعدادات والرمز
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFC107),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_taxi, size: 50, color: Colors.black),
                ),
                const SizedBox(height: 8),
                const Text('عداد التاكسي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text('الإصدار 1.0.0', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 1. إعدادات عامة
          _buildSectionHeader('إعدادات عامة', Icons.settings_suggest),
          _buildSettingsTile(Icons.language, 'اللغة', 'العربية'),
          _buildSettingsTile(Icons.dark_mode, 'الوضع الليلى', 'تفعيل'),
          _buildSettingsTile(Icons.notifications_active, 'الصوت والتنبيهات', 'تفعيل'),
          _buildSettingsTile(Icons.gps_fixed, 'الموقع', 'دقة عالية'),

          const SizedBox(height: 20),

          // 2. إعدادات الحساب
          _buildSectionHeader('إعدادات الحساب', Icons.person),
          _buildSettingsTile(Icons.person_outline, 'معلومات السائق', 'البيانات الشخصية وركية التاكسي'),
          _buildSettingsTile(Icons.lock_outline, 'تغيير كلمة المرور', ''),
          _buildSettingsTile(Icons.account_balance_wallet_outlined, 'المحفظة الإلكترونية', ''),

          const SizedBox(height: 20),

          // 3. إعدادات الخدمة
          _buildSectionHeader('إعدادات الخدمة', Icons.local_taxi_outlined),
          _buildSettingsTile(Icons.payments_outlined, 'التسعيرة', 'حسب المدينة'),
          _buildSettingsTile(Icons.access_time_filled, 'أوقات العمل', 'متاح دائماً'),
          _buildSettingsTile(Icons.circle_notifications_outlined, 'إشعارات الرحلة', 'إدارة الإشعارات'),

          const SizedBox(height: 20),

          // 4. مساعدة ودعم
          _buildSectionHeader('مساعدة ودعم', Icons.help_outline),
          _buildSettingsTile(Icons.help_center_outlined, 'مركز المساعدة', 'الأسئلة الشائعة'),
          _buildSettingsTile(Icons.chat_bubble_outline, 'تواصل معنا', 'راسلنا في أي وقت'),
          _buildSettingsTile(Icons.info_outline, 'عن التطبيق', 'الإصدار 1.0.0'),

          const SizedBox(height: 24),

          // زر تسجيل الخروج
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFFC107)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            icon: const Icon(Icons.logout, color: Color(0xFFFFC107)),
            label: const Text('تسجيل الخروج', style: TextStyle(color: Color(0xFFFFC107), fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: () {},
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFC107), size: 18),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Color(0xFFFFC107), fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)) : null,
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
        onTap: () {},
      ),
    );
  }
}
