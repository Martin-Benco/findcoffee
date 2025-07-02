import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/firebase_service.dart';

class CafeInfoBottomSheet extends StatelessWidget {
  final Cafe cafe;
  const CafeInfoBottomSheet({Key? key, required this.cafe}) : super(key: key);

  String _getTodayKey() {
    final now = DateTime.now();
    switch (now.weekday) {
      case DateTime.monday:
        return 'Po';
      case DateTime.tuesday:
        return 'Ut';
      case DateTime.wednesday:
        return 'St';
      case DateTime.thursday:
        return 'Št';
      case DateTime.friday:
        return 'Pi';
      case DateTime.saturday:
        return 'So';
      case DateTime.sunday:
        return 'Ne';
      default:
        return '';
    }
  }

  bool _isOpenNow(String hours) {
    if (hours.toLowerCase().contains('zatvor')) return false;
    final now = TimeOfDay.now();
    final parts = hours.split('–');
    if (parts.length != 2) return true;
    final start = parts[0].trim();
    final end = parts[1].trim();
    TimeOfDay? startTime = _parseTime(start);
    TimeOfDay? endTime = _parseTime(end);
    if (startTime == null || endTime == null) return true;
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }

  TimeOfDay? _parseTime(String str) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(str);
    if (match == null) return null;
    return TimeOfDay(hour: int.parse(match.group(1)!), minute: int.parse(match.group(2)!));
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final todayKey = _getTodayKey();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: FutureBuilder<List<OpeningHours>>(
        future: firebaseService.getOpeningHours(cafe.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final hoursList = snapshot.data!;
          final today = hoursList.firstWhere(
            (h) => h.den == todayKey,
            orElse: () => OpeningHours(den: todayKey, hodiny: 'Neznáme'),
          );
          final isOpen = _isOpenNow(today.hodiny);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Image.network(
                  cafe.foto_url,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    color: Colors.grey[300],
                    child: const Center(child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cafe.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          isOpen ? Icons.check_circle : Icons.cancel,
                          color: isOpen ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOpen ? 'Otvorené' : 'Zatvorené',
                          style: TextStyle(
                            color: isOpen ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dnešné otváracie hodiny:',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      today.hodiny,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 22),
                        const SizedBox(width: 4),
                        Text(
                          cafe.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 