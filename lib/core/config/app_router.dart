import 'package:flutter/material.dart';
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
import 'package:hulu_coffee_pos/features/pos/providers/cart_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', name: 'splash',
          pageBuilder: (context, state) => const NoTransitionPage(
              child: SplashScreen())),
      GoRoute(path: '/login', name: 'login',
          pageBuilder: (context, state) => const NoTransitionPage(
              child: LoginScreen())),
      GoRoute(path: '/dashboard', name: 'dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen())),
      GoRoute(path: '/home', name: 'home',
          pageBuilder: (context, state) => const NoTransitionPage(
              child: PosHomeScreen())),
      GoRoute(path: '/cart', name: 'cart',
          pageBuilder: (context, state) => const NoTransitionPage(
              child: CartScreen())),
      GoRoute(path: '/payment', name: 'payment',
          pageBuilder: (context, state) => const NoTransitionPage(
              child: QrisPaymentScreen())),
      GoRoute(path: '/payment-success', name: 'payment_success',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return NoTransitionPage(
                child: PaymentSuccessScreen(
                    cartState: extra?['cart'] as CartState?,
                    paymentMethod: extra?['paymentMethod'] as String?));
          }),
      GoRoute(path: '/history', name: 'history',
          pageBuilder: (context, state) => const NoTransitionPage(
              child: TransactionHistoryScreen())),
      GoRoute(path: '/reports', name: 'reports',
          pageBuilder: (context, state) => const NoTransitionPage(
              child: SalesDashboardScreen())),
      GoRoute(path: '/menu', name: 'menu',
          pageBuilder: (context, state) => const NoTransitionPage(
              child: MenuManagementScreen())),
      GoRoute(
        path: '/product-form',
        name: 'product_form',
        pageBuilder: (context, state) => NoTransitionPage(
            child: ProductFormPage(product: state.extra as Product?)),
      ),
      GoRoute(path: '/settings', name: 'settings',
          pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen())),
    ],
  );
});
