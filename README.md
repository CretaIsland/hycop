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

Example program will connect our demo server ( Firbase or Appwrite )
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
4) Create Your firesbase database (realtime database)
5) Create Your storage
5) Create Your functions

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

flutter run -d chrome --web-renderer html
# or
flutter run -d chrome --web-renderer canvaskit

# ############################
# build
# ############################

# 초기에 한번, 빌드 위치를 잡아준다.  이미 잡았다면, 기존 빌드 폴더가 무효가 되므로 주의한다.
cd example
flutter config --build-dir=../release/hycop_demo_v1  
# 그리고 VCode 를 다시 시작해야 한다.
# 이후, build 는 다음과 같다.

flutter build web --web-renderer html --release --base-href="/hycop_demo_v1/"
# or
flutter build web --web-renderer canvaskit --release --base-href="/hycop_demo_v1/"

# ############################
# Release
# ############################
# GitHub에 릴리즈하기
# 먼저 GitHub page 에서 repository 를 만든다.  반드시 public 으로 만들어야 한다.
# hycop_demo_v1 로 repository 를 만든것을 가정한다.

cd ../release/hycop_demo_v1/web
git init
git add .
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/CretaIsland/hycop_demo_v1.git
git push -u origin main

# GitHub repository 에서  Settings - 좌측 세로 메뉴에서 Pages
# 화면 중간에 Branch 를 main 으로 하고 Save 
# 한 5분 정도 기다린 다음 page 를 refresh 하면 아래와 같은 페이지 주소가 나온다.
# 릴리즈 된것이다.

https://cretaisland.github.io/hycop_demo_v1/

# ############################
# Packaging
# ############################

# create package
# 한칸 위에 hycop_web 이란 이름으로 패키지를 만든다.
flutter create --org com.sqisoft.hycop --template=plugin ../hycop_web

# add web platform
flutter create -t plugin --platforms web ../hycop_web


# ############################
# Publishing
# ############################

# 사전 점검
cd ../hycop_web
flutter pub publish --dry-run

# pubspec.yaml 에 다음을 추가함.
flutter_web_plugins:
    sdk: flutter
 Homepage : 에 hycop Repository https://github.com/CretaIsland/hycop.git 정보를 추가해준다.


# 릴리즈
flutter pub publish
"# hycop" 

