import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_data.dart';
import 'package:intl/intl.dart';

class PrayerService {
  static final PrayerService _instance = PrayerService._internal();
  factory PrayerService() => _instance;
  PrayerService._internal();

  final Dio _dio = Dio();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cache for prayer times and location
  final Map<String, PrayerTimes> _prayerTimesCache = {};
  Position? _lastKnownPosition;
  DateTime? _lastLocationUpdate;
  Timer? _updateTimer;
  
  // Stream controllers for real-time updates
  final StreamController<PrayerTimes?> _currentPrayerTimesController = StreamController<PrayerTimes?>.broadcast();
  final StreamController<PrayerRecord?> _currentPrayerRecordController = StreamController<PrayerRecord?>.broadcast();
  
  // Store current values for immediate access
  PrayerTimes? _currentPrayerTimes;
  PrayerRecord? _currentPrayerRecord;
  
  // Getters for streams
  Stream<PrayerTimes?> get currentPrayerTimesStream => _currentPrayerTimesController.stream;
  Stream<PrayerRecord?> get currentPrayerRecordStream => _currentPrayerRecordController.stream;
  
  // Getters for current values (synchronous access)
  PrayerTimes? get currentPrayerTimes => _currentPrayerTimes;
  PrayerRecord? get currentPrayerRecord => _currentPrayerRecord;
  
  // Constants
  static const String _baseUrl = 'http://api.aladhan.com/v1';
  static const Duration _locationCacheTimeout = Duration(hours: 6);
  static const Duration _prayerTimesUpdateInterval = Duration(minutes: 30);
  
  bool _isInitialized = false;
  bool _isInitializing = false; // Add flag to prevent concurrent initialization
  User? _user;
  
  /// Initialize the prayer service
  Future<void> init() async {
    if (_isInitialized) return;
    
    // Prevent concurrent initialization
    if (_isInitializing) {
      debugPrint('🔄 Prayer Service: Already initializing, waiting...');
      // Wait for ongoing initialization to complete
      while (_isInitializing && !_isInitialized) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }
    
    _isInitializing = true;
    
    try {
      debugPrint('🕌 Starting Prayer Service initialization...');
      
      // Initialize Firebase Auth
      debugPrint('🔐 Checking Firebase Auth...');
      _user = FirebaseAuth.instance.currentUser;
      if (_user == null) {
        debugPrint('❌ User not authenticated');
        throw Exception('User must be logged in to use prayer features');
      }
      debugPrint('✅ User authenticated: ${_user!.uid}');
      
      // Load cached data
      debugPrint('💾 Loading cached data...');
      await _loadCachedData();
      debugPrint('✅ Cached data loaded');
      
      // Request location permission
      debugPrint('📍 Requesting location permission...');
      await _requestLocationPermission();
      debugPrint('✅ Location permission granted');
      
      // Get current location and prayer times
      debugPrint('🌍 Getting location and prayer times...');
      await _updateLocationAndPrayerTimes();
      debugPrint('✅ Location and prayer times updated');
      
      // IMMEDIATE FALLBACK: If no prayer times were emitted yet, create emergency times
      final today = DateTime.now();
      final cacheKey = '${today.year}-${today.month}-${today.day}';
      if (!_prayerTimesCache.containsKey(cacheKey)) {
        debugPrint('🚨 No prayer times in cache after initialization - creating immediate fallback...');
        await _createEmergencyFallbackTimes();
      } else {
        debugPrint('✅ Prayer times found in cache: ${_prayerTimesCache[cacheKey]?.fajr}');
      }
      
      // Start periodic updates
      debugPrint('⏰ Starting periodic updates...');
      _startPeriodicUpdates();
      debugPrint('✅ Periodic updates started');
      
      _isInitialized = true;
      debugPrint('✅ Prayer Service initialized successfully');
      
      // FINAL CHECK: Ensure we have emitted something to the stream
      final currentDate = DateTime.now();
      final currentCacheKey = '${currentDate.year}-${currentDate.month}-${currentDate.day}';
      final cachedTimes = _prayerTimesCache[currentCacheKey];
      if (cachedTimes != null) {
        debugPrint('🔄 Final emission: Sending cached prayer times to stream');
        _currentPrayerTimes = cachedTimes; // Store current value
        _currentPrayerTimesController.add(cachedTimes);
      } else {
        debugPrint('🚨 CRITICAL: No prayer times available after full initialization!');
      }
    } catch (e) {
      debugPrint('❌ Error initializing Prayer Service: $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }
  
  /// Dispose of resources
  void dispose() {
    _updateTimer?.cancel();
    _currentPrayerTimesController.close();
    _currentPrayerRecordController.close();
  }
  
  /// Request location permission
  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable location services.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied. Prayer times require location access.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. Please enable them in settings.');
    }
  }
  
  /// Get current location
  Future<Position> _getCurrentLocation() async {
    // Use cached location if it's recent enough
    if (_lastKnownPosition != null && 
        _lastLocationUpdate != null && 
        DateTime.now().difference(_lastLocationUpdate!) < _locationCacheTimeout) {
      debugPrint('📍 Using cached location: ${_lastKnownPosition!.latitude}, ${_lastKnownPosition!.longitude}');
      return _lastKnownPosition!;
    }
    
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15), // Increased timeout
      ).timeout(
        const Duration(seconds: 20), // Additional timeout wrapper
        onTimeout: () {
          debugPrint('⚠️ Location request timed out');
          throw TimeoutException('Location request timed out', const Duration(seconds: 20));
        },
      );
      
      _lastKnownPosition = position;
      _lastLocationUpdate = DateTime.now();
      
      // Cache location in SharedPreferences
      await _cacheLocation(position);
      
      debugPrint('📍 Got fresh location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('❌ Error getting current location: $e');
      
      // Try to use last known position from cache
      if (_lastKnownPosition != null) {
        debugPrint('📍 Using cached location as fallback: ${_lastKnownPosition!.latitude}, ${_lastKnownPosition!.longitude}');
        return _lastKnownPosition!;
      }
      
      // If no cached location, use default coordinates (Copenhagen)
      debugPrint('📍 Using default coordinates (Copenhagen) as fallback');
      final defaultPosition = Position(
        latitude: 55.6761,
        longitude: 12.5683,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
      
      _lastKnownPosition = defaultPosition;
      _lastLocationUpdate = DateTime.now();
      
      return defaultPosition;
    }
  }
  
  /// Cache location data
  Future<void> _cacheLocation(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_latitude', position.latitude);
      await prefs.setDouble('last_longitude', position.longitude);
      await prefs.setString('last_location_update', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('❌ Error caching location: $e');
    }
  }
  
  /// Load cached data from SharedPreferences
  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load cached location
      final latitude = prefs.getDouble('last_latitude');
      final longitude = prefs.getDouble('last_longitude');
      final locationUpdateStr = prefs.getString('last_location_update');
      
      if (latitude != null && longitude != null && locationUpdateStr != null) {
        _lastKnownPosition = Position(
          latitude: latitude,
          longitude: longitude,
          timestamp: DateTime.parse(locationUpdateStr),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        _lastLocationUpdate = DateTime.parse(locationUpdateStr);
      }
    } catch (e) {
      debugPrint('❌ Error loading cached data: $e');
    }
  }
  
  /// Update location and fetch prayer times
  Future<void> _updateLocationAndPrayerTimes() async {
    try {
      debugPrint('🌍 Getting current location...');
      final position = await _getCurrentLocation();
      debugPrint('✅ Got location: ${position.latitude}, ${position.longitude}');
      
      final today = DateTime.now();
      
      debugPrint('📡 Fetching prayer times from API...');
      // Get prayer times for today and tomorrow with timeout
      await Future.wait([
        _fetchPrayerTimesForDate(today, position.latitude, position.longitude),
        _fetchPrayerTimesForDate(today.add(const Duration(days: 1)), position.latitude, position.longitude),
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('⚠️ Prayer times API timeout, creating fallback times...');
          throw TimeoutException('Prayer times API request timed out', const Duration(seconds: 15));
        },
      );
      debugPrint('✅ Prayer times fetched successfully from API');
      
      // Update current prayer record
      debugPrint('📝 Updating prayer record...');
      await _updateCurrentPrayerRecord();
      debugPrint('✅ Prayer record updated');
      
    } catch (e) {
      debugPrint('❌ Error updating location and prayer times: $e');
      
      // ALWAYS create fallback prayer times if API fails
      debugPrint('🔄 Creating fallback prayer times...');
      try {
        await _createTestPrayerTimes();
        debugPrint('✅ Fallback prayer times created successfully');
        
        // Still try to update prayer record with fallback times
        await _updateCurrentPrayerRecord();
        debugPrint('✅ Prayer record updated with fallback times');
      } catch (testError) {
        debugPrint('❌ Failed to create fallback prayer times: $testError');
        
        // FORCE create basic fallback as last resort
        debugPrint('🚨 Force creating emergency fallback prayer times...');
        await _createEmergencyFallbackTimes();
      }
    }
  }
  
  /// Create emergency fallback prayer times as last resort
  Future<void> _createEmergencyFallbackTimes() async {
    try {
      final today = DateTime.now();
      final baseDate = DateTime(today.year, today.month, today.day);
      
      // Create very basic prayer times
      final emergencyPrayerTimes = PrayerTimes(
        date: today,
        fajr: baseDate.add(const Duration(hours: 5, minutes: 30)),
        dhuhr: baseDate.add(const Duration(hours: 12, minutes: 30)),
        asr: baseDate.add(const Duration(hours: 15, minutes: 45)),
        maghrib: baseDate.add(const Duration(hours: 18, minutes: 15)),
        isha: baseDate.add(const Duration(hours: 19, minutes: 45)),
        latitude: 55.6761, // Copenhagen coordinates
        longitude: 12.5683,
      );
      
      // Cache the emergency prayer times
      final cacheKey = '${today.year}-${today.month}-${today.day}';
      _prayerTimesCache[cacheKey] = emergencyPrayerTimes;
      
      // FORCE emit to stream
      debugPrint('🚨 Force emitting emergency prayer times to stream...');
      _currentPrayerTimes = emergencyPrayerTimes; // Store current value
      _currentPrayerTimesController.add(emergencyPrayerTimes);
      debugPrint('✅ Emergency prayer times emitted successfully');
    } catch (e) {
      debugPrint('💥 CRITICAL: Emergency fallback also failed: $e');
      // At this point, we're in serious trouble, but at least log it
    }
  }
  
  /// Create test prayer times for development/testing
  Future<void> _createTestPrayerTimes() async {
    final today = DateTime.now();
    final baseDate = DateTime(today.year, today.month, today.day);
    
    // Create realistic prayer times based on current time
    final now = DateTime.now();
    DateTime fajrTime, dhuhrTime, asrTime, maghribTime, ishaTime;
    
    if (now.hour < 5) {
      // Before Fajr - use today's times
      fajrTime = baseDate.add(const Duration(hours: 5, minutes: 30));
      dhuhrTime = baseDate.add(const Duration(hours: 12, minutes: 30));
      asrTime = baseDate.add(const Duration(hours: 15, minutes: 45));
      maghribTime = baseDate.add(const Duration(hours: 18, minutes: 15));
      ishaTime = baseDate.add(const Duration(hours: 19, minutes: 45));
    } else {
      // After Fajr - ensure next prayer is in the future
      final currentHour = now.hour;
      fajrTime = currentHour < 6 ? baseDate.add(const Duration(hours: 5, minutes: 30)) : baseDate.add(const Duration(hours: 29, minutes: 30)); // Next day
      dhuhrTime = currentHour < 12 ? baseDate.add(const Duration(hours: 12, minutes: 30)) : baseDate.add(const Duration(hours: 36, minutes: 30)); // Next day
      asrTime = currentHour < 15 ? baseDate.add(const Duration(hours: 15, minutes: 45)) : baseDate.add(const Duration(hours: 39, minutes: 45)); // Next day
      maghribTime = currentHour < 18 ? baseDate.add(const Duration(hours: 18, minutes: 15)) : baseDate.add(const Duration(hours: 42, minutes: 15)); // Next day
      ishaTime = currentHour < 19 ? baseDate.add(const Duration(hours: 19, minutes: 45)) : baseDate.add(const Duration(hours: 43, minutes: 45)); // Next day
    }
    
    // Create mock prayer times for today
    final testPrayerTimes = PrayerTimes(
      date: today,
      fajr: fajrTime,
      dhuhr: dhuhrTime,
      asr: asrTime,
      maghrib: maghribTime,
      isha: ishaTime,
      latitude: _lastKnownPosition?.latitude ?? 55.6761, // Copenhagen coordinates as default
      longitude: _lastKnownPosition?.longitude ?? 12.5683,
    );
    
    // Cache the test prayer times
    final cacheKey = '${today.year}-${today.month}-${today.day}';
    _prayerTimesCache[cacheKey] = testPrayerTimes;
    
    // Notify listeners immediately
    _currentPrayerTimesController.add(testPrayerTimes);
    
    debugPrint('📅 Created fallback prayer times: Fajr: ${DateFormat('HH:mm').format(fajrTime)}, Dhuhr: ${DateFormat('HH:mm').format(dhuhrTime)}, Asr: ${DateFormat('HH:mm').format(asrTime)}, Maghrib: ${DateFormat('HH:mm').format(maghribTime)}, Isha: ${DateFormat('HH:mm').format(ishaTime)}');
  }
  
  /// Fetch prayer times for a specific date
  Future<PrayerTimes> _fetchPrayerTimesForDate(DateTime date, double latitude, double longitude) async {
    final cacheKey = '${date.year}-${date.month}-${date.day}';
    
    // Check cache first
    if (_prayerTimesCache.containsKey(cacheKey)) {
      return _prayerTimesCache[cacheKey]!;
    }
    
    try {
      final response = await _dio.get(
        '$_baseUrl/calendar/${date.year}/${date.month}',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'method': 99, // Custom calculation method
          'school': 1,  // Hanafi school
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        final dayData = data.firstWhere((day) => day['date']['readable'] == '${date.day.toString().padLeft(2, '0')} ${_getMonthName(date.month)} ${date.year}');
        
        final prayerTimes = PrayerTimes.fromApiResponse(dayData, date, latitude, longitude);
        
        // Cache the result
        _prayerTimesCache[cacheKey] = prayerTimes;
        
        // ALWAYS emit to stream for today's prayer times
        if (_isSameDay(date, DateTime.now())) {
          debugPrint('📡 API Success: Emitting prayer times to stream - Fajr: ${DateFormat('HH:mm').format(prayerTimes.fajr)}');
          _currentPrayerTimes = prayerTimes; // Store current value
          _currentPrayerTimesController.add(prayerTimes);
        }
        
        return prayerTimes;
      } else {
        throw Exception('Failed to fetch prayer times: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching prayer times for $date: $e');
      rethrow;
    }
  }
  
  /// Get prayer times for a specific date
  Future<PrayerTimes?> getPrayerTimesForDate(DateTime date) async {
    // Don't call init() recursively, instead return null if not initialized
    if (!_isInitialized) {
      debugPrint('❌ Cannot get prayer times - service not initialized yet');
      return null;
    }
    
    try {
      final position = await _getCurrentLocation();
      return await _fetchPrayerTimesForDate(date, position.latitude, position.longitude);
    } catch (e) {
      debugPrint('❌ Error getting prayer times for date: $e');
      return null;
    }
  }
  
  /// Get current prayer times (today)
  Future<PrayerTimes?> getCurrentPrayerTimes() async {
    return await getPrayerTimesForDate(DateTime.now());
  }
  
  /// Update current prayer record in Firestore
  Future<void> _updateCurrentPrayerRecord() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return; // Not authenticated
      
      final today = DateTime.now();
      
      // Get prayer times from cache instead of calling getCurrentPrayerTimes()
      // to avoid infinite loop during initialization
      final cacheKey = '${today.year}-${today.month}-${today.day}';
      final prayerTimes = _prayerTimesCache[cacheKey];
      if (prayerTimes == null) return; // Prayer times not available yet
      
      final recordId = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('prayer_records')
          .doc(recordId);
      
      final docSnapshot = await docRef.get();
      
      PrayerRecord prayerRecord;
      if (docSnapshot.exists) {
        // Update existing record
        prayerRecord = PrayerRecord.fromJson(docSnapshot.data()!);
      } else {
        // Create new record
        prayerRecord = PrayerRecord.createForDate(today, prayerTimes);
      }
      
      // Save to Firestore
      await docRef.set(prayerRecord.toJson(), SetOptions(merge: true));
      
      // Notify listeners
      _currentPrayerRecord = prayerRecord; // Store current value
      _currentPrayerRecordController.add(prayerRecord);
      
    } catch (e) {
      debugPrint('❌ Error updating current prayer record: $e');
    }
  }
  
  /// Mark a prayer as completed or uncompleted
  Future<void> markPrayerCompleted(PrayerType prayerType, {DateTime? date, bool? completed}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      final targetDate = date ?? DateTime.now();
      final recordId = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
      
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('prayer_records')
          .doc(recordId);
      
      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);
        
        PrayerRecord prayerRecord;
        if (docSnapshot.exists) {
          prayerRecord = PrayerRecord.fromJson(docSnapshot.data()!);
        } else {
          // Create new record if it doesn't exist
          // First try to get from cache, then fetch if needed
          final cacheKey = '${targetDate.year}-${targetDate.month}-${targetDate.day}';
          PrayerTimes? prayerTimes = _prayerTimesCache[cacheKey];
          
          // If not in cache, fetch it (but only if service is initialized)
          if (prayerTimes == null) {
            if (_isInitialized) {
              prayerTimes = await getPrayerTimesForDate(targetDate);
            }
            if (prayerTimes == null) throw Exception('Could not get prayer times for date');
          }
          
          prayerRecord = PrayerRecord.createForDate(targetDate, prayerTimes);
        }
        
        // Update the specific prayer
        final currentEntry = prayerRecord.prayers[prayerType];
        if (currentEntry != null) {
          final isCompleted = completed ?? true; // Default to true for backward compatibility
          final updatedEntry = currentEntry.copyWith(
            fardPerformed: isCompleted,
            timeMarked: isCompleted ? DateTime.now() : null, // Clear timeMarked if uncompleted
          );
          
          final updatedPrayers = Map<PrayerType, PrayerEntry>.from(prayerRecord.prayers);
          updatedPrayers[prayerType] = updatedEntry;
          
          final updatedRecord = PrayerRecord(
            id: prayerRecord.id,
            date: prayerRecord.date,
            prayers: updatedPrayers,
            currentStreak: prayerRecord.currentStreak,
            lastUpdated: DateTime.now(),
          );
          
          transaction.set(docRef, updatedRecord.toJson());
          
          // Update local stream if it's today's record
          if (_isSameDay(targetDate, DateTime.now())) {
            _currentPrayerRecord = updatedRecord; // Store current value
            _currentPrayerRecordController.add(updatedRecord);
          }
        }
      });
      
    } catch (e) {
      debugPrint('❌ Error marking prayer as completed: $e');
      rethrow;
    }
  }
  
  /// Toggle Fard prayer completion status
  Future<void> toggleFardPrayer(PrayerType prayerType, {DateTime? date}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      final targetDate = date ?? DateTime.now();
      final recordId = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
      
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('prayer_records')
          .doc(recordId);
      
      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);
        
        PrayerRecord prayerRecord;
        if (docSnapshot.exists) {
          prayerRecord = PrayerRecord.fromJson(docSnapshot.data()!);
        } else {
          // Create new record if it doesn't exist
          final cacheKey = '${targetDate.year}-${targetDate.month}-${targetDate.day}';
          PrayerTimes? prayerTimes = _prayerTimesCache[cacheKey];
          
          if (prayerTimes == null) {
            if (_isInitialized) {
              prayerTimes = await getPrayerTimesForDate(targetDate);
            }
            if (prayerTimes == null) throw Exception('Could not get prayer times for date');
          }
          
          prayerRecord = PrayerRecord.createForDate(targetDate, prayerTimes);
        }
        
        // Toggle the specific prayer
        final currentEntry = prayerRecord.prayers[prayerType];
        if (currentEntry != null) {
          final newStatus = !currentEntry.fardPerformed;
          final updatedEntry = currentEntry.copyWith(
            fardPerformed: newStatus,
            timeMarked: newStatus ? DateTime.now() : null,
          );
          
          final updatedPrayers = Map<PrayerType, PrayerEntry>.from(prayerRecord.prayers);
          updatedPrayers[prayerType] = updatedEntry;
          
          final updatedRecord = PrayerRecord(
            id: prayerRecord.id,
            date: prayerRecord.date,
            prayers: updatedPrayers,
            currentStreak: prayerRecord.currentStreak,
            lastUpdated: DateTime.now(),
          );
          
          transaction.set(docRef, updatedRecord.toJson());
          
          // Update local stream if it's today's record
          if (_isSameDay(targetDate, DateTime.now())) {
            _currentPrayerRecord = updatedRecord;
            _currentPrayerRecordController.add(updatedRecord);
          }
        }
      });
      
    } catch (e) {
      debugPrint('❌ Error toggling Fard prayer: $e');
      rethrow;
    }
  }
  
  /// Toggle Sunnah prayer completion
  Future<void> toggleSunnahPrayer(PrayerType prayerType, String sunnahKey, {DateTime? date}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      final targetDate = date ?? DateTime.now();
      final recordId = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
      
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('prayer_records')
          .doc(recordId);
      
      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);
        
        PrayerRecord prayerRecord;
        if (docSnapshot.exists) {
          prayerRecord = PrayerRecord.fromJson(docSnapshot.data()!);
        } else {
          // First try to get from cache, then fetch if needed
          final cacheKey = '${targetDate.year}-${targetDate.month}-${targetDate.day}';
          PrayerTimes? prayerTimes = _prayerTimesCache[cacheKey];
          
          // If not in cache, fetch it (but only if service is initialized)
          if (prayerTimes == null) {
            if (_isInitialized) {
              prayerTimes = await getPrayerTimesForDate(targetDate);
            }
            if (prayerTimes == null) throw Exception('Could not get prayer times for date');
          }
          
          prayerRecord = PrayerRecord.createForDate(targetDate, prayerTimes);
        }
        
        // Update the specific Sunnah
        final currentEntry = prayerRecord.prayers[prayerType];
        if (currentEntry != null) {
          final updatedSunnahs = Map<String, bool>.from(currentEntry.sunnahs);
          updatedSunnahs[sunnahKey] = !(updatedSunnahs[sunnahKey] ?? false);
          
          final updatedEntry = currentEntry.copyWith(sunnahs: updatedSunnahs);
          
          final updatedPrayers = Map<PrayerType, PrayerEntry>.from(prayerRecord.prayers);
          updatedPrayers[prayerType] = updatedEntry;
          
          final updatedRecord = PrayerRecord(
            id: prayerRecord.id,
            date: prayerRecord.date,
            prayers: updatedPrayers,
            currentStreak: prayerRecord.currentStreak,
            lastUpdated: DateTime.now(),
          );
          
          transaction.set(docRef, updatedRecord.toJson());
          
          // Update local stream if it's today's record
          if (_isSameDay(targetDate, DateTime.now())) {
            _currentPrayerRecord = updatedRecord; // Store current value
            _currentPrayerRecordController.add(updatedRecord);
          }
        }
      });
      
    } catch (e) {
      debugPrint('❌ Error toggling Sunnah prayer: $e');
      rethrow;
    }
  }
  
  /// Get prayer records for a date range
  Future<List<PrayerRecord>> getPrayerRecords({DateTime? startDate, DateTime? endDate}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];
      
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();
      
      final startId = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      final endId = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
      
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('prayer_records')
          .where('id', isGreaterThanOrEqualTo: startId)
          .where('id', isLessThanOrEqualTo: endId)
          .orderBy('id', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => PrayerRecord.fromJson(doc.data()))
          .toList();
      
    } catch (e) {
      debugPrint('❌ Error getting prayer records: $e');
      return [];
    }
  }
  
  /// Calculate current prayer streak
  Future<int> getCurrentPrayerStreak() async {
    try {
      final records = await getPrayerRecords(
        startDate: DateTime.now().subtract(const Duration(days: 365)),
        endDate: DateTime.now(),
      );
      
      int streak = 0;
      final today = DateTime.now();
      
      for (int i = 0; i < records.length; i++) {
        final record = records[i];
        final expectedDate = today.subtract(Duration(days: i));
        
        // Check if this record is for the expected date
        if (!_isSameDay(record.date, expectedDate)) break;
        
        // Check if all Fard prayers were completed
        if (record.allFardCompleted) {
          streak++;
        } else {
          break;
        }
      }
      
      return streak;
    } catch (e) {
      debugPrint('❌ Error calculating prayer streak: $e');
      return 0;
    }
  }
  
  /// Start periodic updates
  void _startPeriodicUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(_prayerTimesUpdateInterval, (timer) {
      _updateLocationAndPrayerTimes();
    });
  }
  
  /// Helper method to get month name
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
  
  /// Helper method to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
} 