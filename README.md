<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->
Hycop is a package for web applications that want to use PAS services provided by firebase or appwrite.

## Features

Hycop allows you to use the following 6 services provided by firebase or appwrite .

Database 
RealTime
Serverless function
Account
Storage
*SocketIO

(*SocketIO is not a service provided by Firebase or Appwrite, but a service created by us.)


## Getting started

Example program will connect our demo server ( Firebase or Appwrite )
You can run demo program in example folder such as follows 

% cd example
% flutter run -d chrome

## Usage

Please refer to the follwing example pages

1. Database
example/app/databse_example_page.dart
2. RealTime
example/app/real_example_page.dart
3. Storage
example/app/storage_example_page.dart
4. Serverless function
example/app/function_example_page.dart
5. Account
example/app/login_page.dart  
example/app/register_page.dart  
example/app/reset_password_confirm_page.dart  
example/app/user_example_page.dart 
6. SocketIO
example/app/socketio_example_page.dart

7. For Configuration
example/assets/hycop_config_example.json

Example program will connect our demo server ( Firbase or Appwrite )
If you want to have your own firebase or Appwrite server,
Follow the instruction below.

1. Using Firebase Server Case, Create a firebase account as follows

1.1 In Firebase console 
1) Create Your Project
2) Register Your app
3) Create Your firestore database
4) Create Your firebase database (realtime database)
5) Create Your storage
6) Create Your functions

1.2 In your source code
1) Create a "hycop_config.json" file under the your assets folder and fill in the values.
You can refer to "example/assets/hycop_config_example.json" file
and you need to specify "hycop_config.json" in your pubspec.yaml file

2. Using Appwrite Server Case, Create a Your own Appwrite Servera as follows

2.1 Install Docker
Install Docker for your OS according to a commonly known method. 
Docker must be installed on a server with at least 4G of memory.
A server can use https only if it has a domain name.

2.2 Install appwrite
Install appwrite by referring to the description on the appwrite.io homepage.

2.3 Appwrite settings
If you connect to the address of the appwrite server using a web browser, you can access the Appwrite console.
1) When connecting for the first time, enter your ID and password.
2) Create Project
3) Create Database

Unlike firebase, the necessary collections must be created here.
When creating a collections, do not forget to give appropriate read and write privileges.
To use RealTime Service, the 'hycop_delta' collection must be created.
To use Account Service, the 'hycop_user' collection must be created.
The schemas for hycop_user and hycop_delta are in the 'example/assets/collection_hycop_delta.json' and 'example/assets/collection_hycop_user.json'file.

4) Create API Key
5) Create Function
If necessary, you can create a Serverless function by following the instructions on the Appwrite.io page.

3. You need to create 'hycop_config.json' file with firebase or appwrite server information and put it in your assets folder.

The 'hycop_config.json' file can be created by referring to the example/assets/hycop_config_example.json file.
Of course you need to add the 'hycop_config.json' file to assets entry in your'pubspec.yaml' file.

## Additional information

# ############################
# Run
# ############################
cd example
flutter run -d chrome --web-renderer html
# or
flutter run -d chrome --web-renderer canvaskit




########## hycop 의 경우  윈도우와 리눅스를 지원하지 않는 패키지

  WL cupertino_icons: ^1.0.2
  -------------------------XX cloud_functions: ^4.0.7
  #device_info_plus: ^3.2.2

  WL logging: ^1.0.2
  WL flutter_riverpod: ^1.0.4
  WL synchronized: ^3.0.0
  WL uuid: ^4.1.0
  WL equatable: ^2.0.3
  -------------------------XX firebase_database: ^10.3.3
  #firebase: ^9.0.2
  -------------------------WX firebase_core: ^2.21.0
  ------------------------WX cloud_firestore: ^4.3.1
  ------------------------XX cloud_firestore_web: ^3.2.1
  WL appwrite: 11.0.0
  WL routemaster: ^1.0.1
  WL provider: ^6.0.1
  WL font_awesome_flutter: ^10.1.0
  WL shimmer: ^2.0.0
  WL random_string: ^2.3.1
  WL encrypt: ^5.0.1
  ------------------------WX firebase_storage: ^11.4.1
  WL dart_appwrite: 10.0.0
   -------------------------XX md5_file_checksum: ^1.0.3   // Web 도 안됨.
  WL convert: ^3.0.2
  WL crypto: ^3.0.2
  -------------------------XX flutter_dropzone: ^3.0.5
  WL socket_io_client: ^2.0.0
  WL http: ^1.1.0
  -------------------------XX extension_google_sign_in_as_googleapis_auth: ^2.0.7  // --> googleapis_auth 를 써야함.
  -------------------------XX google_sign_in: ^5.4.2
  WL flutter_webrtc: ^0.9.35
  WL firebase_core_platform_interface: ^5.0.0
  WL mediasoup_client_flutter: ^0.8.5
  WL protoo_client: ^0.3.3   // web 이 안됨.
  WL flutter_bloc: ^7.0.1
  WL collection: ^1.17.0