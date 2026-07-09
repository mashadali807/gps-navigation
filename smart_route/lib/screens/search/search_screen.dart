import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_route/models/search_result_model.dart' hide SearchResult;
import 'package:smart_route/services/map_services.dart';
import 'dart:async';

import '../../providers/location_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/place_model.dart';
import '../../models/route_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<SearchResult> _searchResults = [];
  List<PlaceModel> _recentSearches = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  bool _showRecentSearches = true;

  // Debounce timer to prevent too many API calls
  Timer? _debounceTimer;
  String _lastSearchedQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _focusNode.requestFocus();
  }

  void _loadRecentSearches() {
    // Load from storage in a real app
    _recentSearches = [];
  }

  void _addToRecentSearches(PlaceModel place) {
    setState(() {
      _recentSearches.removeWhere((p) => p.id == place.id);
      _recentSearches.insert(0, place);
      if (_recentSearches.length > 10) {
        _recentSearches.removeLast();
      }
    });
  }

  void _onSearchChanged(String query) {
    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // If query is empty, clear results immediately
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
        _showRecentSearches = true;
        _error = null;
      });
      return;
    }

    // Show loading state immediately for user feedback
    setState(() {
      _isSearching = true;
      _error = null;
      _showRecentSearches = false;
    });

    // Debounce search - wait 500ms after user stops typing
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    // Don't search if query is empty or same as last search
    if (query.isEmpty) return;
    if (query == _lastSearchedQuery && _searchResults.isNotEmpty) return;

    _lastSearchedQuery = query;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await MapService.searchLocation(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
          _isSearching = false;
        });

        if (results.isEmpty) {
          setState(() {
            _error =
                'No results found for "$query". Please try a different search.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        // Check if it's a network/connection error
        String errorMessage = e.toString();
        if (errorMessage.contains('SocketException') ||
            errorMessage.contains('Connection') ||
            errorMessage.contains('timeout')) {
          errorMessage =
              'Network error. Please check your internet connection.';
        } else if (errorMessage.contains('429')) {
          errorMessage =
              'Too many requests. Please wait a moment and try again.';
        }

        setState(() {
          _error = errorMessage;
          _isLoading = false;
          _isSearching = false;
        });
      }
    }
  }

  void _selectSearchResult(SearchResult result) {
    final mapProvider = context.read<MapProvider>();
    final location = LatLng(result.latitude, result.longitude);

    final place = result.toPlaceModel();
    _addToRecentSearches(place);

    mapProvider.selectPlace(place);
    mapProvider.moveTo(location, zoom: 15);

    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _isSearching = false;
      _showRecentSearches = true;
      _error = null;
    });

    context.go('/home', extra: {'selectedPlace': place});
  }

  void _navigateToPlace(PlaceModel place) {
    final mapProvider = context.read<MapProvider>();
    final location = LatLng(place.latitude, place.longitude);

    mapProvider.selectPlace(place);
    mapProvider.moveTo(location, zoom: 15);

    context.go('/home', extra: {'selectedPlace': place});
  }

  void _calculateRoute(PlaceModel place) {
    final locationProvider = context.read<LocationProvider>();

    if (locationProvider.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current location not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final origin = LatLng(
      locationProvider.currentPosition!.latitude,
      locationProvider.currentPosition!.longitude,
    );
    final destination = LatLng(place.latitude, place.longitude);

    context.go(
      '/route-preview',
      extra: {
        'route': RouteModel(
          points: [origin, destination],
          distance: 0,
          duration: 0,
          origin: PlaceModel.currentLocation(
            latitude: origin.latitude,
            longitude: origin.longitude,
          ),
          destination: place,
        ),
      },
    );
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _isSearching = false;
      _showRecentSearches = true;
      _error = null;
      _lastSearchedQuery = '';
    });
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Search Places',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          if (_searchController.text.isNotEmpty || _searchResults.isNotEmpty)
            IconButton(
              onPressed: _clearSearch,
              icon: Icon(
                Icons.close,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(theme, isDark),
          Expanded(child: _buildContent(theme, isDark)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                border: Border.all(
                  color: _isSearching ? theme.primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search places...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                  prefixIcon: Icon(
                    _isSearching ? Icons.search : Icons.search,
                    color: _isSearching
                        ? theme.primaryColor
                        : (isDark ? Colors.grey[500] : Colors.grey[400]),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: _clearSearch,
                          icon: Icon(
                            Icons.clear,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                            size: 18,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingSmall,
                    vertical: AppConstants.paddingSmall,
                  ),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isDark) {
    if (_isSearching && _searchResults.isEmpty) {
      return _buildLoadingState(theme);
    }

    if (_error != null) {
      return _buildErrorState(theme);
    }

    if (_searchResults.isNotEmpty) {
      return _buildSearchResults(theme, isDark);
    }

    if (_showRecentSearches) {
      return _buildRecentAndFavorites(theme, isDark);
    }

    return _buildEmptyState(theme);
  }

  Widget _buildSearchResults(ThemeData theme, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildResultItem(theme, isDark, result, index);
      },
    );
  }

  Widget _buildResultItem(
    ThemeData theme,
    bool isDark,
    SearchResult result,
    int index,
  ) {
    return GlassmorphicCard(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
          onTap: () => _selectSearchResult(result),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryColor.withOpacity(0.1),
                ),
                child: Icon(
                  _getResultIcon(result.type),
                  color: theme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result.type ?? 'Location',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(
          duration: AppConstants.durationMedium,
          delay: Duration(milliseconds: index * 50),
        )
        .slideX(
          begin: 0.2,
          end: 0,
          duration: AppConstants.durationMedium,
          delay: Duration(milliseconds: index * 50),
        );
  }

  Widget _buildRecentAndFavorites(ThemeData theme, bool isDark) {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No recent searches',
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start searching for places to see them here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _recentSearches.clear();
                  });
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          ..._recentSearches.map(
            (place) => _buildRecentItem(theme, isDark, place),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItem(ThemeData theme, bool isDark, PlaceModel place) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      onTap: () => _navigateToPlace(place),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.withOpacity(0.1),
            ),
            child: Icon(
              Icons.history,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              size: 18,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (place.address != null)
                  Text(
                    place.address!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _calculateRoute(place),
            icon: Icon(Icons.navigation, color: theme.primaryColor, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LoadingWidget(size: 40, style: LoadingStyle.dots),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Searching...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _error?.contains('Network') == true
                  ? Icons.wifi_off
                  : Icons.error_outline,
              size: 64,
              color: _error?.contains('Network') == true
                  ? Colors.orange[300]
                  : Colors.red[300],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              _error!,
              style: theme.textTheme.titleMedium?.copyWith(
                color: _error?.contains('Network') == true
                    ? Colors.orange[700]
                    : Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () =>
                      _performSearch(_searchController.text.trim()),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'No results found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Try searching for a different place',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getResultIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'city':
      case 'town':
      case 'village':
        return Icons.location_city;
      case 'street':
      case 'road':
        return Icons.streetview;
      case 'building':
        return Icons.business_center;
      case 'park':
        return Icons.park;
      case 'restaurant':
        return Icons.restaurant;
      case 'cafe':
        return Icons.local_cafe;
      case 'hotel':
        return Icons.hotel;
      case 'hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'university':
        return Icons.school;
      case 'museum':
        return Icons.museum;
      case 'church':
        return Icons.church;
      case 'mosque':
        return Icons.mosque;
      case 'temple':
        return Icons.temple_buddhist;
      case 'landmark':
        return Icons.history;
      default:
        return Icons.place;
    }
  }
}

// ============ SEARCH RESULT EXTENSIONS ============

extension SearchResultExtension on SearchResult {
  PlaceModel toPlaceModel() {
    return PlaceModel.fromOSM({
      'display_name': displayName,
      'lat': latitude,
      'lon': longitude,
      'place_id': placeId,
      'type': type,
    });
  }
}
