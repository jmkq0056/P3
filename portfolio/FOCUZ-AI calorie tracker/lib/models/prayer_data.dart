import 'package:cloud_firestore/cloud_firestore.dart';

// Enum for the five daily prayers
enum PrayerType {
  fajr('Fajr'),
  dhuhr('Dhuhr'),
  asr('Asr'),
  maghrib('Maghrib'),
  isha('Isha');

  const PrayerType(this.displayName);
  final String displayName;
}

// Prayer times for a specific date
class PrayerTimes {
  final DateTime date;
  final DateTime fajr;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final double latitude;
  final double longitude;

  PrayerTimes({
    required this.date,
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.latitude,
    required this.longitude,
  });

  // Get prayer time by type
  DateTime getPrayerTime(PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
        return fajr;
      case PrayerType.dhuhr:
        return dhuhr;
      case PrayerType.asr:
        return asr;
      case PrayerType.maghrib:
        return maghrib;
      case PrayerType.isha:
        return isha;
    }
  }

  // Get current prayer based on current time
  PrayerType getCurrentPrayer(DateTime now) {
    if (now.isBefore(fajr)) return PrayerType.isha; // Before Fajr is still Isha time
    if (now.isBefore(dhuhr)) return PrayerType.fajr;
    if (now.isBefore(asr)) return PrayerType.dhuhr;
    if (now.isBefore(maghrib)) return PrayerType.asr;
    if (now.isBefore(isha)) return PrayerType.maghrib;
    return PrayerType.isha;
  }

  // Get next prayer based on current time
  ({PrayerType prayer, DateTime time}) getNextPrayer(DateTime now) {
    if (now.isBefore(fajr)) return (prayer: PrayerType.fajr, time: fajr);
    if (now.isBefore(dhuhr)) return (prayer: PrayerType.dhuhr, time: dhuhr);
    if (now.isBefore(asr)) return (prayer: PrayerType.asr, time: asr);
    if (now.isBefore(maghrib)) return (prayer: PrayerType.maghrib, time: maghrib);
    if (now.isBefore(isha)) return (prayer: PrayerType.isha, time: isha);
    
    // After Isha, next prayer is Fajr of the next day
    // This would need to be handled by getting tomorrow's prayer times
    return (prayer: PrayerType.fajr, time: fajr.add(const Duration(days: 1)));
  }

  // Convert to/from JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'date': Timestamp.fromDate(date),
      'fajr': Timestamp.fromDate(fajr),
      'dhuhr': Timestamp.fromDate(dhuhr),
      'asr': Timestamp.fromDate(asr),
      'maghrib': Timestamp.fromDate(maghrib),
      'isha': Timestamp.fromDate(isha),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    return PrayerTimes(
      date: (json['date'] as Timestamp).toDate(),
      fajr: (json['fajr'] as Timestamp).toDate(),
      dhuhr: (json['dhuhr'] as Timestamp).toDate(),
      asr: (json['asr'] as Timestamp).toDate(),
      maghrib: (json['maghrib'] as Timestamp).toDate(),
      isha: (json['isha'] as Timestamp).toDate(),
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
    );
  }

  factory PrayerTimes.fromApiResponse(Map<String, dynamic> apiData, DateTime date, double latitude, double longitude) {
    final timings = apiData['timings'] as Map<String, dynamic>;
    
    // Parse prayer times from API response
    DateTime parseTime(String timeStr) {
      // API returns time in format "HH:MM" or "HH:MM (timezone)"
      final cleanTime = timeStr.split(' ')[0]; // Remove timezone info if present
      final parts = cleanTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      return DateTime(date.year, date.month, date.day, hour, minute);
    }

    return PrayerTimes(
      date: date,
      fajr: parseTime(timings['Fajr']),
      dhuhr: parseTime(timings['Dhuhr']),
      asr: parseTime(timings['Asr']),
      maghrib: parseTime(timings['Maghrib']),
      isha: parseTime(timings['Isha']),
      latitude: latitude,
      longitude: longitude,
    );
  }
}

// Individual prayer entry with completion status and Sunnah tracking
class PrayerEntry {
  final PrayerType type;
  final DateTime scheduledTime;
  final bool fardPerformed;
  final DateTime? timeMarked;
  final Map<String, bool> sunnahs; // Sunnah prayers associated with this prayer
  final String? notes;

  PrayerEntry({
    required this.type,
    required this.scheduledTime,
    this.fardPerformed = false,
    this.timeMarked,
    this.sunnahs = const {},
    this.notes,
  });

  // Copy with method for updates
  PrayerEntry copyWith({
    PrayerType? type,
    DateTime? scheduledTime,
    bool? fardPerformed,
    DateTime? timeMarked,
    Map<String, bool>? sunnahs,
    String? notes,
  }) {
    return PrayerEntry(
      type: type ?? this.type,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      fardPerformed: fardPerformed ?? this.fardPerformed,
      timeMarked: timeMarked ?? this.timeMarked,
      sunnahs: sunnahs ?? this.sunnahs,
      notes: notes ?? this.notes,
    );
  }

  // Convert to/from JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'fardPerformed': fardPerformed,
      'timeMarked': timeMarked != null ? Timestamp.fromDate(timeMarked!) : null,
      'sunnahs': sunnahs,
      'notes': notes,
    };
  }

  factory PrayerEntry.fromJson(Map<String, dynamic> json) {
    return PrayerEntry(
      type: PrayerType.values.firstWhere((e) => e.name == json['type']),
      scheduledTime: (json['scheduledTime'] as Timestamp).toDate(),
      fardPerformed: json['fardPerformed'] ?? false,
      timeMarked: json['timeMarked'] != null ? (json['timeMarked'] as Timestamp).toDate() : null,
      sunnahs: Map<String, bool>.from(json['sunnahs'] ?? {}),
      notes: json['notes'],
    );
  }

  // Get default Sunnah prayers for each prayer type
  static Map<String, bool> getDefaultSunnahs(PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
        return {'beforeFajr': false}; // 2 Rak'ah before Fajr
      case PrayerType.dhuhr:
        return {
          'beforeDhuhr': false, // 4 Rak'ah before Dhuhr
          'afterDhuhr': false,  // 2 Rak'ah after Dhuhr
        };
      case PrayerType.asr:
        return {'beforeAsr': false}; // 4 Rak'ah before Asr
      case PrayerType.maghrib:
        return {'afterMaghrib': false}; // 2 Rak'ah after Maghrib
      case PrayerType.isha:
        return {
          'afterIsha': false, // 2 Rak'ah after Isha
          'witr': false,      // Witr prayer
        };
    }
  }
}

// Daily prayer record - stores all prayers for a specific date
class PrayerRecord {
  final String id; // Format: "YYYY-MM-DD"
  final DateTime date;
  final Map<PrayerType, PrayerEntry> prayers;
  final int currentStreak;
  final DateTime? lastUpdated;

  PrayerRecord({
    required this.id,
    required this.date,
    required this.prayers,
    this.currentStreak = 0,
    this.lastUpdated,
  });

  // Get completion percentage for the day
  double get completionPercentage {
    final completedCount = prayers.values.where((entry) => entry.fardPerformed).length;
    return completedCount / prayers.length;
  }

  // Get total Sunnah completion for the day
  double get sunnahCompletionPercentage {
    int totalSunnahs = 0;
    int completedSunnahs = 0;
    
    for (final entry in prayers.values) {
      totalSunnahs += entry.sunnahs.length;
      completedSunnahs += entry.sunnahs.values.where((completed) => completed).length;
    }
    
    if (totalSunnahs == 0) return 0.0;
    return completedSunnahs / totalSunnahs;
  }

  // Check if all Fard prayers are completed
  bool get allFardCompleted => prayers.values.every((entry) => entry.fardPerformed);

  // Convert to/from JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'prayers': prayers.map((key, value) => MapEntry(key.name, value.toJson())),
      'currentStreak': currentStreak,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }

  factory PrayerRecord.fromJson(Map<String, dynamic> json) {
    final prayersMap = <PrayerType, PrayerEntry>{};
    final prayersData = json['prayers'] as Map<String, dynamic>? ?? {};
    
    for (final entry in prayersData.entries) {
      final prayerType = PrayerType.values.firstWhere((e) => e.name == entry.key);
      prayersMap[prayerType] = PrayerEntry.fromJson(entry.value);
    }

    return PrayerRecord(
      id: json['id'],
      date: (json['date'] as Timestamp).toDate(),
      prayers: prayersMap,
      currentStreak: json['currentStreak'] ?? 0,
      lastUpdated: json['lastUpdated'] != null ? (json['lastUpdated'] as Timestamp).toDate() : null,
    );
  }

  // Create a new prayer record for a date with prayer times
  factory PrayerRecord.createForDate(DateTime date, PrayerTimes prayerTimes) {
    final id = _formatDateId(date);
    final prayers = <PrayerType, PrayerEntry>{};
    
    for (final prayerType in PrayerType.values) {
      prayers[prayerType] = PrayerEntry(
        type: prayerType,
        scheduledTime: prayerTimes.getPrayerTime(prayerType),
        sunnahs: PrayerEntry.getDefaultSunnahs(prayerType),
      );
    }

    return PrayerRecord(
      id: id,
      date: date,
      prayers: prayers,
    );
  }

  // Helper method to format date as ID
  static String _formatDateId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
} 