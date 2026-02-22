import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/repositories/win32_joystick_repository.dart';
import 'data/repositories/serial_transmitter_repository.dart';
import 'presentation/viewmodels/main_viewmodel.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MainViewModel(
            Win32JoystickRepository(),
            SerialTransmitterRepository(),
          ),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    ),
  );
}
