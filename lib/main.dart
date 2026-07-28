import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  // wrap the app so ThemeModel can be reached from any screen
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeModel(),
      child: const MyApp(),
    ),
  );
}

// holds the app state (theme). ChangeNotifier lets it tell widgets to rebuild
class ThemeModel with ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  // switch between light and dark, then update the widgets listening
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);

    return MaterialApp(
      title: 'Ephemeral vs App State',
      debugShowCheckedModeBanner: false,
      // pick the theme based on app state
      theme: themeModel.isDark ? ThemeData.dark() : ThemeData.light(),
      home: const CounterScreen(),
    );
  }
}

// stateful because the counter value belongs only to this screen
class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int _counter = 0;

  late final ThemeModel _themeModel;

  @override
  void initState() {
    super.initState();
    // listen: false since we add our own listener below
    _themeModel = Provider.of<ThemeModel>(context, listen: false);
    _themeModel.addListener(_resetCounterOnThemeChange);
  }

  @override
  void dispose() {
    // remove listener so it doesn't leak
    _themeModel.removeListener(_resetCounterOnThemeChange);
    super.dispose();
  }

  // reset the counter whenever the theme is toggled
  void _resetCounterOnThemeChange() {
    setState(() {
      _counter = 0;
    });
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  // go to the theme settings screen
  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter'),
        actions: [
          // settings icon on the top right
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// theme toggle screen, reads and updates the shared ThemeModel
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              themeModel.isDark ? 'Dark Mode ON' : 'Light Mode ON',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            // toggles the theme for the whole app
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: themeModel.isDark,
              onChanged: (_) => themeModel.toggleTheme(),
            ),
          ],
        ),
      ),
    );
  }
}
