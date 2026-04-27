import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String baseUrl = 'https://aispending-production.up.railway.app';

  /// Dự đoán chi tiêu tháng tới
  static Future<Map<String, dynamic>?> predictMonthlySpending({
    required String userId,
    required List<Map<String, dynamic>> transactions,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict/monthly-spending'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'transactions': transactions,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final prediction = data['prediction'];
          // Convert int to double if needed
          if (prediction['predicted_amount'] is int) {
            prediction['predicted_amount'] =
                (prediction['predicted_amount'] as int).toDouble();
          }
          if (prediction['confidence'] is int) {
            prediction['confidence'] =
                (prediction['confidence'] as int).toDouble();
          }
          return prediction;
        }
      }
    } catch (e) {
      print('AI Service Error (Monthly Prediction): $e');
    }
    return null;
  }

  /// Gợi ý ngân sách theo category
  static Future<Map<String, dynamic>?> getBudgetRecommendations({
    required String userId,
    required List<Map<String, dynamic>> transactions,
    double? monthlyIncome,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recommend/budget'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'transactions': transactions,
          'monthly_income': monthlyIncome,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['budget_recommendations'];
        }
      }
    } catch (e) {
      print('AI Service Error (Budget Recommendations): $e');
    }
    return null;
  }

  /// Phát hiện chi tiêu bất thường
  static Future<Map<String, dynamic>?> detectAnomalies({
    required String userId,
    required List<Map<String, dynamic>> transactions,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analyze/anomalies'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'transactions': transactions,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['analysis_result'];
        }
      }
    } catch (e) {
      print('AI Service Error (Anomaly Detection): $e');
    }
    return null;
  }

  /// Tìm cơ hội tiết kiệm
  static Future<List<dynamic>?> getSavingOpportunities({
    required String userId,
    required List<Map<String, dynamic>> transactions,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/insights/savings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'transactions': transactions,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['analysis_result']['saving_opportunities'];
        }
      }
    } catch (e) {
      print('AI Service Error (Saving Opportunities): $e');
    }
    return null;
  }

  /// Lấy tất cả insights cùng lúc
  static Future<Map<String, dynamic>?> getComprehensiveInsights({
    required String userId,
    required List<Map<String, dynamic>> transactions,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/insights/comprehensive'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'transactions': transactions,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['insights'];
        }
      }
    } catch (e) {
      print('AI Service Error (Comprehensive Insights): $e');
    }
    return null;
  }

  /// Kiểm tra server có hoạt động không
  static Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/'));
      return response.statusCode == 200;
    } catch (e) {
      print('AI Service Error (Health Check): $e');
      return false;
    }
  }
}
