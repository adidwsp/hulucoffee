import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hulu_coffee_pos/features/splash/splash_screen.dart';
import 'package:hulu_coffee_pos/features/auth/presentation/screens/login_screen.dart';
import 'package:hulu_coffee_pos/features/dashboard/dashboard_screen.dart';
import 'package:hulu_coffee_pos/features/pos/pos_home_screen.dart';
import 'package:hulu_coffee_pos/features/cart_order/cart_screen.dart';
import 'package:hulu_coffee_pos/features/payment/qris_payment_screen.dart';
import 'package:hulu_coffee_pos/features/payment/payment_success_screen.dart';
import 'package:hulu_coffee_pos/features/orders/transaction_history_screen.dart';
import 'package:hulu_coffee_pos/features/reports/sales_dashboard_screen.dart';
import 'package:hulu_coffee_pos/features/menu/menu_management_screen.dart';
import 'package:hulu_coffee_pos/features/menu/product_form_page.dart';
import 'package:hulu_coffee_pos/features/settings/settings_screen.dart';
import 'package:hulu_coffee_pos/shared/models/product_models.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', name: 'splash',
          builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', name: 'login',
          builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/dashboard', name: 'dashboard',
          builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/home', name: 'home',
          builder: (context, state) => const PosHomeScreen()),
      GoRoute(path: '/cart', name: 'cart',
          builder: (context, state) => const CartScreen()),
      GoRoute(path: '/payment', name: 'payment',
          builder: (context, state) => const QrisPaymentScreen()),
      GoRoute(path: '/payment-success', name: 'payment_success',
          builder: (context, state) => const PaymentSuccessScreen()),
      GoRoute(path: '/history', name: 'history',
          builder: (context, state) => const TransactionHistoryScreen()),
      GoRoute(path: '/reports', name: 'reports',
          builder: (context, state) => const SalesDashboardScreen()),
      GoRoute(path: '/menu', name: 'menu',
          builder: (context, state) => const MenuManagementScreen()),
      GoRoute(
        path: '/product-form',
        name: 'product_form',
        builder: (context, state) =>
            ProductFormPage(product: state.extra as Product?),
      ),
      GoRoute(path: '/settings', name: 'settings',
          builder: (context, state) => const SettingsScreen()),
    ],
  );
});
