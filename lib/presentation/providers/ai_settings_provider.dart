import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AISettingsProvider extends ChangeNotifier {
  bool _enablePredictions = true;
  bool _enableAnomalyDetection = true;
  bool _enableBudgetRecommendations = true;
  bool _enableSavingTips = true;

  // Getters
  bool get enablePredictions => _enablePredictions;
  bool get enableAnomalyDetection => _enableAnomalyDetection;
  bool get enableBudgetRecommendations => _enableBudgetRecommendations;
  bool get enableSavingTips => _enableSavingTips;

  // Keys for SharedPreferences
  static const String _keyPredictions = 'ai_predictions';
  static const String _keyAnomalyDetection = 'ai_anomaly_detection';
  static const String _keyBudgetRecommendations = 'ai_budget_recommendations';
  static const String _keySavingTips = 'ai_saving_tips';

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _enablePredictions = prefs.getBool(_keyPredictions) ?? true;
      _enableAnomalyDetection = prefs.getBool(_keyAnomalyDetection) ?? true;
      _enableBudgetRecommendations = prefs.getBool(_keyBudgetRecommendations) ?? true;
      _enableSavingTips = prefs.getBool(_keySavingTips) ?? true;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading AI settings: $e');
    }
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool(_keyPredictions, _enablePredictions);
      await prefs.setBool(_keyAnomalyDetection, _enableAnomalyDetection);
      await prefs.setBool(_keyBudgetRecommendations, _enableBudgetRecommendations);
      await prefs.setBool(_keySavingTips, _enableSavingTips);
    } catch (e) {
      debugPrint('Error saving AI settings: $e');
    }
  }

  /// Update predictions setting
  Future<void> setEnablePredictions(bool value) async {
    _enablePredictions = value;
    notifyListeners();
    await _saveSettings();
  }

  /// Update anomaly detection setting
  Future<void> setEnableAnomalyDetection(bool value) async {
    _enableAnomalyDetection = value;
    notifyListeners();
    await _saveSettings();
  }

  /// Update budget recommendations setting
  Future<void> setEnableBudgetRecommendations(bool value) async {
    _enableBudgetRecommendations = value;
    notifyListeners();
    await _saveSettings();
  }

  /// Update saving tips setting
  Future<void> setEnableSavingTips(bool value) async {
    _enableSavingTips = value;
    notifyListeners();
    await _saveSettings();
  }

  /// Reset all settings to default
  Future<void> resetToDefaults() async {
    _enablePredictions = true;
    _enableAnomalyDetection = true;
    _enableBudgetRecommendations = true;
    _enableSavingTips = true;
    
    notifyListeners();
    await _saveSettings();
  }
}