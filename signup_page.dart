import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:new_firebase_login/Myhome_page.dart';
import 'package:new_firebase_login/uihelper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class signUpPage extends StatefulWidget {
  const signUpPage({Key? key}) : super(key: key);

  @override
  State<signUpPage> createState() => _signUpPageState();
}

class _signUpPageState extends State<signUpPage> {
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


  // signUp(String email, String password) async {
  //   if (email.isEmpty || password.isEmpty) {
  //     uihelper.CustomAlertButton(context, "Enter Required Fields");
  //   } else {
  //     try {
  //       UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
  //       Navigator.push(context, MaterialPageRoute(builder: (context) => MyHomePage(title: "HomePage")));
  //
  //       // Save login status
  //       SharedPreferences prefs = await SharedPreferences.getInstance();
  //       prefs.setBool('isLoggedIn', true);
  //
  //       // Navigate to home page
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (context) => MyHomePage(title: "")),
  //       );
  //
  //       emailController.clear();
  //       passwordController.clear();
  //     } catch (ex) {
  //       uihelper.CustomAlertButton(context, ex.toString());
  //     }
  //   }
  // }

  signUp(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      uihelper.CustomAlertButton(context, "Enter Required Fields");
    } else {
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);

        // Save login status
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('isLoggedIn', true);

        // Navigate to home page and remove sign-up page from the route stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage(title: "HomePage")),
              (route) => false, // Remove all routes from the stack
        );

        emailController.clear();
        passwordController.clear();
      } catch (ex) {
        uihelper.CustomAlertButton(context, ex.toString());
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign Up Page"),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          uihelper.CustomTextField(emailController, "Email", Icons.mail, false,(){}),
          uihelper.CustomTextField(
              passwordController, "Password", Icons.password, true,(){}),
          SizedBox(
            height: 30,
          ),
          uihelper.CustomButton(() {
            signUp(emailController.text.toString(),
                passwordController.text.toString());
          }, "sign Up")
        ],
      ),
    );
  }

  void SignUp() async {
    // Perform sign-up logic here
    // After successful sign-up, set the isLoggedIn flag to true
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);

    // Navigate to home page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MyHomePage(title: "")),
    );
  }
}


