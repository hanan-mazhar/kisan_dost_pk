class AppConstants {
  static const String appName = 'Kisan Dost PK';
  static const String appTagline = 'Empowering Farmers, Connecting Futures';

  // Roles
  static const String roleFarmer = 'farmer';
  static const String roleBuyer = 'buyer';
  static const String roleTransporter = 'transporter';
  static const String roleAdmin = 'admin';

  // Firestore Collections
  static const String usersCol = 'users';
  static const String productsCol = 'products';
  static const String ordersCol = 'orders';
  static const String mandiRatesCol = 'mandi_rates';
  static const String transportCol = 'transport_routes';
  static const String ratingsCol = 'ratings';
  static const String notificationsCol = 'notifications';
  static const String priceHistoryCol = 'price_history';

  // Order Status
  static const String statusPending = 'Pending';
  static const String statusAccepted = 'Accepted';
  static const String statusDelivered = 'Delivered';
  static const String statusRejected = 'Rejected';

  // Payment
  static const String paymentCOD = 'Cash on Delivery';
  static const String paymentEscrow = 'Escrow (Hold)';
  static const String paymentEasypaisa = 'Easypaisa';
  static const String paymentJazzCash = 'JazzCash';

  // Crop Categories
  static const List<String> cropCategories = [
    'All', 'Wheat', 'Rice', 'Maize', 'Tomato', 'Onion', 'Potato',
    'Sugarcane', 'Cotton', 'Mango', 'Citrus', 'Vegetables', 'Pulses', 'Other',
  ];

  // Hive
  static const String hiveProducts = 'cached_products';
  static const String hiveMandiRates = 'cached_mandi_rates';
  static const String hiveUserData = 'cached_user';

  // Prefs Keys
  static const String prefUserId = 'user_id';
  static const String prefUserRole = 'user_role';
  static const String prefOnboardingDone = 'onboarding_done';

  // Quick cities for dropdowns (top cities)
  static const List<String> cities = [
    'Lahore', 'Karachi', 'Islamabad', 'Rawalpindi', 'Faisalabad',
    'Multan', 'Peshawar', 'Quetta', 'Sialkot', 'Gujranwala',
    'Hyderabad', 'Bahawalpur', 'Sargodha', 'Sukkur', 'Larkana',
    'Sheikhupura', 'Jhang', 'Gujrat', 'Kasur', 'Okara',
  ];

  // ── ALL Pakistan Cities (for signup search) ───────────────────────────────
  static const List<String> allPakistanCities = [
    // Punjab
    'Lahore', 'Faisalabad', 'Rawalpindi', 'Gujranwala', 'Sargodha',
    'Multan', 'Bahawalpur', 'Sialkot', 'Sheikhupura', 'Jhang',
    'Gujrat', 'Kasur', 'Rahim Yar Khan', 'Okara', 'Sahiwal',
    'Wah Cantt', 'Dera Ghazi Khan', 'Muzaffargarh', 'Hafizabad',
    'Mianwali', 'Jhelum', 'Khushab', 'Bahawalnagar', 'Vehari',
    'Pakpattan', 'Nankana Sahib', 'Attock', 'Chakwal', 'Narowal',
    'Toba Tek Singh', 'Lodhran', 'Khanewal', 'Layyah', 'Mandi Bahauddin',
    'Chiniot', 'Bhakkar', 'Rajanpur', 'Murree', 'Taxila', 'Kamoke',
    'Daska', 'Wazirabad', 'Kamalia', 'Jaranwala', 'Sambrial',
    'Hafizabad', 'Pind Dadan Khan', 'Phalia', 'Kot Addu', 'Mailsi',
    'Burewala', 'Dipalpur', 'Ferozewala', 'Muridke', 'Chunian',
    'Patoki', 'Renala Khurd', 'Warburton', 'Pattoki', 'Arifwala',
    'Chichawatni', 'Kamalia', 'Piplan', 'Leiah', 'Taunsa',
    'Ahmadpur East', 'Hasilpur', 'Yazman', 'Liaquatpur', 'Fort Abbas',
    'Khairpur Tamewali', 'Harappa', 'Boson', 'Jalalpur Pirwala',
    'Shorkot', 'Ahmed Nager Chatha', 'Saddiqabad', 'Khanpur',

    // Sindh
    'Karachi', 'Hyderabad', 'Sukkur', 'Larkana', 'Nawabshah',
    'Mirpurkhas', 'Khairpur', 'Jacobabad', 'Shikarpur', 'Dadu',
    'Thatta', 'Badin', 'Tando Adam', 'Tando Allahyar', 'Sanghar',
    'Matiari', 'Umerkot', 'Jamshoro', 'Kotri', 'Ghotki',
    'Kashmore', 'Kamber', 'Shahdadkot', 'Qambar', 'Sehwan',
    'Kandhkot', 'Mehar', 'Johi', 'Digri', 'Mithi',
    'Tharparkar', 'Naushero Feroze', 'Kandiaro', 'Rohri', 'Pano Aqil',
    'Ranipur', 'Hala', 'Moro', 'Tandojam', 'Bulri Shah Karim',

    // Khyber Pakhtunkhwa
    'Peshawar', 'Mardan', 'Abbottabad', 'Mingora', 'Kohat',
    'Dera Ismail Khan', 'Nowshera', 'Charsadda', 'Bannu', 'Swabi',
    'Mansehra', 'Haripur', 'Karak', 'Hangu', 'Lakki Marwat',
    'Tank', 'Chitral', 'Buner', 'Dir', 'Malakand',
    'Shangla', 'Kohistan', 'Battagram', 'Torghar', 'Swat',
    'Parachinar', 'Dera Ismail Khan', 'Timergara', 'Chakdara',
    'Takht Bhai', 'Daggar', 'Matta', 'Alpuri',

    // Balochistan
    'Quetta', 'Turbat', 'Khuzdar', 'Hub', 'Chaman',
    'Gwadar', 'Kalat', 'Dera Bugti', 'Sibi', 'Nushki',
    'Mastung', 'Kharan', 'Panjgur', 'Washuk', 'Kech',
    'Loralai', 'Zhob', 'Musakhel', 'Barkhan', 'Ziarat',
    'Harnai', 'Qila Saifullah', 'Qila Abdullah', 'Pishin',
    'Killa Saifullah', 'Pasni', 'Ormara', 'Jiwani', 'Dalbandin',
    'Nokundi', 'Chaghi', 'Lasbela', 'Bela', 'Uthal',

    // Islamabad Capital Territory
    'Islamabad',

    // Azad Kashmir
    'Muzaffarabad', 'Mirpur', 'Rawalakot', 'Kotli', 'Bagh',
    'Haveli', 'Sudhnoti', 'Neelum', 'Poonch',

    // Gilgit-Baltistan
    'Gilgit', 'Skardu', 'Hunza', 'Nagar', 'Ghizer',
    'Diamer', 'Astore', 'Shigar', 'Kharmang', 'Ghanche',
  ];

  // Crop to emoji mapping
  static const Map<String, String> cropEmojis = {
    'Wheat': '🌾',
    'Rice': '🍚',
    'Maize': '🌽',
    'Tomato': '🍅',
    'Onion': '🧅',
    'Potato': '🥔',
    'Sugarcane': '🎋',
    'Cotton': '🪴',
    'Mango': '🥭',
    'Citrus': '🍊',
    'Vegetables': '🥦',
    'Pulses': '🫘',
    'Other': '🌿',
    'All': '🌿',
  };

  // Crop to color mapping (hex)
  static const Map<String, int> cropColors = {
    'Wheat': 0xFFF9A825,
    'Rice': 0xFF81C784,
    'Maize': 0xFFFFB300,
    'Tomato': 0xFFE53935,
    'Onion': 0xFF7B1FA2,
    'Potato': 0xFF795548,
    'Sugarcane': 0xFF388E3C,
    'Cotton': 0xFFB0BEC5,
    'Mango': 0xFFFF8F00,
    'Citrus': 0xFFF57C00,
    'Vegetables': 0xFF43A047,
    'Pulses': 0xFF6D4C41,
    'Other': 0xFF2E7D32,
  };

  static String getCropEmoji(String category) =>
      cropEmojis[category] ?? '🌿';

  static int getCropColor(String category) =>
      cropColors[category] ?? 0xFF2E7D32;
}

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String farmerHome = '/farmer/home';
  static const String buyerHome = '/buyer/home';
  static const String transporterHome = '/transporter/home';
  static const String addProduct = '/farmer/add-product';
  static const String editProduct = '/farmer/edit-product';
  static const String productDetail = '/product-detail';
  static const String orders = '/orders';
  static const String mandiRates = '/mandi-rates';
  static const String logistics = '/logistics';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String payment = '/payment';
  static const String adminHome = '/admin/home';
}
