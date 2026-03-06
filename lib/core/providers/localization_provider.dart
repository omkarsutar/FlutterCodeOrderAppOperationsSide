import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage { english, hindi, marathi }

class LanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => AppLanguage.hindi;

  void toggleLanguage() {
    if (state == AppLanguage.english) {
      state = AppLanguage.hindi;
    } else if (state == AppLanguage.hindi) {
      state = AppLanguage.marathi;
    } else {
      state = AppLanguage.english;
    }
  }

  void setLanguage(AppLanguage lang) {
    state = lang;
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, AppLanguage>(() {
  return LanguageNotifier();
});

final l10nProvider = Provider<Map<String, String>>((ref) {
  final lang = ref.watch(languageProvider);
  return _translations[lang] ?? _translations[AppLanguage.english]!;
});

const _translations = {
  AppLanguage.english: {
    'app_title': 'OrderZApp',
    'my_cart': 'My Cart',
    'products': 'Products',
    'search_hint': 'Search products...',
    'add_to_cart': 'Add to Cart',
    'items': 'Items',
    'shop_profit': 'Shop Profit on MRP',
    'final_amount': 'Final Amount',
    'add_items': 'Add Items',
    'empty_cart_btn': 'Empty Cart',
    'place_order': 'Place Order',
    'thank_you': 'Thank You!',
    'order_success': 'Your order has been placed successfully.',
    'continue_shopping': 'Continue Shopping',
    'empty_cart_msg': 'Your cart is empty',
    'go_to_products': 'Go to Products',
    'confirm': 'Confirm',
    'cancel': 'Cancel',
    'place_pending_order_title': 'Place Pending Order?',
    'place_pending_order_msg':
        'You have items in your cart. Do you want to place this order now?',
    'clear_cart_title': 'Empty Cart?',
    'clear_cart_msg': 'Remove all items?',
    'clear_all': 'Clear All',
    'cart_saved_login': 'Cart saved. Please login to complete your order.',
    'only_authorized_order': 'Only salesperson, and admin can place orders.',
    'logout': 'Logout',
    'profile': 'Profile',
    'orders': 'Orders',
    'home': 'Home',
    'welcome_orderzapp': 'Welcome to Orderzapp',
    'welcome_user': 'Welcome, {name}',
    'welcome_suffix': 'to Orderzapp',
    'role': 'Role',
    'purchase_history': 'Purchase History',
    'login': 'Login',
    'select': 'Select',
    'no_products_found': 'No products found',
    'no_matching_products': 'No matching products',
    'error_loading': 'Error loading',
    'no_internet': 'No internet connection. Please check your network.',
    'internet_connected': 'Back online!',
    'internet_disconnected': 'You are offline. Some features may not work.',
    'save_success': 'Saved successfully!',
    'delete_success': 'Deleted successfully!',
    'save_failed': 'Failed to save.',
    'delete_failed': 'Failed to delete.',
    'please_wait': 'Please wait...',
  },
  AppLanguage.marathi: {
    'app_title': 'OrderZApp',
    'my_cart': ' माझे कार्ट',
    'products': 'सामानाची यादी',
    'search_hint': 'सामान शोधा...',
    'add_to_cart': 'कार्टमध्ये टाका',
    'items': 'सामान',
    'shop_profit': 'दुकानाचा नफा (MRP वर)',
    'final_amount': 'एकूण रक्कम',
    'add_items': 'सामान वाढवा',
    'empty_cart_btn': 'कार्ट रिकामे करा',
    'place_order': 'ऑर्डर करा',
    'thank_you': 'धन्यवाद!',
    'order_success': 'आपली ऑर्डर यशस्वीरीत्या पूर्ण झाली आहे.',
    'continue_shopping': 'खरेदी सुरू ठेवा',
    'empty_cart_msg': 'आपले कार्ट रिकामे आहे',
    'go_to_products': 'सामान पहा',
    'confirm': 'ठीक आहे',
    'cancel': 'रद्द करा',
    'place_pending_order_title': 'जुनी ऑर्डर पूर्ण करायची का?',
    'place_pending_order_msg':
        'आपल्या कार्टमध्ये जुने सामान आहे. आता ऑर्डर करायची आहे का?',
    'clear_cart_title': 'कार्ट रिकामे करायचे का?',
    'clear_cart_msg': 'सर्व सामान काढून टाका?',
    'clear_all': 'सर्व काढा',
    'cart_saved_login': 'कार्ट सेव्ह झाले आहे. ऑर्डरसाठी लॉगिन करा.',
    'only_authorized_order': 'फक्त सेल्सपर्सन आणि एडमिन ऑर्डर करू शकतात.',
    'logout': 'लॉग आउट',
    'profile': 'माझे प्रोफाइल',
    'orders': 'माझी ऑर्डर',
    'home': 'All',
    'welcome_orderzapp': 'OrderZApp मध्ये स्वागत आहे',
    'welcome_user': 'स्वागत आहे, {name}',
    'welcome_suffix': 'OrderZApp मध्ये',
    'role': 'Role',
    'purchase_history': 'जुने ऑर्डर',
    'login': 'लॉगिन करा',
    'select': 'निवडा',
    'no_products_found': 'कोणतेही सामान सापडले नाही',
    'no_matching_products': 'जुळणारे सामान सापडले नाही',
    'error_loading': 'क्षमस्व, लोड होत नाही',
    'no_internet': 'इंटरनेट कनेक्शन नाही. कृपया तुमचे नेटवर्क तपासा.',
    'internet_connected': 'इंटरनेट परत आले!',
    'internet_disconnected': 'तुम्ही ऑफलाइन आहात. काही सुविधा काम करणार नाहीत.',
    'save_success': 'यशस्वीरीत्या सेव्ह झाले!',
    'delete_success': 'यशस्वीरीत्या डिलीट झाले!',
    'save_failed': 'सेव्ह होऊ शकले नाही.',
    'delete_failed': 'डिलीट होऊ शकले नाही.',
    'please_wait': 'कृपया थांबा..',
  },
  AppLanguage.hindi: {
    'app_title': 'OrderZApp',
    'my_cart': 'मेरा कार्ट',
    'products': 'सामान सूची',
    'search_hint': 'सामान खोजें...',
    'add_to_cart': 'कार्ट में डालें',
    'items': 'सामान',
    'shop_profit': 'दुकान का मुनाफा (MRP पर)',
    'final_amount': 'कुल रकम',
    'add_items': 'सामान जोड़ें',
    'empty_cart_btn': 'कार्ट खाली करें',
    'place_order': 'ऑर्डर करें',
    'thank_you': 'धन्यवाद!',
    'order_success': 'आपका ऑर्डर सफलतापूर्वक हो गया है।',
    'continue_shopping': 'खरीदारी जारी रखें',
    'empty_cart_msg': 'आपका कार्ट खाली है',
    'go_to_products': 'सामान देखें',
    'confirm': 'ठीक है',
    'cancel': 'रद्द करें',
    'place_pending_order_title': 'पुराना ऑर्डर पूरा करें?',
    'place_pending_order_msg':
        'आपके कार्ट में पुराना सामान है। क्या आप अभी ऑर्डर करना चाहते हैं?',
    'clear_cart_title': 'कार्ट खाली करें?',
    'clear_cart_msg': 'सारे सामान हटाएँ?',
    'clear_all': 'सब हटाएँ',
    'cart_saved_login': 'कार्ट सेव हो गया। ऑर्डर के लिए लॉगिन करें।',
    'only_authorized_order': 'केवल सेल्सपर्सन और एडमिन ही ऑर्डर कर सकते हैं।',
    'logout': 'लॉग आउट',
    'profile': 'मेरा प्रोफ़ाइल',
    'orders': 'मेरे ऑर्डर',
    'home': 'All',
    'welcome_orderzapp': 'OrderZApp में स्वागत है',
    'welcome_user': 'स्वागत है, {name}',
    'welcome_suffix': 'OrderZApp में',
    'role': 'Role',
    'purchase_history': 'पुराने ऑर्डर',
    'login': 'लॉगिन करें',
    'select': 'चुनें',
    'no_products_found': 'कोई सामान नहीं मिला',
    'no_matching_products': 'मिलता-जुलता सामान नहीं मिला',
    'error_loading': 'क्षमा करें, लोड नहीं हो पाया',
    'no_internet': 'इंटरनेट कनेक्शन नहीं है। कृपया अपना नेटवर्क जांचें।',
    'internet_connected': 'इंटरनेट वापस आ गया!',
    'internet_disconnected': 'आप ऑफलाइन हैं। कुछ सुविधाएँ काम नहीं करेंगी।',
    'save_success': 'सफलतापूर्वक सेव हो गया!',
    'delete_success': 'सफलतापूर्वक डिलीट हो गया!',
    'save_failed': 'सेव नहीं हो पाया।',
    'delete_failed': 'डिलीट नहीं हो पाया।',
    'please_wait': 'कृपया प्रतीक्षा करें...',
  },
};
