import 'dart:io';

import 'package:chat_app/widgets/user_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  var _isLogin = true;
  var _enteredUserName = '';
  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredPasswordConfirmation = '';
  File? _selectedImage;
  var _isUploading = false;

  void _submit() async {
    final valid = _formKey.currentState!.validate();

    if (!valid || (!_isLogin && _selectedImage == null)) {
      return;
    }

    _formKey.currentState!.save();

    try {
      setState(() {
        _isUploading = true;
      });

      if (_isLogin) {
        FocusScope.of(context).unfocus();

        final UserCredential userCredential =
            await _firebase.signInWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );
      } else {
        if (_enteredPassword != _enteredPasswordConfirmation) {
          FocusScope.of(context).unfocus();

          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).clearSnackBars();
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text("Password and Password Confirmation does not match"),
            ),
          );

          setState(() {
            _isUploading = false;
          });
          return;
        }

        FocusScope.of(context).unfocus();

        final UserCredential userCredential =
            await _firebase.createUserWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );

        final Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredential.user!.uid}.jpg');

        await storageRef.putFile(_selectedImage!);
        final imageURL = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': _enteredUserName,
          'email': _enteredEmail,
          'imageURL': imageURL,
        });
      }
    } on FirebaseAuthException catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).clearSnackBars();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? "Authentication failed.",
          ),
        ),
      );
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 30,
                ),
                width: 200,
                child: Image.asset('assets/image/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (!_isLogin)
                            UserImagePicker(
                              onPickImage: (File pickedImage) {
                                _selectedImage = pickedImage;
                              },
                            ),
                          if (!_isLogin)
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: "User Name",
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              onSaved: (value) => _enteredUserName = value!,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter Your User Name';
                                }
                                return null;
                              },
                            ),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Email Address",
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            onSaved: (value) => _enteredEmail = value!,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains('@')) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Password",
                            ),
                            obscureText: true,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            onSaved: (value) => _enteredPassword = value!,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().length < 6 ||
                                  !value.contains('@')) {
                                return 'Password must be at least 6 characters long.';
                              }
                              return null;
                            },
                          ),
                          if (!_isLogin)
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: "Password Confirmation",
                              ),
                              obscureText: true,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              onSaved: (value) =>
                                  _enteredPasswordConfirmation = value!,
                              validator: (value) {
                                if (value == null || value.trim().length < 6) {
                                  return 'Password must be at least 6 characters long.';
                                }
                                return null;
                              },
                            ),
                          const SizedBox(
                            height: 12,
                          ),
                          if (_isUploading) const CircularProgressIndicator(),
                          if (!_isUploading)
                            ElevatedButton(
                              onPressed: () => _submit(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                              ),
                              child: Text(_isLogin ? "Login" : "Signup"),
                            ),
                          if (!_isUploading)
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                });
                              },
                              child: Text(
                                _isLogin
                                    ? "Create an account"
                                    : "I already have an account",
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
