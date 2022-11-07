import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences{
  static late SharedPreferences _preferences ;
  static Future<void> init()async{
    _preferences = await SharedPreferences.getInstance();
  }
  static setMode(bool v){
    _preferences.setBool("Mode", v);
  }

  static bool getMode()=> _preferences.getBool("Mode") ?? false;

}
