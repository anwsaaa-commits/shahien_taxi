Dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

const gold = Color(0xFFFFC107);
const bg = Color(0xFF0D1117);
const panel = Color(0xFF161B22);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        scaffoldBackgroundColor: bg,
        primaryColor: gold,
        colorScheme: const ColorScheme.dark(
          primary: gold,
          secondary: gold,
          surface: panel,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: Colors.white,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class TaxiSettings {
  static Future<Map<String, dynamic>> load() async {
    final p = await SharedPreferences.getInstance();
    return {
      'base': p.getDouble('baseFare') ?? 1000.0,
      'rate': p.getDouble('perKmRate') ?? 500.0,
      'driver': p.getString('driverName') ?? '',
      'phone': p.getString('driverPhone') ?? '',
      'taxi': p.getString('taxiNumber') ?? '',
    };
  }

  static Future<void> save({
    required double base,
    required double rate,
    required String driver,
    required String phone,
    required String taxi,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('baseFare', base);
    await p.setDouble('perKmRate', rate);
    await p.setString('driverName', driver);
    await p.setString('driverPhone', phone);
    await p.setString('taxiNumber', taxi);
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: [
          HomeScreen(
            openSettings: () => setState(() => index = 1),
          ),
          SettingsScreen(
            onSettingsSaved: () {
              setState(() {});
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        backgroundColor: bg,
        selectedItemColor: gold,
        unselectedItemColor: Colors.white54,
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
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final VoidCallback onSettingsSaved;

  const SettingsScreen({
    super.key,
    required this.onSettingsSaved,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final baseController = TextEditingController();
  final rateController = TextEditingController();
  final driverController = TextEditingController();
  final phoneController = TextEditingController();
  final taxiController = TextEditingController();

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await TaxiSettings.load();
    if (!mounted) return;

    baseController.text = '${data['base']}';
    rateController.text = '${data['rate']}';
    driverController.text = data['driver'] as String;
    phoneController.text = data['phone'] as String;
    taxiController.text = data['taxi'] as String;

    setState(() => loading = false);
  }

  @override
  void dispose() {
    baseController.dispose();
    rateController.dispose();
    driverController.dispose();
    phoneController.dispose();
    taxiController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final base = double.tryParse(baseController.text.trim());
    final rate = double.tryParse(rateController.text.trim());

    if (base == null || rate == null || base < 0 || rate < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أدخل تسعيرة صحيحة أكبر من أو تساوي صفر'),
        ),
      );
      return;
    }

    await TaxiSettings.save(
      base: base,
      rate: rate,
      driver: driverController.text.trim(),
      phone: phoneController.text.trim(),
      taxi: taxiController.text.trim(),
    );

    widget.onSettingsSaved();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ الإعدادات بنجاح')),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: panel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات شاهين تاكسي'),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Icon(Icons.local_taxi, color: gold, size: 64),
                const SizedBox(height: 12),
                const Text(
                  'بيانات السائق والتسعيرة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: gold,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _field('الأجرة الأساسية (ريال)', baseController,
                    keyboard: TextInputType.number),
                _field('سعر الكيلومتر (ريال)', rateController,
                    keyboard: TextInputType.number),
                _field('اسم السائق', driverController),
                _field('رقم هاتف السائق', phoneController,
                    keyboard: TextInputType.phone),
                _field('رقم التاكسي أو اللوحة', taxiController),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ الإعدادات'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'تُحفظ البيانات على هذا الجهاز فقط.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
    );
  }
}Dart
enum TripStatus { idle, running, paused }

class HomeScreen extends StatefulWidget {
  final VoidCallback openSettings;

  const HomeScreen({
    super.key,
    required this.openSettings,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController mapController = MapController();

  LatLng currentLocation = const LatLng(14.5388, 49.1242);
  LatLng? lastTripPosition;

  TripStatus status = TripStatus.idle;

  double baseFare = 1000;
  double perKmRate = 500;
  double distanceKm = 0;
  double fare = 0;
  double speed = 0;

  int elapsedSeconds = 0;

  Timer? timer;
  StreamSubscription<Position>? positionStream;

  bool locationReady = false;
  bool locating = false;
  String? locationError;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _getLocation();
  }

  Future<void> _loadSettings() async {
    final data = await TaxiSettings.load();
    if (!mounted) return;

    setState(() {
      baseFare = data['base'] as double;
      perKmRate = data['rate'] as double;

      if (status == TripStatus.idle) {
        fare = 0;
      } else {
        fare = baseFare + distanceKm * perKmRate;
      }
    });
  }

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        setState(() {
          locationError = 'شغّل خدمة الموقع GPS من الهاتف';
        });
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (mounted) {
        setState(() => locationError = 'إذن الموقع مرفوض');
      }
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          locationError = 'فعّل إذن الموقع من إعدادات التطبيق';
        });
      }
      return false;
    }

    return true;
  }

  Future<void> _getLocation() async {
    if (locating) return;

    setState(() {
      locating = true;
      locationError = null;
    });

    try {
      if (!await _ensurePermission()) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;

      currentLocation = LatLng(pos.latitude, pos.longitude);
      locationReady = true;

      setState(() {});

      try {
        mapController.move(currentLocation, 16);
      } catch (_) {
        // قد لا يكون عنصر الخريطة قد اكتمل بناؤه بعد.
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          locationError = 'تعذّر تحديد الموقع. تحقق من GPS والإنترنت.';
        });
      }
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> _startTrip() async {
    if (!await _ensurePermission()) {
      if (mounted && locationError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(locationError!)),
        );
      }
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;

      currentLocation = LatLng(pos.latitude, pos.longitude);
      lastTripPosition = currentLocation;

      setState(() {
        status = TripStatus.running;
        distanceKm = 0;
        elapsedSeconds = 0;
        speed = 0;
        fare = baseFare;
        locationReady = true;
      });

      _startTimer();
      _startTracking();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذّر الحصول على موقع GPS لبدء المشوار'),
        ),
      );
    }
  }

  void _startTimer() {
    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || status != TripStatus.running) return;

      setState(() {
        elapsedSeconds++;
      });
    });
  }

  void _startTracking() {
    positionStream?.cancel();

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen(
      (position) {
        if (!mounted || status != TripStatus.running) return;

        final next = LatLng(position.latitude, position.longitude);

        if (lastTripPosition != null) {
          final meters = Geolocator.distanceBetween(
            lastTripPosition!.latitude,
            lastTripPosition!.longitude,
            next.latitude,
            next.longitude,
          );

          // تجاهل الانجراف البسيط في GPS أثناء التوقف.
          if (meters >= 3 && meters < 100) {
            distanceKm += meters / 1000.0;
          }
        }

        lastTripPosition = next;
        currentLocation = next;

        if (position.speed >= 0) {
          speed = position.speed * 3.6;
        }

        fare = baseFare + distanceKm * perKmRate;

        setState(() {});

        try {
          mapController.move(currentLocation, 16);
        } catch (_) {}
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          locationError = 'انقطع تحديث الموقع. تحقق من GPS.';
        });
      },
    );
  }

  void _pauseTrip() {
    if (status != TripStatus.running) return;

    timer?.cancel();
    timer = null;

    positionStream?.cancel();
    positionStream = null;

    setState(() {
      status = TripStatus.paused;
      speed = 0;
    });
  }

  void _resumeTrip() {
    if (status != TripStatus.paused) return;

    setState(() {
      status = TripStatus.running;
    });

    // إعادة أخذ الموقع لتجنب احتساب المسافة أثناء التوقف.
    _refreshPositionForResume();
  }

  Future<void> _refreshPositionForResume() async {
    if (!await _ensurePermission()) {
      if (mounted) {
        setState(() => status = TripStatus.paused);
      }
      return;
    }

    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted || status != TripStatus.running) return;

      currentLocation = LatLng(p.latitude, p.longitude);
      lastTripPosition = currentLocation;

      _startTimer();
      _startTracking();

      setState(() {});
    } catch (_) {
      if (!mounted) return;

      setState(() {
        status = TripStatus.paused;
        locationError = 'تعذّر استئناف GPS. حاول مجددًا.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذّر استئناف المشوار بسبب الموقع'),
        ),
      );
    }
  }

  Future<void> _finishTrip() async {
    if (status == TripStatus.idle) return;

    timer?.cancel();
    timer = null;

    await positionStream?.cancel();
    positionStream = null;

    setState(() {
      status = TripStatus.idle;
      speed = 0;
    });

    if (!mounted) return;
    _showSummary();
  }

  void _showSummary() {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: panel,
        title: const Text(
          'ملخص المشوار 🏁',
          textAlign: TextAlign.center,
          style: TextStyle(color: gold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _summaryRow('المسافة', '${distanceKm.toStringAsFixed(2)} كم'),
            _summaryRow('الوقت', '$minutes دقيقة و$seconds ثانية'),
            const Divider(color: Colors.white24),
            _summaryRow(
              'الأجرة النهائية',
              '${fare.toStringAsFixed(0)} ريال',
              highlight: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('تم', style: TextStyle(color: gold)),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String title, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: highlight ? gold : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: highlight ? 18 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get timeText {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get statusText {
    switch (status) {
      case TripStatus.idle:
        return 'جاهز لبدء مشوار';
      case TripStatus.running:
        return 'المشوار جارٍ';
      case TripStatus.paused:
        return 'المشوار متوقف مؤقتًا';
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    positionStream?.cancel();
    super.dispose();
  }Dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: currentLocation,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.shahien.taxi',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentLocation,
                      width: 52,
                      height: 52,
                      child: const Icon(
                        Icons.navigation,
                        color: gold,
                        size: 40,
                      ),
                    ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),

            Positioned(
              top: 8,
              right: 12,
              left: 12,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xEE0D1117),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.local_taxi,
                              color: gold,
                              size: 32,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'عداد شاهين تاكسي',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    'رحلتك بأمان وبدون قلق',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'الإعدادات',
                              onPressed: widget.openSettings,
                              icon: const Icon(Icons.settings, color: gold),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _stat('السرعة', '${speed.toStringAsFixed(0)} كم/س',
                                Icons.speed),
                            _stat('المسافة',
                                '${distanceKm.toStringAsFixed(2)} كم',
                                Icons.route),
                            _stat('الوقت', timeText, Icons.access_time),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFA161B22),
                      border: Border.all(color: gold, width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'الأجرة الحالية',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${fare.toStringAsFixed(0)} ريال',
                          style: const TextStyle(
                            color: gold,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'أساسي ${baseFare.toStringAsFixed(0)} + '
                          '${perKmRate.toStringAsFixed(0)} ريال/كم',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: status == TripStatus.paused
                                ? Colors.orangeAccent
                                : status == TripStatus.running
                                    ? Colors.greenAccent
                                    : Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              right: 16,
              top: 330,
              child: FloatingActionButton.small(
                heroTag: 'locateTaxi',
                backgroundColor: panel,
                foregroundColor: gold,
                onPressed: _getLocation,
                child: locating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: gold,
                        ),
                      )
                    : const Icon(Icons.my_location),
              ),
            ),

            if (locationError != null)
              Positioned(
                top: 385,
                right: 16,
                left: 16,
                child: Material(
                  color: panel,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      locationError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                  ),
                ),
              ),

            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xF2161B22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: gold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            locationReady
                                ? 'تم تحديد موقع السائق'
                                : 'بانتظار تحديد موقع السائق',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Icon(
                          locationReady
                              ? Icons.gps_fixed
                              : Icons.gps_not_fixed,
                          color: locationReady
                              ? Colors.greenAccent
                              : Colors.orangeAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (status == TripStatus.idle)
                      _actionButton(
                        'ابدأ المشوار',
                        Icons.play_circle_fill,
                        gold,
                        _startTrip,
                      )
                    else if (status == TripStatus.running)
                      Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              'إيقاف مؤقت',
                              Icons.pause_circle_filled,
                              Colors.orangeAccent,
                              _pauseTrip,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _actionButton(
                              'إنهاء',
                              Icons.stop_circle,
                              Colors.redAccent,
                              _confirmFinish,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              'استئناف',
                              Icons.play_circle_fill,
                              gold,
                              _resumeTrip,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _actionButton(
                              'إنهاء',
                              Icons.stop_circle,
                              Colors.redAccent,
                              _confirmFinish,
                            ),
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
    );
  }

  Future<void> _confirmFinish() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: panel,
        title: const Text('إنهاء المشوار؟'),
        content: const Text(
          'سيتم إيقاف العدادات وعرض ملخص الرحلة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'إنهاء المشوار',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _finishTrip();
    }
  }

  Widget _stat(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: gold, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.black),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
