import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:new_firebase_login/Myhome_page.dart';
import 'package:new_firebase_login/signup_page.dart';
import 'package:new_firebase_login/uihelper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  final Key? key;

  const LoginPage({this.key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      // User is already logged in, navigate to home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage(title: "")),
      );
    }
  }

  login(String email, String password) async {
    if (email == "" && password == "") {
      return uihelper.CustomAlertButton(context, "Enter Required Fields");
    } else {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        // Save login status
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('isLoggedIn', true);

        // Navigate to home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage(title: "")),
        );

        emailController.clear();
        passwordController.clear();
      } on FirebaseAuthException catch (ex) {
        return uihelper.CustomAlertButton(context, ex.code.toString());
      }
    }
  }

  // login(String email, String password) async {
  //   if (email == "" && password == "") {
  //     return uihelper.CustomAlertButton(context, "Enter Required Fields");
  //   } else {
  //     UserCredential? usercredential;
  //     try {
  //       usercredential = await FirebaseAuth.instance
  //           .signInWithEmailAndPassword(email: email, password: password)
  //           .then((value) {
  //         Navigator.push(context,
  //             MaterialPageRoute(builder: (context) => MyHomePage(title: "")));
  //         emailController.clear();
  //         passwordController.clear();
  //       });
  //     } on FirebaseAuthException catch (ex) {
  //       return uihelper.CustomAlertButton(context, ex.code.toString());
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login Page"),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          uihelper.CustomTextField(emailController, "Email", Icons.mail, false,(){}),
          uihelper.CustomTextField(
              passwordController, "Password", Icons.password, true,(){}),
          SizedBox(height: 30),
          uihelper.CustomButton(() {
            login(emailController.text.toString(),
                passwordController.text.toString());
          }, "Login"),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Create a new account",
                style: TextStyle(fontSize: 20),
              ),
              TextButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => signUpPage()));
                  },
                  child: Text(
                    'sign up',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w200),
                  ))
            ],
          )
        ],
      ),
    );
  }
}
