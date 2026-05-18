import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const _serviceId = 'service_djv89l9';
  static const _templateId = 'template_nf8c68m';
  static const _publicKey = 'LuPYSpy9LzNBk0QRy';

  static Future<bool> sendSosAlert({
    required String caretakerEmail,
    required String elderName,
    required String alertTime,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'caretaker_email': caretakerEmail,
            'elder_name': elderName,
            'alert_time': alertTime,
            'message': '$elderName needs immediate help! Please respond now.',
            'to_email': caretakerEmail,
          },
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}