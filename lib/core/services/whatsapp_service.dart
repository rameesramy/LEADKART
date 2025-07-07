import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static Future<bool> openWhatsApp({
    required String phoneNumber,
    String? message,
  }) async {
    // Remove any non-digit characters from phone number
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Ensure phone number starts with country code
    if (!cleanPhone.startsWith('91') && cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone'; // Assuming Indian numbers
    }

    String encodedMessage = '';
    if (message != null && message.isNotEmpty) {
      encodedMessage = Uri.encodeComponent(message);
    }

    final whatsappUrl = 'https://wa.me/$cleanPhone?text=$encodedMessage';

    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      print('Error opening WhatsApp: $e');
      return false;
    }
  }

  static Future<bool> contactCustomer({
    required String customerPhone,
    required String productName,
    required String orderDetails,
  }) async {
    final message =
        'Hi! I have an update regarding your order for $productName. $orderDetails';
    return await openWhatsApp(phoneNumber: customerPhone, message: message);
  }

  static Future<bool> contactSeller({
    required String sellerPhone,
    required String productName,
    String? customerName,
  }) async {
    final message =
        customerName != null
            ? 'Hi! I\'m interested in your product "$productName". Could you please provide more details?'
            : 'Hi! I\'m interested in your product "$productName". Could you please provide more details?';

    return await openWhatsApp(phoneNumber: sellerPhone, message: message);
  }

  static Future<bool> sendMessage({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Clean phone number (remove any non-digit characters except +)
      String cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // Add country code if not present (assuming India +91)
      if (!cleanedPhone.startsWith('+')) {
        if (cleanedPhone.startsWith('91')) {
          cleanedPhone = '+$cleanedPhone';
        } else {
          cleanedPhone = '+91$cleanedPhone';
        }
      }

      // Encode the message for URL
      String encodedMessage = Uri.encodeComponent(message);

      // Create WhatsApp URL
      final whatsappUrl = 'https://wa.me/$cleanedPhone?text=$encodedMessage';

      // Launch WhatsApp
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        print('Could not launch WhatsApp');
        return false;
      }
    } catch (e) {
      print('Error sending WhatsApp message: $e');
      return false;
    }
  }

  static Future<bool> sendOrderToSeller({
    required String sellerPhone,
    required String productName,
    required int quantity,
    required double totalPrice,
    required String customerName,
    required String customerPhone,
  }) async {
    final message = '''
Hi! I would like to place an order:

🛍️ Product: $productName
📦 Quantity: $quantity
💰 Total: ₹${totalPrice.toStringAsFixed(0)}

👤 Customer Details:
Name: $customerName
Phone: $customerPhone

Please confirm the order. Thank you!
''';

    return await sendMessage(phoneNumber: sellerPhone, message: message);
  }
}
