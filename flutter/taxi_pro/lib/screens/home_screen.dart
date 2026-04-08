import 'package:flutter/material.dart';

import 'b2b_screen.dart';
import 'driver_screen.dart';
import 'operator_screen.dart';
import 'owner_screen.dart';
import 'passenger_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taxi Pro Tunisia'),
        backgroundColor: Colors.amber.shade800,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Login as / الدخول بصفتي',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _tile(context, 'Passenger / الحريف', Icons.person, const PassengerScreen()),
          _tile(context, 'Driver / السائق', Icons.local_taxi, const DriverScreen()),
          _tile(context, 'Owner / المالك', Icons.business_center, const OwnerScreen()),
          _tile(context, 'Operator / الموظف', Icons.headset_mic, const OperatorScreen()),
          _tile(context, 'B2B / الشركات', Icons.apartment, const B2bScreen()),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    String title,
    IconData icon,
    Widget page,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
        },
      ),
    );
  }
}
