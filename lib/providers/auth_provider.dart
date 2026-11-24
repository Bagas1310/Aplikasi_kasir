import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/shift.dart';
import '../services/database/database_helper.dart';

class AuthProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  UserModel? _currentUser;
  ShiftModel? _currentShift;
  bool _isLoading = true;
  bool _hasOwner = false;
  List<UserModel> _staffList = [];

  UserModel? get currentUser => _currentUser;
  ShiftModel? get currentShift => _currentShift;
  bool get isLoading => _isLoading;
  bool get hasOwner => _hasOwner;
  bool get isAuthenticated => _currentUser != null;
  bool get isOwner => _currentUser?.isOwner ?? false;
  List<UserModel> get staffList => _staffList;

  Future<void> checkInit() async {
    _isLoading = true;
    notifyListeners();
    _hasOwner = await _db.hasOwner();
    final session = await _db.getSession();
    if (session != null) {
      final user = await _db.getUserById(session['user_id'] as int);
      if (user != null) {
        _currentUser = user;
        final shiftId = session['shift_id'] as int?;
        _currentShift = shiftId == null ? null : await _db.getShiftById(shiftId);
        if (_currentShift == null) await _checkAndStartShift(user);
        if (user.isOwner) await loadStaff();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> registerOwner({
    required String name,
    required String username,
    required String password,
  }) async {
    final user = UserModel(
      name: name.trim(),
      username: username.trim(),
      password: password,
      role: 'owner',
    );
    final id = await _db.createUser(user);
    if (id > 0) {
      _currentUser = user.copyWith(id: id);
      _hasOwner = true;
      await _checkAndStartShift(_currentUser!);
      await _db.saveSession(userId: _currentUser!.id!, shiftId: _currentShift?.id);
      await loadStaff();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> login(String username, String password) async {
    final user = await _db.authenticate(username.trim(), password);
    if (user != null) {
      _currentUser = user;
      await _checkAndStartShift(user);
      await _db.saveSession(userId: user.id!, shiftId: _currentShift?.id);
      if (user.isOwner) await loadStaff();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> switchShift(String identifier, String password) async {
    final user = await _db.authenticateShift(identifier.trim(), password);
    if (user != null) {
      if (_currentShift != null) {
        await _db.closeShift(_currentShift!.id!);
      }
      _currentUser = user;
      final newShift = ShiftModel(
        userId: user.id!,
        userName: user.name,
      );
      final shiftId = await _db.startShift(newShift);
      _currentShift = newShift.copyWith(id: shiftId);
      await _db.saveSession(userId: user.id!, shiftId: shiftId);
      if (user.isOwner) await loadStaff();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> _checkAndStartShift(UserModel user) async {
    var active = await _db.getActiveShift();
    if (active == null) {
      final shift = ShiftModel(
        userId: user.id!,
        userName: user.name,
      );
      final id = await _db.startShift(shift);
      _currentShift = shift.copyWith(id: id);
    } else {
      _currentShift = active;
    }
  }

  Future<void> loadStaff() async {
    _staffList = await _db.getStaffList();
    notifyListeners();
  }

  Future<bool> addStaff({
    required String name,
    required String username,
    required String password,
  }) async {
    final staff = UserModel(
      name: name.trim(),
      username: username.trim(),
      password: password,
      role: 'staff',
    );
    final id = await _db.createUser(staff);
    if (id > 0) {
      await loadStaff();
      return true;
    }
    return false;
  }

  Future<void> deleteStaff(int id) async {
    await _db.deleteUser(id);
    await loadStaff();
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) return false;
    if (_currentUser!.password != oldPassword) return false;
    if (newPassword.isEmpty || newPassword.length < 6) return false;
    final id = _currentUser!.id;
    await _db.updateUserPassword(id!, newPassword);
    _currentUser = _currentUser!.copyWith(password: newPassword);
    notifyListeners();
    return true;
  }

  Future<bool> changeOwnerPassword({
    required String oldPassword,
    required String newPassword,
  }) => changePassword(oldPassword: oldPassword, newPassword: newPassword);

  Future<void> logout() async {
    if (_currentShift != null) {
      await _db.closeShift(_currentShift!.id!);
      _currentShift = null;
    }
    await _db.clearSession();
    _currentUser = null;
    notifyListeners();
  }
}
