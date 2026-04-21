import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hulu_coffee_pos/features/splash/splash_screen.dart';
import 'package:hulu_coffee_pos/features/auth/presentation/screens/login_screen.dart';
import 'package:hulu_coffee_pos/features/pos/pos_home_screen.dart';
import 'package:hulu_coffee_pos/features/cart_order/cart_screen.dart';
import 'package:hulu_coffee_pos/features/payment/qris_payment_screen.dart';
import 'package:hulu_coffee_pos/features/payment/payment_success_screen.dart';
import 'package:hulu_coffee_pos/features/orders/queue_screen.dart';
import 'package:hulu_coffee_pos/features/reports/sales_dashboard_screen.dart';
import 'package:hulu_coffee_pos/features/menu/menu_management_screen.dart';
import 'package:hulu_coffee_pos/features/settings/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const PosHomeScreen(),
      ),
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/payment',
        name: 'payment',
        builder: (context, state) => const QrisPaymentScreen(),
      ),
      GoRoute(
        path: '/payment-success',
        name: 'payment_success',
        builder: (context, state) => const PaymentSuccessScreen(),
      ),
      GoRoute(
        path: '/queue',
        name: 'queue',
        builder: (context, state) => const OrderQueueScreen(),
      ),
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (context, state) => const SalesDashboardScreen(),
      ),
      GoRoute(
        path: '/menu',
        name: 'menu',
        builder: (context, state) => const MenuManagementScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
