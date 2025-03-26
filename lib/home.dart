import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';

import 'package:steam_buddy/currency_provider.dart';
import 'package:steam_buddy/game_details.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _games = [];
  CurrencyProvider? _currencyProvider;

  @override
  void initState() {
    super.initState();
  }

  void _onCurrencyChanged() {
    _performSearch(_searchController.text);
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    if (_currencyProvider != currencyProvider) {
      _currencyProvider?.removeListener(_onCurrencyChanged);
      _currencyProvider = currencyProvider;
      _currencyProvider?.addListener(_onCurrencyChanged);
      _performSearch(_searchController.text);
    }
  }

  @override
  void dispose() {
    _currencyProvider?.removeListener(_onCurrencyChanged);
    _searchController.dispose();
    super.dispose();
  }

  String _formatPrice(dynamic priceData) {
    if (priceData == null) return 'Free';

    if (priceData is Map) {
      if (priceData.containsKey('final') && priceData.containsKey('currency')) {
        final price = priceData['final'];
        final currencyCode = priceData['currency'];

        String symbol = _getCurrencySymbol(currencyCode);

        double formattedValue = price / 100;

        bool useDecimals =
            !['JPY', 'KRW', 'IDR', 'VND', 'CLP', 'COP'].contains(currencyCode);

        String formattedPrice =
            useDecimals
                ? formattedValue.toStringAsFixed(2)
                : formattedValue.toStringAsFixed(0);

        bool symbolAfter = ['kr', 'zł'].contains(symbol);

        return symbolAfter
            ? '$formattedPrice $symbol'
            : '$symbol$formattedPrice';
      }
    }

    return 'See price';
  }

  String _getCurrencySymbol(String currencyCode) {
    final Map<String, String> currencySymbols = {
      "USD": "\$",
      "ARS": "ARS\$",
      "AUD": "A\$",
      "BRL": "R\$",
      "CAD": "C\$",
      "CLP": "CLP\$",
      "CNY": "¥",
      "COP": "COL\$",
      "CRC": "₡",
      "EUR": "€",
      "GBP": "£",
      "HKD": "HK\$",
      "IDR": "Rp",
      "ILS": "₪",
      "INR": "₹",
      "JPY": "¥",
      "KRW": "₩",
      "KZT": "₸",
      "MXN": "Mex\$",
      "MYR": "RM",
      "NOK": "kr",
      "NZD": "NZ\$",
      "PEN": "S/.",
      "PHP": "₱",
      "PLN": "zł",
      "QAR": "QR",
      "RUB": "₽",
      "SAR": "SR",
      "SGD": "S\$",
      "THB": "฿",
      "TRY": "₺",
      "TWD": "NT\$",
      "UAH": "₴",
      "AED": "AED",
      "UYU": "\$U",
      "VND": "₫",
      "ZAR": "R",
    };

    return currencySymbols[currencyCode] ?? currencyCode;
  }

  bool _hasDiscount(dynamic priceData) {
    if (priceData is Map &&
        priceData.containsKey('initial') &&
        priceData.containsKey('final')) {
      return priceData['initial'] > priceData['final'];
    }
    return false;
  }

  String _formatOriginalPrice(dynamic priceData) {
    if (priceData is Map &&
        priceData.containsKey('initial') &&
        priceData.containsKey('currency')) {
      final initialPrice = priceData['initial'];
      final currencyCode = priceData['currency'];

      // Get currency symbol
      String symbol = _getCurrencySymbol(currencyCode);

      // Format the price value
      double formattedValue = initialPrice / 100;

      // Handle currencies that don't typically use decimal places
      bool useDecimals =
          !['JPY', 'KRW', 'IDR', 'VND', 'CLP', 'COP'].contains(currencyCode);

      // Format with or without decimal places
      String formattedPrice =
          useDecimals
              ? formattedValue.toStringAsFixed(2)
              : formattedValue.toStringAsFixed(0);

      // Some symbols go before the number, some after
      bool symbolAfter = ['kr', 'zł'].contains(symbol);

      // Return formatted price with symbol in correct position
      return symbolAfter ? '$formattedPrice $symbol' : '$symbol$formattedPrice';
    }
    return '';
  }

  int _calculateDiscountPercent(dynamic priceData) {
    if (priceData is Map &&
        priceData.containsKey('initial') &&
        priceData.containsKey('final') &&
        priceData['initial'] > 0) {
      final initial = priceData['initial'];
      final finalPrice = priceData['final'];
      return ((initial - finalPrice) / initial * 100).round();
    }
    return 0;
  }

  Widget _buildFeaturedSections() {
    // Group games by platform
    final bundleGames =
        _games.where((game) => game['platform'] == 'Bundle').toList();
    final windowsGames =
        _games.where((game) => game['platform'] == 'Windows').toList();
    final macGames = _games.where((game) => game['platform'] == 'Mac').toList();
    final linuxGames =
        _games.where((game) => game['platform'] == 'Linux').toList();

    return ListView(
      children: [
        if (bundleGames.isNotEmpty)
          _buildSection('Featured Game Bundles', bundleGames),
        if (windowsGames.isNotEmpty)
          _buildSection('Featured Windows Games', windowsGames),
        if (macGames.isNotEmpty) _buildSection('Featured Mac Games', macGames),
        if (linuxGames.isNotEmpty)
          _buildSection('Featured Linux Games', linuxGames),
      ],
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> games) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 240, // Fixed height for horizontal list
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return SizedBox(
                width: 300, // Fixed width for each item
                child: Card(
                  margin: const EdgeInsets.only(right: 12, bottom: 4),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameDetailsScreen(game: game),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child:
                              game['image'] != null
                                  ? ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    child: Image.network(
                                      game['image'],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (ctx, error, _) => Container(
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              size: 40,
                                            ),
                                          ),
                                    ),
                                  )
                                  : Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 40,
                                    ),
                                  ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  game['name'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ID: ${game['id']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    if (game['price'] != null)
                                      Flexible(
                                        flex: 3,
                                        child:
                                            _hasDiscount(game['price'])
                                                ? Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      _formatOriginalPrice(
                                                        game['price'],
                                                      ),
                                                      style: const TextStyle(
                                                        fontSize: 9,
                                                        decoration:
                                                            TextDecoration
                                                                .lineThrough,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                    Text(
                                                      _formatPrice(
                                                        game['price'],
                                                      ),
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                    Text(
                                                      '-${_calculateDiscountPercent(game['price'])}%',
                                                      style: const TextStyle(
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                                : Text(
                                                  _formatPrice(game['price']),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _performSearch(String query) async {
    final currencyProvider = Provider.of<CurrencyProvider>(
      context,
      listen: false,
    );
    String currencyCode = currencyProvider.currencyCode;

    if (query.isEmpty) {
      setState(() {
        _isLoading = true;
        _games = [];
      });
      try {
        final featured = await http.get(
          Uri.parse(
            'https://store.steampowered.com/api/featured/?cc=$currencyCode',
          ),
        );

        if (featured.statusCode == 200) {
          final data = json.decode(featured.body);
          List<Map<String, dynamic>> featuredGames = [];

          int parsePrice(dynamic priceValue) {
            if (priceValue is int) {
              return priceValue;
            } else if (priceValue is String) {
              return int.parse(priceValue.replaceAll(',', ''));
            } else {
              return 0; // Default value if parsing fails
            }
          }

          if (data.containsKey('large_capsules') &&
              data['large_capsules'] is List) {
            final games = data['large_capsules'] as List;
            for (var game in games) {
              // Create a properly formatted price map
              final priceMap = {
                'currency': game['currency'],
                'initial':
                    game['discounted']
                        ? parsePrice(game['original_price'])
                        : parsePrice(game['final_price']),
                'final': parsePrice(game['final_price']),
              };

              featuredGames.add({
                'id': game['id'],
                'name': game['name'],
                'price': priceMap,
                'platform':
                    'Bundle', // Changed from 'platforms' to 'platform' to match your _buildFeaturedSections
                'image':
                    game.containsKey('large_capsule_image')
                        ? game['large_capsule_image']
                        : null,
              });
            }
          }

          if (data.containsKey('featured_win') &&
              data['featured_win'] is List) {
            final games = data['featured_win'] as List;
            for (var game in games) {
              if (!featuredGames.any(
                (element) => element['id'] == game['id'],
              )) {
                // Create a properly formatted price map
                final priceMap = {
                  'currency': game['currency'],
                  'initial':
                      game['discounted']
                          ? parsePrice(game['original_price'])
                          : parsePrice(game['final_price']),
                  'final': parsePrice(game['final_price']),
                };

                featuredGames.add({
                  'id': game['id'],
                  'name': game['name'],
                  'price': priceMap,
                  'platform': 'Windows', // Changed from 'platforms'
                  'image':
                      game.containsKey('large_capsule_image')
                          ? game['large_capsule_image']
                          : null,
                });
              }
            }
          }

          if (data.containsKey('featured_mac') &&
              data['featured_mac'] is List) {
            final games = data['featured_mac'] as List;
            for (var game in games) {
              if (!featuredGames.any(
                (element) => element['id'] == game['id'],
              )) {
                // Create a properly formatted price map
                final priceMap = {
                  'currency': game['currency'],
                  'initial':
                      game['discounted']
                          ? parsePrice(game['original_price'])
                          : parsePrice(game['final_price']),
                  'final': parsePrice(game['final_price']),
                };

                featuredGames.add({
                  'id': game['id'],
                  'name': game['name'],
                  'price': priceMap,
                  'platform': 'Mac', // Changed from 'platforms'
                  'image':
                      game.containsKey('large_capsule_image')
                          ? game['large_capsule_image']
                          : null,
                });
              }
            }
          }

          if (data.containsKey('featured_linux') &&
              data['featured_linux'] is List) {
            final games = data['featured_linux'] as List;
            for (var game in games) {
              if (!featuredGames.any(
                (element) => element['id'] == game['id'],
              )) {
                // Create a properly formatted price map
                final priceMap = {
                  'currency': game['currency'],
                  'initial':
                      game['discounted']
                          ? parsePrice(game['original_price'])
                          : parsePrice(game['final_price']),
                  'final': parsePrice(game['final_price']),
                };
                featuredGames.add({
                  'id': game['id'],
                  'name': game['name'],
                  'price': priceMap,
                  'platform': 'Linux', // Changed from 'platforms'
                  'image':
                      game.containsKey('large_capsule_image')
                          ? game['large_capsule_image']
                          : null,
                });
              }
            }
          }

          setState(() {
            _games = featuredGames;
            _isLoading = false;
          });

          if (_games.isNotEmpty) {}
        } else {
          throw Exception('Failed to load featured games');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load featured games: $e'),
              backgroundColor: Colors.red,
            ),
          );
        });
      }
    } else {
      try {
        final response = await http.get(
          Uri.parse(
            'https://store.steampowered.com/api/storesearch/?term=$query&l=english&cc=$currencyCode',
          ),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data.containsKey('items') && data['items'] is List) {
            final apps = data['items'];

            setState(() {
              _games = List<Map<String, dynamic>>.from(
                apps.map(
                  (item) => {
                    'id': item['id'],
                    'name': item['name'],
                    'price': item.containsKey('price') ? item['price'] : null,
                    'image':
                        item.containsKey('tiny_image')
                            ? item['tiny_image']
                            : null,
                  },
                ),
              );
              _isLoading = false;
            });
          } else {
            setState(() {
              _isLoading = false;
              _games = [];
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('No games found'),
                  backgroundColor: Colors.red,
                ),
              );
            });
          }
        } else {
          throw Exception('Failed to load Steam games');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load Steam games: $e'),
              backgroundColor: Colors.red,
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrencyProvider>(
      builder: (context, currencyProvider, child) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search for a game',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchController.clear(),
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) => _performSearch(value),
                ),

                const SizedBox(height: 16),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),

                if (!_isLoading && _games.isEmpty)
                  const Center(
                    child: Text(
                      'No games found. Try a different search term.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                if (!_isLoading && _games.isNotEmpty)
                  Expanded(
                    child:
                        _searchController.text.isEmpty
                            ? _buildFeaturedSections()
                            : GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.65,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                              itemCount: _games.length,
                              itemBuilder: (context, index) {
                                final game = _games[index];
                                return Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  GameDetailsScreen(game: game),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child:
                                              game['image'] != null
                                                  ? ClipRRect(
                                                    borderRadius:
                                                        const BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            12,
                                                          ),
                                                        ),
                                                    child: Image.network(
                                                      game['image'],
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            ctx,
                                                            error,
                                                            _,
                                                          ) => Container(
                                                            color:
                                                                Colors
                                                                    .grey[300],
                                                            child: const Icon(
                                                              Icons
                                                                  .image_not_supported,
                                                              size: 40,
                                                            ),
                                                          ),
                                                      loadingBuilder: (
                                                        ctx,
                                                        child,
                                                        loadingProgress,
                                                      ) {
                                                        if (loadingProgress ==
                                                            null) {
                                                          return child;
                                                        }
                                                        return Center(
                                                          child: CircularProgressIndicator(
                                                            value:
                                                                loadingProgress
                                                                            .expectedTotalBytes !=
                                                                        null
                                                                    ? loadingProgress
                                                                            .cumulativeBytesLoaded /
                                                                        loadingProgress
                                                                            .expectedTotalBytes!
                                                                    : null,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  )
                                                  : Container(
                                                    color: Colors.grey[300],
                                                    child: const Icon(
                                                      Icons.image_not_supported,
                                                      size: 40,
                                                    ),
                                                  ),
                                        ),

                                        Expanded(
                                          flex: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  game['name'],
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),

                                                const Spacer(),

                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'ID: ${game['id']}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    ),

                                                    if (game['price'] != null)
                                                      Flexible(
                                                        flex: 3,
                                                        child:
                                                            _hasDiscount(
                                                                  game['price'],
                                                                )
                                                                ? Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .end,
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    Text(
                                                                      _formatOriginalPrice(
                                                                        game['price'],
                                                                      ),
                                                                      style: const TextStyle(
                                                                        fontSize:
                                                                            9,
                                                                        decoration:
                                                                            TextDecoration.lineThrough,
                                                                        color:
                                                                            Colors.grey,
                                                                      ),
                                                                    ),

                                                                    Text(
                                                                      _formatPrice(
                                                                        game['price'],
                                                                      ),
                                                                      style: const TextStyle(
                                                                        fontSize:
                                                                            10,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color:
                                                                            Colors.green,
                                                                      ),
                                                                    ),

                                                                    Text(
                                                                      '-${_calculateDiscountPercent(game['price'])}%',
                                                                      style: const TextStyle(
                                                                        fontSize:
                                                                            9,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color:
                                                                            Colors.red,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                )
                                                                : Text(
                                                                  _formatPrice(
                                                                    game['price'],
                                                                  ),
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color:
                                                                        Colors
                                                                            .green,
                                                                  ),
                                                                ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
