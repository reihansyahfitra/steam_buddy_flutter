import 'package:flutter/material.dart';
import 'package:steam_buddy/home.dart';
import 'package:provider/provider.dart';
import 'package:steam_buddy/currency_provider.dart';
import 'package:steam_buddy/theme_provider.dart';
import 'package:steam_buddy/settings.dart';
import 'package:country_flags/country_flags.dart';

void main() => runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => CurrencyProvider()),
      ChangeNotifierProvider(create: (context) => ThemeProvider()),
    ],
    child: const MyApp(),
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const appTitle = 'Steam Buddy';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: appTitle,
      theme: themeProvider.currentTheme,
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: appTitle),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  final Map<String, String> _countryCodeMap = {
    "US": "US", // United States
    "AR": "AR", // Argentina
    "AU": "AU", // Australia
    "BR": "BR", // Brazil
    "CA": "CA", // Canada
    "CL": "CL", // Chile
    "CN": "CN", // China
    "CO": "CO", // Colombia
    "CR": "CR", // Costa Rica
    "EU": "EU", // European Union (special case)
    "GB": "GB", // United Kingdom
    "HK": "HK", // Hong Kong
    "ID": "ID", // Indonesia
    "IL": "IL", // Israel
    "IN": "IN", // India
    "JP": "JP", // Japan
    "KR": "KR", // South Korea
    "KZ": "KZ", // Kazakhstan
    "MX": "MX", // Mexico
    "MY": "MY", // Malaysia
    "NO": "NO", // Norway
    "NZ": "NZ", // New Zealand
    "PE": "PE", // Peru
    "PH": "PH", // Philippines
    "PL": "PL", // Poland
    "QA": "QA", // Qatar
    "RU": "RU", // Russia
    "SA": "SA", // Saudi Arabia
    "SG": "SG", // Singapore
    "TH": "TH", // Thailand
    "TR": "TR", // Turkey
    "TW": "TW", // Taiwan
    "UA": "UA", // Ukraine
    "AE": "AE", // United Arab Emirates
    "UY": "UY", // Uruguay
    "VN": "VN", // Vietnam
    "ZA": "ZA", // South Africa
  };

  Widget _getFlag(String countryCode) {
    return CountryFlag.fromCountryCode(
      countryCode.toLowerCase(),
      height: 20,
      width: 30,
    );
  }

  String _getCurrencyName(String code) {
    final Map<String, String> currencyNames = {
      "US": "USD (US Dollar)",
      "AR": "ARS (Argentine Peso)",
      "AU": "AUD (Australian Dollar)",
      "BR": "BRL (Brazilian Real)",
      "CA": "CAD (Canadian Dollar)",
      "CL": "CLP (Chilean Peso)",
      "CN": "CNY (Chinese Yuan)",
      "CO": "COP (Colombian Peso)",
      "CR": "CRC (Costa Rican Colón)",
      "EU": "EUR (Euro)",
      "GB": "GBP (British Pound)",
      "HK": "HKD (Hong Kong Dollar)",
      "ID": "IDR (Indonesian Rupiah)",
      "IL": "ILS (Israeli New Shekel)",
      "IN": "INR (Indian Rupee)",
      "JP": "JPY (Japanese Yen)",
      "KR": "KRW (South Korean Won)",
      "KZ": "KZT (Kazakhstani Tenge)",
      "MX": "MXN (Mexican Peso)",
      "MY": "MYR (Malaysian Ringgit)",
      "NO": "NOK (Norwegian Krone)",
      "NZ": "NZD (New Zealand Dollar)",
      "PE": "PEN (Peruvian Sol)",
      "PH": "PHP (Philippine Peso)",
      "PL": "PLN (Polish Złoty)",
      "QA": "QAR (Qatari Riyal)",
      "RU": "RUB (Russian Ruble)",
      "SA": "SAR (Saudi Riyal)",
      "SG": "SGD (Singapore Dollar)",
      "TH": "THB (Thai Baht)",
      "TR": "TRY (Turkish Lira)",
      "TW": "TWD (New Taiwan Dollar)",
      "UA": "UAH (Ukrainian Hryvnia)",
      "AE": "AED (UAE Dirham)",
      "UY": "UYU (Uruguayan Peso)",
      "VN": "VND (Vietnamese Đồng)",
      "ZA": "ZAR (South African Rand)",
    };
    return currencyNames[code] ?? code;
  }

  static const TextStyle optionStyle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    SettingScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.title),
            const Spacer(),
            DropdownButton<String>(
              value: currencyProvider.currencyCode,
              icon: const Icon(Icons.arrow_drop_down),
              dropdownColor: Theme.of(context).appBarTheme.backgroundColor,
              style: const TextStyle(color: Colors.black),
              underline: Container(height: 2, color: Colors.white),
              onChanged: (String? newValue) {
                setState(() {
                  currencyProvider.setCurrency(newValue!);
                });
              },
              items:
                  _countryCodeMap.keys.toList().map<DropdownMenuItem<String>>((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Tooltip(
                        message: _getCurrencyName(value),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _getFlag(value),
                            const SizedBox(width: 8),
                            Text(
                              value,
                              style: TextStyle(
                                color:
                                    themeProvider
                                        .currentTheme
                                        .textTheme
                                        .bodyLarge!
                                        .color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      body: Center(child: _widgetOptions[_selectedIndex]),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Steam Buddy',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Settings & Navigation',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('Home'),
              selected: _selectedIndex == 0,
              onTap: () {
                // Update the state of the app
                _onItemTapped(0);
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Settings'),
              selected: _selectedIndex == 1,
              onTap: () {
                // Update the state of the app
                _onItemTapped(1);
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
