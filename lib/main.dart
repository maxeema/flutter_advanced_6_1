import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart'; //needed for basename

import 'auth.dart' as fbAuth;
import 'storage.dart' as fbStorage;

void main() async {

  runApp(new MaterialApp(
    home: new MyApp(),
  ));

}

class MyApp extends StatefulWidget {

  @override
  _State createState() => new _State();
}

class _State extends State<MyApp> {

  final scaffoldKey = GlobalKey<ScaffoldState>();

  String _authStatus = 'Not Authenticated',
         _uploadStatus = 'Not Uploaded';
  String _location;
  FirebaseUser _user;

  var _isUploading = false,
      _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _signIn();
    });
  }

  void _signIn() async => _wrapErrorHandling(() async {
    setState(() {
      _isAuthenticating = true;
    });
    try {
      final authResult = await fbAuth.signInGoogle();
      final user = authResult.user;
      if (user != null) {
        setState(() {
          _user = user;
          _authStatus = 'Signed in with Google\n'
              'User uid: ${user.uid}\n'
              'User email: ${user.email}\n'
              'User name: ${user.displayName}\n'
              'User phoneNumber: ${user.phoneNumber}';
        });
      } else {
        setState(() {
          _authStatus = 'Could not sign in!';
        });
      }
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  });

  void _signOut() async => _wrapErrorHandling(() async {
    await fbAuth.signOut();
    setState(() {
      _authStatus = 'Signed out';
      _user = null;
    });
  });

  void _upload() async => _wrapErrorHandling(() async {
    if (_user == null)
      throw "Please, Sign In first!";
    //
    setState(() {
      _isUploading = true;
    });
    try {
      Directory systemTempDir = Directory.systemTemp;
      File file = await File('${systemTempDir.path}/test.txt').create();
      await file.writeAsString('Firebase is awesome! (${DateTime.now()})');

      String location = await fbStorage.upload(file, basename(file.path));
      setState(() {
        _location = location;
        _uploadStatus = 'Uploaded!\n$location';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  });

  void _download() async => _wrapErrorHandling(() async {
    setState(() {
      _isUploading = true;
    });
    try {
      Uri location = Uri.parse(_location);
      String data = await fbStorage.download(location);
      setState(() {
        _uploadStatus = 'Downloaded: $data';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  });

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: scaffoldKey,
      appBar: new AppBar(
        title: new Text('Name here'),
      ),
      body: new Container(
        padding: new EdgeInsets.all(32.0),
        child: new Center(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _isAuthenticating ? CircularProgressIndicator() : new Text(_authStatus),
              new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  new RaisedButton(onPressed: _user != null ? _signOut : null, child: new Text('Sign out'),),
                  new RaisedButton(onPressed: _user == null ? _signIn : null, child: new Text('Sign in Google'),),
                ],
              ),
              Divider(height: 20,),
              _isUploading ? CircularProgressIndicator() : new Text(_uploadStatus),
              new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  new RaisedButton(onPressed: _upload, child: new Text('Upload'),),
                  new RaisedButton(onPressed: _location != null ? _download : null, child: new Text('Download'),),
                ],
              ),
            ],
          ),
        )
      ),
    );
  }

  _wrapErrorHandling(action()) async {
    try {
      await action();
    } catch (e) {
      _showSnack("$e");
    }
  }

  _showSnack(String text) {
    scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(text),));
  }

}
