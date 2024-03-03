import 'package:flutter_dotenv/flutter_dotenv.dart';

// appwrite_client_template.dart
const String endpoint = 'https://cloud.appwrite.io/v1';
//const String project_idd = 'farmhelpswetha';
//const String apiKey = '[YOUR_API_KEY]';

//import the project_id using dotenv

// ignore: non_constant_identifier_names
final String project_id = dotenv.env['APPWRITE_PROJECT_ID']!;


/*
import 'package:appwrite/appwrite.dart';

Client client = Client();
client
    .setEndpoint('https://cloud.appwrite.io/v1')
    .setProject('farmhelpswetha')
    .setSelfSigned(status: true); // For self signed certificates, only use for development

    */