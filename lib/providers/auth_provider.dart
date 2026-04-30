import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  static const String _keyUserId = 'auth_user_id';
  static const String _keyUserName = 'auth_user_name';
  static const String _keyTableNumber = 'auth_table_number';
  static const String _keyDeviceTableNumber = 'device_table_number';

  User? _authUser;
  Map<String, dynamic>? _perfil;
  String _tableNumber = '';
  String _deviceTableNumber = '';
  bool _isLoading = false;

  bool get isLoggedIn => _authUser != null && _perfil != null;
  User? get authUser => _authUser;
  Map<String, dynamic>? get perfil => _perfil;
  String get userName => _perfil?['nome'] ?? '';
  String get tableNumber => _tableNumber;
  String get deviceTableNumber => _deviceTableNumber;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session != null) {
      _authUser = session.user;
      await _fetchPerfil();
    }

    final prefs = await SharedPreferences.getInstance();
    _tableNumber = prefs.getString(_keyTableNumber) ?? '';
    _deviceTableNumber = prefs.getString(_keyDeviceTableNumber) ?? '';

    notifyListeners();

    supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _authUser = session.user;
        await _fetchPerfil();
      } else if (event == AuthChangeEvent.signedOut) {
        _authUser = null;
        _perfil = null;
        _tableNumber = '';
      }
      notifyListeners();
    });
  }

  Future<void> _fetchPerfil() async {
    if (_authUser == null) return;

    try {
      final response = await Supabase.instance.client
          .from('usuario')
          .select()
          .eq('user_id', _authUser!.id)
          .eq('empresa_id', 7)
          .maybeSingle();

      _perfil = response;

      if (_perfil != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUserId, _authUser!.id);
        await prefs.setString(_keyUserName, _perfil!['nome'] ?? '');
      }
    } catch (e) {
      debugPrint('Erro ao buscar perfil: $e');
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final authResponse = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (authResponse.user == null) {
        throw Exception('Credenciais inválidas');
      }

      _authUser = authResponse.user;
      await _fetchPerfil();

      if (_perfil == null) {
        await Supabase.instance.client.auth.signOut();
        _authUser = null;
        throw Exception('Usuário sem acesso à empresa 7');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    _authUser = null;
    _perfil = null;
    _tableNumber = '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyTableNumber);

    notifyListeners();
  }

  Future<void> unlinkDeviceTable() async {
    _deviceTableNumber = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDeviceTableNumber);
    notifyListeners();
  }

  Future<void> linkTable(String tableNumber) async {
    _tableNumber = tableNumber;
    _deviceTableNumber = tableNumber;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTableNumber, tableNumber);
    await prefs.setString(_keyDeviceTableNumber, tableNumber);

    notifyListeners();
  }
}
