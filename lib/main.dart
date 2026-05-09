import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
import 'screens/shared/splash_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/farmer/farmer_home_screen.dart';
import 'screens/farmer/add_product_screen.dart';
import 'screens/buyer/buyer_home_screen.dart';
import 'screens/buyer/product_detail_screen.dart';
import 'screens/transporter/transporter_home_screen.dart';
import 'screens/shared/orders_screen.dart';
import 'screens/shared/mandi_rates_screen.dart';
import 'screens/shared/logistics_screen.dart';
import 'screens/shared/notifications_screen.dart';
import 'screens/shared/profile_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'models/product_model.dart';
import 'services/asset_image_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Asset product images ko local storage mein copy karo (sirf pehli baar)
  await AssetImageService.copyAssetsToLocal();

  runApp(const KisanDostApp());
}

class KisanDostApp extends StatelessWidget {
  const KisanDostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: _generateRoute,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        ),
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _fade(const SplashScreen());
      case AppRoutes.onboarding:
        return _slide(const OnboardingScreen());
      case AppRoutes.login:
        return _fade(const LoginScreen());
      case AppRoutes.signup:
        return _slide(const SignupScreen());
      case AppRoutes.farmerHome:
        return _fade(const FarmerHomeScreen());
      case AppRoutes.buyerHome:
        return _fade(const BuyerHomeScreen());
      case AppRoutes.transporterHome:
        return _fade(const TransporterHomeScreen());
      case AppRoutes.addProduct:
        return _slide(const AddProductScreen());
      case AppRoutes.editProduct:
        return _slide(
            AddProductScreen(editProduct: settings.arguments as ProductModel));
      case AppRoutes.productDetail:
        return _slide(
            ProductDetailScreen(product: settings.arguments as ProductModel));
      case AppRoutes.orders:
        return _slide(
            OrdersScreen(isFarmer: settings.arguments as bool? ?? false));
      case AppRoutes.mandiRates:
        return _slide(const MandiRatesScreen());
      case AppRoutes.logistics:
        return _slide(const LogisticsScreen());
      case AppRoutes.notifications:
        return _slide(const NotificationsScreen());
      case AppRoutes.profile:
        return _slide(const ProfileScreen());
      case AppRoutes.adminHome:
        return _fade(const AdminHomeScreen());
      case AppRoutes.editProfile:
        return _slide(const EditProfileScreen());
      default:
        return _fade(const SplashScreen());
    }
  }

  PageRoute _fade(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 250),
      );

  PageRoute _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, a, __, c) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOutCubic))
              .animate(a),
          child: c,
        ),
        transitionDuration: const Duration(milliseconds: 280),
      );
}
