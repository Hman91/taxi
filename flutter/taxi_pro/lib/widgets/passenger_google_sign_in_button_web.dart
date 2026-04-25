import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart';

/// Official Google Identity Services button (`renderButton`). Web-only.
class PassengerGoogleGsiButton extends StatefulWidget {
  const PassengerGoogleGsiButton({super.key});

  @override
  State<PassengerGoogleGsiButton> createState() => _PassengerGoogleGsiButtonState();
}

class _PassengerGoogleGsiButtonState extends State<PassengerGoogleGsiButton> {
  late final Widget _gsiButton = renderButton(
    configuration: GSIButtonConfiguration(
      type: GSIButtonType.standard,
      theme: GSIButtonTheme.outline,
      size: GSIButtonSize.large,
      text: GSIButtonText.continueWith,
      minimumWidth: 280,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: 44,
        width: double.infinity,
        child: _gsiButton,
      ),
    );
  }
}
