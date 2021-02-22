import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

void main(List<String> arguments) async {
  if (arguments.length == 4) {
    if (arguments[2] == "upload") {
      File file = File(arguments[3]);
      String fileAsString = file.readAsStringSync();
      Map<String, dynamic> fileAsMap = jsonDecode(fileAsString);
      String locale = fileAsMap["@@locale"] ?? "en";
      print(locale);
      Uint8List fileAsBytes = await file.readAsBytes();
      Map<String, String> headers = {
        "X-Api-Token": arguments[0],
      };
      Map<String, dynamic> body = {
        "filename": "intl_en.json",
        "data": base64Encode(fileAsBytes),
        "lang_iso": locale,
      };

      http.Client client = http.Client();

      http.Response response = await client.post("https://api.lokalise.com/api2/projects/${arguments[1]}/files/upload",
          headers: headers, body: jsonEncode(body));

      print(response.statusCode);
      print(response.body);
      return;
    } else if (arguments[2] == "download") {
      Map<String, String> headers = {
        "X-Api-Token": arguments[0],
      };
      Map<String, dynamic> body = {
        "format": "json",
        "original_filenames": true,
      };

      http.Client client = http.Client();

      http.Response lokaliseResponse = await client.post(
          "https://api.lokalise.com/api2/projects/${arguments[1]}/files/download",
          headers: headers,
          body: jsonEncode(body));

      print(lokaliseResponse.statusCode);
      print(lokaliseResponse.body);

      if (lokaliseResponse?.body == null ||
          lokaliseResponse.body.isEmpty ||
          !lokaliseResponse.body.contains("bundle_url")) {
        print("no file downloaded");
        return;
      }

      Map<String, dynamic> lokliseResponseBody = jsonDecode(lokaliseResponse.body);

      http.Response response = await client.get(lokliseResponseBody["bundle_url"]);
      final archive = ZipDecoder().decodeBytes(response.bodyBytes);
      for (final file in archive) {
        final filename = file.name.split("/")[1].split(".")[0] + ".arb";
        if (file.isFile) {
          final data = file.content as List<int>;
          File(arguments[3] + Platform.pathSeparator + filename)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        }
      }
      return;
    }
  }
  print("usage: <api token> <project id> upload/download <source/destination>");
  return;
}
