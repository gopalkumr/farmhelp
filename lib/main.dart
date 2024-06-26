import 'package:animated_login/animated_login.dart';
import 'package:appwrite/models.dart';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:farmhelp/src/Home/enum_shelf.dart';
import 'package:farmhelp/src/providers/appwrite_client.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:farmhelp/ui/screen/home_page.dart';
import 'package:farmhelp/ui/screen/final_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dialog_builders.dart';
import 'login_functions.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");
  //(fileName: ".env");

  // String dsn = dotenv['SENTRY_DSN'] ?? '';
  //load the .env file
  String dsn = dotenv.env['SENTRY_DSN'] ?? '';

  await SentryFlutter.init(
    (options) {
      options.dsn = dsn;
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(MyApp()),
  );
  AppwriteClient.getClient();

  runApp(MyApp(
      //firstCamera: firstCamera,
      ));
}

class MyApp extends StatelessWidget {
  /// Main app widget.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'farmhelp',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: _getLoginState(),
        builder: (context, snapshot) {
          //this is to test if isLogedin is working or not
          print('HIIIIIIIIIIIIIIIIIIIIIII');
          print(snapshot.data);
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(); //Show a loading indicator while waiting
          } else {
            //if _getLoginState returns true, show the HomePage
            if (snapshot.data == true) {
              return Homepage();
            } else {
              //if _getLoginState returns false, show the LoginScreen
              return const LoginScreen();
            }
          }
        },
      ),
      routes: {
        '/login': (BuildContext context) => const LoginScreen(),
        '/forgotPass': (BuildContext context) => const ForgotPassword(),
        '/signupverification': (BuildContext context) =>
            const Signupverification(),
        '/Homepage': (BuildContext context) => Homepage(),
        '/final': (BuildContext context) => FinalPage(),
      },
    );
  }

  Future<bool> _getLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }
}

/// Example login screen
class LoginScreen extends StatefulWidget {
  /// Simulates the multilanguage, you will implement your own logic.
  /// According to the current language, you can display a text message
  /// with the help of [LoginTexts] class.
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Example selected language, default is English.
  LanguageOption language = _languageOptions[1];

  /// Current auth mode, default is [AuthMode.login].
  AuthMode currentMode = AuthMode.login;

  CancelableOperation? _operation;

  @override
  Widget build(BuildContext context) {
    return AnimatedLogin(
      //due to some misunderstanding, another parameter called logindata is passed
      onLogin: (LoginData data) async =>
          _authOperation(LoginFunctions(context).onLogin(data), currentMode),
      onSignup: (SignUpData data) async =>
          _authOperation(LoginFunctions(context).onSignup(data), currentMode),

      onForgotPassword: _onForgotPassword,
      //logo: Image.asset('assets/images/logo.gif'),
      logo: Image.asset('assets/logo.gif'),
      // backgroundImage: 'images/background_image.jpg',
      signUpMode: SignUpModes.both,
      socialLogins: _socialLogins(context),
      loginDesktopTheme: _desktopTheme,
      loginMobileTheme: _mobileTheme,
      loginTexts: _loginTexts,
      emailValidator: ValidatorModel(
          validatorCallback: (String? email) => 'What an email! $email'),
      changeLanguageCallback: null,
      initialMode: currentMode,
      onAuthModeChange: (AuthMode newMode) async {
        currentMode = newMode;
        await _operation?.cancel();
      },
    );
  }

  // Erase this, this is for testing the login verification wheather github copilot can write or not

  Future<String?> _authOperation(
      Future<String?> func, AuthMode authMode) async {
    await _operation?.valueOrCancellation();
    _operation = CancelableOperation.fromFuture(func);
    final String? res = await _operation?.valueOrCancellation();
    if (_operation?.isCompleted == true) {
      // DialogBuilder(context).showResultDialog(res ?? 'Successful.'); modified

      //modified -2
      /*
      if (res != null) {
        DialogBuilder(context).showResultDialog(res);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          //print res value
        );
      } else {
        DialogBuilder(context).showResultDialog('Unsuccessful');
        final String? funcres = await res;
        print(funcres);
      }  */

      // check if the auth mode is login and navigate to HomeScreen if it is
      //this down line will be disabled fot testing login verification

      /*

      if (authMode == AuthMode.login) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
          //print res value
        );
      } else if (authMode == AuthMode.signup) {
        try {
          Client client = AppwriteClient.getClient();
          Account account = Account(client);
          final result = await account.create(
              userId: ID.unique(), email: 'gopal@g.com', password: 'password');
          //add this line for push replacement
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => Signupverification()));
        } on AppwriteException catch (e) {
          print(e.message);
        }
      } */
    }
    print(res);
    if (authMode == AuthMode.login) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => FinalPage()),
      );
    }
    return res;
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); // Reset the login state

    // Navigate back to LoginScreen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<String?> _onForgotPassword(String email) async {
    await _operation?.cancel();
    return await LoginFunctions(context).onForgotPassword(email);
  }

  static List<LanguageOption> get _languageOptions => const <LanguageOption>[
        LanguageOption(
          value: 'Hindi',
          code: 'IN',
          iconPath: 'assets/india.png',
        ),
        LanguageOption(
          value: 'English',
          code: 'EN',
          iconPath: 'assets/en.png',
        ),
      ];

  /// You can adjust the colors, text styles, button styles, borders
  /// according to your design preferences for *DESKTOP* view.
  /// You can also set some additional display options such as [showLabelTexts].
  LoginViewTheme get _desktopTheme => _mobileTheme.copyWith(
        // To set the color of button text, use foreground color.
        actionButtonStyle: ButtonStyle(
          foregroundColor: MaterialStateProperty.all(Colors.white),
        ),
        dialogTheme: const AnimatedDialogTheme(
          languageDialogTheme: LanguageDialogTheme(
              optionMargin: EdgeInsets.symmetric(horizontal: 80)),
        ),
        loadingSocialButtonColor: Colors.blue,
        loadingButtonColor: Colors.white,
        privacyPolicyStyle: const TextStyle(color: Colors.black87),
        privacyPolicyLinkStyle: const TextStyle(
            color: Colors.blue, decoration: TextDecoration.underline),
      );

  /// You can adjust the colors, text styles, button styles, borders
  /// according to your design preferences for *MOBILE* view.
  /// You can also set some additional display options such as [showLabelTexts].
  LoginViewTheme get _mobileTheme => LoginViewTheme(
        // showLabelTexts: false,
        backgroundColor: Colors.green, // const Color(0xFF6666FF),
        formFieldBackgroundColor: Colors.white,
        formWidthRatio: 60,
        actionButtonStyle: ButtonStyle(
          foregroundColor: MaterialStateProperty.all(Colors.blue),
        ),
        animatedComponentOrder: const <AnimatedComponent>[
          AnimatedComponent(
            component: LoginComponents.logo,
            animationType: AnimationType.right,
          ),
          AnimatedComponent(component: LoginComponents.title),
          AnimatedComponent(component: LoginComponents.description),
          AnimatedComponent(component: LoginComponents.formTitle),
          AnimatedComponent(component: LoginComponents.socialLogins),
          AnimatedComponent(component: LoginComponents.useEmail),
          AnimatedComponent(component: LoginComponents.form),
          AnimatedComponent(component: LoginComponents.notHaveAnAccount),
          AnimatedComponent(component: LoginComponents.forgotPassword),
          AnimatedComponent(component: LoginComponents.policyCheckbox),
          AnimatedComponent(component: LoginComponents.changeActionButton),
          AnimatedComponent(component: LoginComponents.actionButton),
        ],
        privacyPolicyStyle: const TextStyle(color: Colors.white70),
        privacyPolicyLinkStyle: const TextStyle(
            color: Colors.white, decoration: TextDecoration.underline),
      );

  LoginTexts get _loginTexts => LoginTexts(
        nameHint: _username,
        login: _login,
        signUp: _signup,
        // signupEmailHint: 'Signup Email',
        // loginEmailHint: 'Login Email',
        // signupPasswordHint: 'Signup Password',
        // loginPasswordHint: 'Login Password',
      );

  /// You can adjust the texts in the screen according to the current language
  /// With the help of [LoginTexts], you can create a multilanguage scren.
  String get _username => language.code == 'TR' ? 'Kullanıcı Adı' : 'Username';

  String get _login => language.code == 'TR' ? 'Giriş Yap' : 'Login';

  String get _signup => language.code == 'TR' ? 'Kayıt Ol' : 'Sign Up';

  /// Social login options, you should provide callback function and icon path.
  /// Icon paths should be the full path in the assets
  /// Don't forget to also add the icon folder to the "pubspec.yaml" file.
  List<SocialLogin> _socialLogins(BuildContext context) => <SocialLogin>[
        SocialLogin(
            callback: () async => _socialCallback('Google'),
            iconPath: 'assets/google.png'),
        SocialLogin(
            callback: () async => _socialCallback('Facebook'),
            iconPath: 'assets/facebook.png'),
        SocialLogin(
            callback: () async => _socialCallback('LinkedIn'),
            iconPath: 'assets/linkedin.png'),
      ];

  Future<String?> _socialCallback(String type) async {
    await _operation?.cancel();
    _operation = CancelableOperation.fromFuture(
        LoginFunctions(context).socialLogin(type));
    final String? res = await _operation?.valueOrCancellation();
    if (_operation?.isCompleted == true && res == null) {
      DialogBuilder(context)
          .showResultDialog('Successfully logged in with $type.');
    }
    return res;
  }
}

/// Example forgot password screen
