import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/localization.dart';
import 'utils.dart';

class SignUpView extends StatefulWidget {
  final String email;
  final bool passwordCheck;

  SignUpView(this.email, this.passwordCheck, {Key key}) : super(key: key);

  @override
  _SignUpViewState createState() => new _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  TextEditingController _controllerEmail;
  TextEditingController _controllerDisplayName;
  TextEditingController _controllerPassword;
  TextEditingController _controllerCheckPassword;

  final FocusNode _focusPassword = FocusNode();

  bool _valid = false;

  @override
  dispose() {
    _focusPassword.dispose();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    _controllerEmail = new TextEditingController(text: widget.email);
    _controllerDisplayName = new TextEditingController();
    _controllerPassword = new TextEditingController();
    _controllerCheckPassword = new TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    _controllerEmail.text = widget.email;
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(FFULocalizations.of(context).signUpTitle),
        elevation: 4.0,
      ),
      body: new Builder(
        builder: (BuildContext context) {
          return new Padding(
            padding: const EdgeInsets.all(16.0),
            child: new ListView(
              children: <Widget>[
                new TextField(
                  controller: _controllerEmail,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  onSubmitted: _submit,
                  decoration: new InputDecoration(
                      labelText: FFULocalizations.of(context).emailLabel),
                ),
                const SizedBox(height: 8.0),
                new TextField(
                  controller: _controllerDisplayName,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  autocorrect: false,
                  onChanged: _checkValid,
                  onSubmitted: _submitDisplayName,
                  decoration: new InputDecoration(
                      labelText: FFULocalizations.of(context).nameLabel),
                ),
                const SizedBox(height: 8.0),
                new TextField(
                  controller: _controllerPassword,
                  obscureText: true,
                  autocorrect: false,
                  onSubmitted: _submit,
                  focusNode: _focusPassword,
                  decoration: new InputDecoration(
                      labelText: FFULocalizations.of(context).passwordLabel),
                ),
                !widget.passwordCheck
                    ? new Container()
                    : new TextField(
                        controller: _controllerCheckPassword,
                        obscureText: true,
                        autocorrect: false,
                        decoration: new InputDecoration(
                            labelText: FFULocalizations.of(context)
                                .passwordCheckLabel),
                      ),
              ],
            ),
          );
        },
      ),
      persistentFooterButtons: <Widget>[
        new ButtonBar(
          alignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new FlatButton(
                onPressed: _valid ? () => _connexion(context) : null,
                child: new Row(
                  children: <Widget>[
                    new Text(FFULocalizations.of(context).saveLabel),
                  ],
                )),
          ],
        )
      ],
    );
  }

  _submitDisplayName(String submitted) {
    FocusScope.of(context).requestFocus(_focusPassword);
  }

  _submit(String submitted) {
    _connexion(context);
  }

  bool connecting = false;
  _connexion(BuildContext context) async {
    if(connecting){
      return;
    }
    connecting = true;
    if (widget.passwordCheck &&
        _controllerPassword.text != _controllerCheckPassword.text) {
      showErrorDialog(context, FFULocalizations.of(context).passwordCheckError);
      connecting = false;
      return;
    }

    FirebaseAuth _auth = FirebaseAuth.instance;
    try {
      FirebaseUser user = await _auth.createUserWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
      try {
        var userUpdateInfo = new UserUpdateInfo();
        userUpdateInfo.displayName = _controllerDisplayName.text;
        await user.updateProfile(userUpdateInfo);
        Navigator.pop(context, true);
      } catch (e) {
        showErrorDialog(context, e?.toString());
      }
    } on PlatformException catch (e) {
      print("PlatformException Firebase UI: " + (e.toString() ?? ""));
      //TODO improve errors catching
      String msg;
      if(e.code == "ERROR_WEAK_PASSWORD"){
        msg = FFULocalizations.of(context).passwordLengthMessage;
      } else if(e.code == "error" && e.message == "Given String is empty or null"){
        msg = FFULocalizations.of(context).passwordLengthMessage;
      } else {
        msg = "${FFULocalizations.of(context).errorOccurred} (${e.code}, ${e.details ?? ""})";
      }
      showErrorDialog(context, msg);
    }
    connecting = false;
  }

  void _checkValid(String value) {
    setState(() {
      _valid = _controllerDisplayName.text.isNotEmpty;
    });
  }
}
