// web implementation
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> storageSave(String key, String value) async {
  html.window.localStorage[key] = value;
}

Future<String?> storageRead(String key) async {
  return html.window.localStorage[key];
}

Future<void> storageRemove(String key) async {
  html.window.localStorage.remove(key);
}
