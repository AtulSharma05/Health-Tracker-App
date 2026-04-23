import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard_page.dart';
import 'analytics_page.dart';
import 'features_page.dart';
import 'profile_page.dart';
import '../services/meal_service.dart';
import '../services/profile_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<MealService>().fetchMeals();
      await context.read<ProfileService>().fetchProfile();
      if (!mounted) return;
      if (context.read<ProfileService>().profile == null) {
        Navigator.pushNamed(context, '/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const AnalyticsPage(),
      DashboardPage(onSwitchTab: (v) => setState(() => _index = v)),
      FeaturesPage(onSwitchTab: (v) => setState(() => _index = v)),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (v) => setState(() => _index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.analytics), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'Features'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
