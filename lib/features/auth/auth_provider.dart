import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/collection_repository.dart';
import '../../data/repositories/vault_item_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(
    this._itemRepository,
    this._collectionRepository, {
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final VaultItemRepository _itemRepository;
  final CollectionRepository _collectionRepository;
  final FirebaseAuth _firebaseAuth;
  StreamSubscription<User?>? _subscription;

  User? user;
  bool isInitializing = true;
  bool isBusy = false;
  String? errorMessage;

  bool get isSignedIn => user != null;
  bool get isUsingCloudStorage => isSignedIn;

  void initialize() {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    user = _firebaseAuth.currentUser;
    await _activateStorageFor(user);
    isInitializing = false;
    _subscription = _firebaseAuth.authStateChanges().listen((nextUser) async {
      user = nextUser;
      await _activateStorageFor(nextUser);
      isInitializing = false;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    return _runAuthAction(() {
      return _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  Future<bool> createAccount({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return _runAuthAction(() async {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final name = displayName?.trim();
      if (name != null && name.isNotEmpty) {
        await credential.user?.updateDisplayName(name);
      }
      return credential;
    });
  }

  Future<void> signOut() async {
    errorMessage = null;
    await _firebaseAuth.signOut();
    user = null;
    await _activateStorageFor(null);
    notifyListeners();
  }

  Future<bool> _runAuthAction(Future<UserCredential> Function() action) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final credential = await action();
      await _activateStorageFor(credential.user);
      return true;
    } on FirebaseAuthException catch (error) {
      errorMessage = _friendlyMessage(error);
      return false;
    } catch (_) {
      errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _activateStorageFor(User? firebaseUser) async {
    final userId = firebaseUser?.uid;
    await _collectionRepository.useUser(userId);
    await _itemRepository.useUser(userId);
  }

  String _friendlyMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Use a stronger password.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
