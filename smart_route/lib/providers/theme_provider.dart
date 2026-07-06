import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:smart_route/core/utills/helpers.dart';
import 'dart:ui';

import '../core/constants/app_constants.dart';

class ThemeProvider extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // ============ STATE VARIABLES ============

  ThemeMode _themeMode = ThemeMode.system;
  bool _isDarkMode = false;
  Color _primaryColor = Colors.blue;
  Color _secondaryColor = Colors.blueAccent;
  Color _accentColor = Colors.teal;
  String _fontFamily = 'Inter';
  double _fontScale = 1.0;
  bool _isMaterial3 = true;
  bool _useGlassmorphism = true;
  Map<String, dynamic> _customColors = {};

  // ============ GETTERS ============

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;
  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;
  Color get accentColor => _accentColor;
  String get fontFamily => _fontFamily;
  double get fontScale => _fontScale;
  bool get isMaterial3 => _isMaterial3;
  bool get useGlassmorphism => _useGlassmorphism;
  Map<String, dynamic> get customColors => _customColors;

  // ============ THEME DATA ============

  ThemeData get themeData {
    if (_isMaterial3) {
      return _buildMaterial3Theme(Brightness.light);
    }
    return _buildMaterial2Theme(Brightness.light);
  }

  ThemeData get darkThemeData {
    if (_isMaterial3) {
      return _buildMaterial3Theme(Brightness.dark);
    }
    return _buildMaterial2Theme(Brightness.dark);
  }

  // ============ THEME BUILDERS ============

  ThemeData _buildMaterial3Theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: brightness,
      secondary: _secondaryColor,
      tertiary: _accentColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: _fontFamily,
      textTheme: _buildTextTheme(brightness),
      appBarTheme: _buildAppBarTheme(brightness),
      cardTheme: _buildCardTheme(brightness),
      inputDecorationTheme: _buildInputDecorationTheme(brightness),
      elevatedButtonTheme: _buildElevatedButtonTheme(brightness),
      outlinedButtonTheme: _buildOutlinedButtonTheme(brightness),
      textButtonTheme: _buildTextButtonTheme(brightness),
      snackBarTheme: _buildSnackBarTheme(brightness),
      dialogTheme: _buildDialogTheme(brightness),
      bottomSheetTheme: _buildBottomSheetTheme(brightness),
      navigationBarTheme: _buildNavigationBarTheme(brightness),
      navigationRailTheme: _buildNavigationRailTheme(brightness),
      drawerTheme: _buildDrawerTheme(brightness),
      chipTheme: _buildChipTheme(brightness),
      popupMenuTheme: _buildPopupMenuTheme(brightness),
      tooltipTheme: _buildTooltipTheme(brightness),
      checkboxTheme: _buildCheckboxTheme(brightness),
      radioTheme: _buildRadioTheme(brightness),
      switchTheme: _buildSwitchTheme(brightness),
      sliderTheme: _buildSliderTheme(brightness),
      tabBarTheme: _buildTabBarTheme(brightness),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(brightness),
      floatingActionButtonTheme: _buildFloatingActionButtonTheme(brightness),
      dividerTheme: _buildDividerTheme(brightness),
      listTileTheme: _buildListTileTheme(brightness),
      iconTheme: _buildIconTheme(brightness),
      primaryIconTheme: _buildPrimaryIconTheme(brightness),
      scaffoldBackgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      // Remove backgroundColor - deprecated
      canvasColor: isDark ? Colors.grey[850] : Colors.grey[50],
      cardColor: isDark ? Colors.grey[800] : Colors.white,
      dividerColor: isDark ? Colors.grey[700] : Colors.grey[200],
      highlightColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200],
      splashColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300],
      hoverColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
      focusColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200],
      indicatorColor: isDark ? Colors.white : Colors.black,
      primaryColorLight: isDark ? Colors.grey[700] : Colors.grey[300],
      primaryColorDark: isDark ? Colors.grey[300] : Colors.grey[700],
      secondaryHeaderColor: isDark ? Colors.grey[700] : Colors.grey[200],
      shadowColor: isDark ? Colors.black54 : Colors.black26,
      pageTransitionsTheme: _buildPageTransitionsTheme(),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  ThemeData _buildMaterial2Theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: false,
      brightness: brightness,
      primarySwatch: _getMaterialColor(_primaryColor),
      primaryColor: _primaryColor,
      primaryColorLight: _primaryColor.withOpacity(0.5),
      primaryColorDark: _primaryColor.withOpacity(0.8),
      secondaryHeaderColor: _secondaryColor,
      // Remove accentColor - use colorScheme instead
      fontFamily: _fontFamily,
      textTheme: _buildTextTheme(brightness),
      appBarTheme: _buildAppBarTheme(brightness),
      cardTheme: _buildCardTheme(brightness),
      inputDecorationTheme: _buildInputDecorationTheme(brightness),
      elevatedButtonTheme: _buildElevatedButtonTheme(brightness),
      outlinedButtonTheme: _buildOutlinedButtonTheme(brightness),
      textButtonTheme: _buildTextButtonTheme(brightness),
      snackBarTheme: _buildSnackBarTheme(brightness),
      dialogTheme: _buildDialogTheme(brightness),
      bottomSheetTheme: _buildBottomSheetTheme(brightness),
      scaffoldBackgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      // Remove backgroundColor - deprecated
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: _primaryColor,
        secondary: _secondaryColor,
        tertiary: _accentColor,
        surface: isDark ? Colors.grey[800]! : Colors.white,
        background: isDark ? Colors.grey[900] : Colors.grey[50],
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: isDark ? Colors.white : Colors.black87,
        onBackground: isDark ? Colors.white : Colors.black87,
        onError: Colors.white,
      ),
      canvasColor: isDark ? Colors.grey[850] : Colors.grey[50],
      cardColor: isDark ? Colors.grey[800] : Colors.white,
      dividerColor: isDark ? Colors.grey[700] : Colors.grey[200],
      indicatorColor: isDark ? Colors.white : Colors.black,
    );
  }

  // ============ COMPONENT THEMES ============

  TextTheme _buildTextTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black87;

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57 * _fontScale,
        fontWeight: FontWeight.w300,
        color: baseColor,
        letterSpacing: -0.25,
      ),
      displayMedium: TextStyle(
        fontSize: 45 * _fontScale,
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),
      displaySmall: TextStyle(
        fontSize: 36 * _fontScale,
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),
      headlineLarge: TextStyle(
        fontSize: 32 * _fontScale,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 28 * _fontScale,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 24 * _fontScale,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleLarge: TextStyle(
        fontSize: 22 * _fontScale,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleMedium: TextStyle(
        fontSize: 18 * _fontScale,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      titleSmall: TextStyle(
        fontSize: 16 * _fontScale,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16 * _fontScale,
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14 * _fontScale,
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12 * _fontScale,
        fontWeight: FontWeight.w400,
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),
      labelLarge: TextStyle(
        fontSize: 14 * _fontScale,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      labelMedium: TextStyle(
        fontSize: 12 * _fontScale,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      labelSmall: TextStyle(
        fontSize: 11 * _fontScale,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),
    );
  }

  AppBarTheme _buildAppBarTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      foregroundColor: isDark ? Colors.white : Colors.black87,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      shadowColor: isDark ? Colors.black54 : Colors.black26,
      iconTheme: _buildIconTheme(brightness),
      actionsIconTheme: _buildIconTheme(brightness),
      titleTextStyle: TextStyle(
        fontSize: 20 * _fontScale,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black87,
      ),
      toolbarTextStyle: TextStyle(
        fontSize: 14 * _fontScale,
        fontWeight: FontWeight.w400,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  CardThemeData _buildCardTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.grey[800] : Colors.white,
      shadowColor: isDark ? Colors.black54 : Colors.black12,
      surfaceTintColor: isDark ? Colors.grey[900] : Colors.white,
      margin: const EdgeInsets.all(8),
    );
  }

  InputDecorationTheme _buildInputDecorationTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),
      hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
      prefixIconColor: isDark ? Colors.grey[400] : Colors.grey[600],
      suffixIconColor: isDark ? Colors.grey[400] : Colors.grey[600],
    );
  }

  ElevatedButtonThemeData _buildElevatedButtonTheme(Brightness brightness) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: TextStyle(
          fontSize: 16 * _fontScale,
          fontWeight: FontWeight.w600,
        ),
        minimumSize: const Size(88, 48),
      ),
    );
  }

  OutlinedButtonThemeData _buildOutlinedButtonTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: BorderSide(
          color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
          width: 1,
        ),
        textStyle: TextStyle(
          fontSize: 16 * _fontScale,
          fontWeight: FontWeight.w600,
        ),
        minimumSize: const Size(88, 48),
      ),
    );
  }

  TextButtonThemeData _buildTextButtonTheme(Brightness brightness) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: TextStyle(
          fontSize: 14 * _fontScale,
          fontWeight: FontWeight.w500,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  SnackBarThemeData _buildSnackBarTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: isDark ? Colors.grey[800] : Colors.white,
      contentTextStyle: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 14 * _fontScale,
      ),
      actionTextColor: _primaryColor,
    );
  }

  DialogThemeData _buildDialogTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? Colors.grey[800] : Colors.white,
      elevation: 8,
      titleTextStyle: TextStyle(
        fontSize: 20 * _fontScale,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black87,
      ),
      contentTextStyle: TextStyle(
        fontSize: 14 * _fontScale,
        color: isDark ? Colors.grey[300] : Colors.grey[700],
      ),
    );
  }

  BottomSheetThemeData _buildBottomSheetTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return BottomSheetThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? Colors.grey[800] : Colors.white,
      elevation: 8,
      modalBackgroundColor: isDark ? Colors.grey[800] : Colors.white,
    );
  }

  NavigationBarThemeData _buildNavigationBarTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return NavigationBarThemeData(
      backgroundColor: isDark ? Colors.grey[850] : Colors.white,
      elevation: 8,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      indicatorColor: _primaryColor.withOpacity(0.2),
      shadowColor: isDark ? Colors.black54 : Colors.black12,
      surfaceTintColor: isDark ? Colors.grey[900] : Colors.white,
    );
  }

  NavigationRailThemeData _buildNavigationRailTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return NavigationRailThemeData(
      backgroundColor: isDark ? Colors.grey[850] : Colors.white,
      elevation: 8,
      selectedIconTheme: IconThemeData(color: _primaryColor, size: 24),
      unselectedIconTheme: IconThemeData(
        color: isDark ? Colors.grey[400] : Colors.grey[600],
        size: 24,
      ),
      selectedLabelTextStyle: TextStyle(
        color: _primaryColor,
        fontSize: 12 * _fontScale,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: isDark ? Colors.grey[400] : Colors.grey[600],
        fontSize: 12 * _fontScale,
      ),
    );
  }

  DrawerThemeData _buildDrawerTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return DrawerThemeData(
      backgroundColor: isDark ? Colors.grey[850] : Colors.white,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
    );
  }

  ChipThemeData _buildChipTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ChipThemeData(
      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
      selectedColor: _primaryColor.withOpacity(0.2),
      disabledColor: isDark ? Colors.grey[700] : Colors.grey[300],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: TextStyle(
        fontSize: 14 * _fontScale,
        color: isDark ? Colors.white : Colors.black87,
      ),
      secondaryLabelStyle: TextStyle(
        fontSize: 14 * _fontScale,
        color: Colors.white,
      ),
      brightness: brightness,
      deleteIconColor: isDark ? Colors.grey[400] : Colors.grey[600],
      side: BorderSide(
        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        width: 1,
      ),
      shape: StadiumBorder(),
      elevation: 0,
      pressElevation: 4,
      showCheckmark: true,
      checkmarkColor: Colors.green,
    );
  }

  PopupMenuThemeData _buildPopupMenuTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return PopupMenuThemeData(
      color: isDark ? Colors.grey[800] : Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: TextStyle(
        fontSize: 14 * _fontScale,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  TooltipThemeData _buildTooltipTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return TooltipThemeData(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[700],
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: TextStyle(fontSize: 12 * _fontScale, color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.all(8),
    );
  }

  CheckboxThemeData _buildCheckboxTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return _primaryColor;
        }
        return isDark ? Colors.grey[600] : Colors.grey[400];
      }),
      checkColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.white;
        }
        return isDark ? Colors.grey[400] : Colors.grey[600];
      }),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: BorderSide(
        color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
        width: 2,
      ),
    );
  }

  RadioThemeData _buildRadioTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return _primaryColor;
        }
        return isDark ? Colors.grey[600] : Colors.grey[400];
      }),
    );
  }

  SwitchThemeData _buildSwitchTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return _primaryColor;
        }
        return isDark ? Colors.grey[400] : Colors.grey[300];
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return _primaryColor.withOpacity(0.5);
        }
        return isDark ? Colors.grey[600] : Colors.grey[400];
      }),
    );
  }

  SliderThemeData _buildSliderTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SliderThemeData(
      activeTrackColor: _primaryColor,
      inactiveTrackColor: isDark ? Colors.grey[700] : Colors.grey[300],
      thumbColor: _primaryColor,
      overlayColor: _primaryColor.withOpacity(0.2),
      valueIndicatorColor: _primaryColor,
      valueIndicatorTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 12 * _fontScale,
      ),
    );
  }

  TabBarThemeData _buildTabBarTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return TabBarThemeData(
      labelColor: isDark ? Colors.white : Colors.black87,
      unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
      indicatorColor: _primaryColor,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(
        fontSize: 14 * _fontScale,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 14 * _fontScale,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  BottomNavigationBarThemeData _buildBottomNavigationBarTheme(
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;
    return BottomNavigationBarThemeData(
      backgroundColor: isDark ? Colors.grey[850] : Colors.white,
      selectedItemColor: _primaryColor,
      unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey[600],
      selectedLabelStyle: TextStyle(
        fontSize: 12 * _fontScale,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12 * _fontScale,
        fontWeight: FontWeight.w400,
      ),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    );
  }

  FloatingActionButtonThemeData _buildFloatingActionButtonTheme(
    Brightness brightness,
  ) {
    return FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),
      extendedSizeConstraints: const BoxConstraints.tightFor(height: 48),
      extendedTextStyle: TextStyle(
        fontSize: 16 * _fontScale,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  DividerThemeData _buildDividerTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return DividerThemeData(
      color: isDark ? Colors.grey[700] : Colors.grey[200],
      thickness: 1,
      space: 16,
    );
  }

  ListTileThemeData _buildListTileTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ListTileThemeData(
      textColor: isDark ? Colors.white : Colors.black87,
      iconColor: isDark ? Colors.grey[400] : Colors.grey[600],
      tileColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      dense: false,
    );
  }

  IconThemeData _buildIconTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return IconThemeData(
      color: isDark ? Colors.white : Colors.black87,
      size: 24,
    );
  }

  IconThemeData _buildPrimaryIconTheme(Brightness brightness) {
    return IconThemeData(color: _primaryColor, size: 24);
  }

  PageTransitionsTheme _buildPageTransitionsTheme() {
    return const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      },
    );
  }

  // ============ HELPER METHODS ============

  MaterialColor _getMaterialColor(Color color) {
    final int red = color.red;
    final int green = color.green;
    final int blue = color.blue;

    final Map<int, Color> swatch = {
      50: Color.fromRGBO(red, green, blue, .1),
      100: Color.fromRGBO(red, green, blue, .2),
      200: Color.fromRGBO(red, green, blue, .3),
      300: Color.fromRGBO(red, green, blue, .4),
      400: Color.fromRGBO(red, green, blue, .5),
      500: Color.fromRGBO(red, green, blue, .6),
      600: Color.fromRGBO(red, green, blue, .7),
      700: Color.fromRGBO(red, green, blue, .8),
      800: Color.fromRGBO(red, green, blue, .9),
      900: Color.fromRGBO(red, green, blue, 1),
    };

    return MaterialColor(color.value, swatch);
  }

  // ============ THEME SETTINGS ============

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    _themeMode = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
    await _saveThemeMode();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    _isDarkMode = mode == ThemeMode.dark;
    await _saveThemeMode();
    notifyListeners();
  }

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    await _saveColor('primary_color', color);
    notifyListeners();
  }

  Future<void> setSecondaryColor(Color color) async {
    _secondaryColor = color;
    await _saveColor('secondary_color', color);
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    await _saveColor('accent_color', color);
    notifyListeners();
  }

  Future<void> setFontFamily(String fontFamily) async {
    _fontFamily = fontFamily;
    await _secureStorage.write(key: 'font_family', value: fontFamily);
    notifyListeners();
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale.clamp(0.8, 1.2);
    await _secureStorage.write(key: 'font_scale', value: scale.toString());
    notifyListeners();
  }

  Future<void> toggleMaterial3() async {
    _isMaterial3 = !_isMaterial3;
    await _secureStorage.write(
      key: 'material3',
      value: _isMaterial3.toString(),
    );
    notifyListeners();
  }

  Future<void> toggleGlassmorphism() async {
    _useGlassmorphism = !_useGlassmorphism;
    await _secureStorage.write(
      key: 'glassmorphism',
      value: _useGlassmorphism.toString(),
    );
    notifyListeners();
  }

  // ============ CUSTOM COLORS ============

  Future<void> setCustomColor(String key, Color color) async {
    _customColors[key] = color;
    await _secureStorage.write(
      key: 'custom_color_$key',
      value: color.value.toString(),
    );
    notifyListeners();
  }

  Color? getCustomColor(String key) {
    final value = _customColors[key];
    if (value is Color) return value;
    return null;
  }

  // ============ PERSISTENCE ============

  Future<void> _saveThemeMode() async {
    await _secureStorage.write(
      key: AppConstants.prefThemeMode,
      value: _themeMode.toString(),
    );
  }

  Future<void> _saveColor(String key, Color color) async {
    await _secureStorage.write(key: key, value: color.value.toString());
  }

  Future<Color> _loadColor(String key, Color defaultValue) async {
    try {
      final value = await _secureStorage.read(key: key);
      if (value != null && value.isNotEmpty) {
        // Try to parse as integer
        final parsed = int.tryParse(value);
        if (parsed != null && parsed >= 0) {
          return Color(parsed);
        }
        // Try to parse as hex string (e.g., #FF0000)
        if (value.startsWith('#')) {
          final hex = value.replaceAll('#', '');
          if (hex.length == 6 || hex.length == 8) {
            final intValue = int.tryParse(hex, radix: 16);
            if (intValue != null) {
              if (hex.length == 6) {
                return Color(0xFF000000 + intValue);
              }
              return Color(intValue);
            }
          }
        }
      }
      return defaultValue;
    } catch (e) {
      Helpers.logError(e, tag: 'ThemeProvider._loadColor');
      return defaultValue;
    }
  }

  // ============ INITIALIZATION ============

  Future<void> initialize() async {
    try {
      // Load theme mode
      final themeModeStr = await _secureStorage.read(
        key: AppConstants.prefThemeMode,
      );
      if (themeModeStr != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (e) => e.toString() == themeModeStr,
          orElse: () => ThemeMode.system,
        );
        _isDarkMode = _themeMode == ThemeMode.dark;
      }

      // Load colors
      _primaryColor = await _loadColor('primary_color', Colors.blue);
      _secondaryColor = await _loadColor('secondary_color', Colors.blueAccent);
      _accentColor = await _loadColor('accent_color', Colors.teal);

      // Load font settings
      final fontFamily = await _secureStorage.read(key: 'font_family');
      if (fontFamily != null) _fontFamily = fontFamily;

      final fontScaleStr = await _secureStorage.read(key: 'font_scale');
      if (fontScaleStr != null) {
        _fontScale = double.tryParse(fontScaleStr) ?? 1.0;
      }

      // Load feature toggles
      final material3Str = await _secureStorage.read(key: 'material3');
      if (material3Str != null) {
        _isMaterial3 = material3Str == 'true';
      }

      final glassmorphismStr = await _secureStorage.read(key: 'glassmorphism');
      if (glassmorphismStr != null) {
        _useGlassmorphism = glassmorphismStr == 'true';
      }

      notifyListeners();
    } catch (e) {
      Helpers.logError(e, tag: 'ThemeProvider');
    }
  }

  // ============ DISPOSE ============

  @override
  void dispose() {
    super.dispose();
  }
}

// ============ THEME PROVIDER EXTENSIONS ============

extension ThemeProviderExtension on BuildContext {
  ThemeProvider get theme => Provider.of<ThemeProvider>(this, listen: false);
  ThemeProvider get watchTheme =>
      Provider.of<ThemeProvider>(this, listen: true);

  /// Get theme data
  ThemeData get themeData => Theme.of(this);

  /// Check if dark mode is enabled
  bool get isDarkMode => watchTheme.isDarkMode;

  /// Check if Material 3 is enabled
  bool get isMaterial3 => watchTheme.isMaterial3;

  /// Check if glassmorphism is enabled
  bool get useGlassmorphism => watchTheme.useGlassmorphism;

  /// Get primary color
  Color get primaryColor => watchTheme.primaryColor;

  /// Get secondary color
  Color get secondaryColor => watchTheme.secondaryColor;

  /// Get accent color
  Color get accentColor => watchTheme.accentColor;

  /// Get font family
  String get fontFamily => watchTheme.fontFamily;

  /// Get font scale
  double get fontScale => watchTheme.fontScale;
}

// ============ THEME STREAM BUILDER ============

class ThemeStreamBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    bool isDarkMode,
    ThemeData theme,
    ThemeData darkTheme,
  )
  builder;

  const ThemeStreamBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return builder(
      context,
      themeProvider.isDarkMode,
      themeProvider.themeData,
      themeProvider.darkThemeData,
    );
  }
}

// ============ GLASSMORPHISM EXTENSIONS ============

extension GlassmorphismExtension on Widget {
  /// Wrap widget with glassmorphic effect using theme settings
  Widget withThemeGlassmorphic({
    double borderRadius = 16,
    double blur = 20,
    double opacity = 0.7,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    VoidCallback? onTap,
  }) {
    return Builder(
      builder: (context) {
        final useGlass = context.useGlassmorphism;

        if (!useGlass) {
          return this;
        }

        final isDark = context.isDarkMode;

        return Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.6),
                isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.3),
              ],
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.white.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: blur,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
            ],
          ),
          child: onTap != null
              ? Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(borderRadius),
                    child: this,
                  ),
                )
              : this,
        );
      },
    );
  }
}
