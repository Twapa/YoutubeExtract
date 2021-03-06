import 'dart:convert';

import 'package:YoutubeExtract/lib/extractor/Extractor.dart';

import 'package:http/http.dart' as http;

class DefaultExtractor extends Extractor {
  http.Client httped;
  // \. backslash treats period as special character
  
  static final List<RegExp> YT_PLAYER_CONFIG_PATTERNS = [
    RegExp(r";ytplayer\.config = (\{.*?\})\;ytplayer"),
    RegExp(r";ytplayer\.config = (\{.*?\})\;")
  ];

  static final RegExp YT_PLAYER_CONFIG =
      RegExp(r";ytplayer\.config = ({.*?});");


     
     RegExp YT_INITIAL_DATA = RegExp("window\\[\"ytInitialData\"\\] = (\\{.*?\\});");

   final String DEFAULT_USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36";
  final String DEFAULT_ACCEPT_LANG = "en-US,en;";
  

    Map<String, String> requestProperties = {};
    int retryOnFailure = 3;

  DefaultExtractor() {
     setRequestProperty("User-Agent", DEFAULT_USER_AGENT);
     setRequestProperty("Accept-language", DEFAULT_ACCEPT_LANG);
  }

  @override
 setRequestProperty(String key, String value) {
      requestProperties[key] = value;
  }

  @override
   setRetryOnFailure(int retryOnFailure) {
      if (retryOnFailure < 0)
          throw ("retry count should be > 0");
      this.retryOnFailure = retryOnFailure;
  }

  @override
  extractYtPlayerConfig(String html) {
    var matcher;
    var yt;

    
   
    for (RegExp pattern in YT_PLAYER_CONFIG_PATTERNS) {

      matcher = pattern.firstMatch(html)?.group(1);

      
    }
    return matcher;
    // return json.decode(matcher);
  }

  @override
   String extractYtInitialData(String html){


      var matcher = YT_INITIAL_DATA.firstMatch(html).group(1);

      
          return matcher;
      

      
  }

  @override
  Future<String> loadUrl(String url) async {
    httped = http.Client();
    var connection = await httped.get(url);

    var connection2 = connection.body;
//var decoded = json.decode(connection2);
    return connection2;

    // int retryCount = retryOnFailure;
    // String errorMsg = "";
    // while (retryCount-- >= 0) {
    //     try {
    //         HttpURLConnection connection = (HttpURLConnection) new URL(url).openConnection();
    //         for (Map.Entry<String, String> entry : requestProperties.entrySet()) {
    //             connection.setRequestProperty(entry.getKey(), entry.getValue());
    //         }
    //         int responseCode = connection.getResponseCode();
    //         if (responseCode != 200) {
    //             errorMsg = String.format("Could not load url: %s, response code: %d", url, responseCode);
    //             continue;
    //         }

    //         BufferedReader in = new BufferedReader(new InputStreamReader(
    //                 connection.getInputStream(), "UTF-8"));

    //         StringBuilder sb = new StringBuilder();
    //         String inputLine;
    //         while ((inputLine = in.readLine()) != null)
    //             sb.append(inputLine).append('\n');
    //         in.close();
    //         return sb.toString();
    //     } catch (IOException e) {
    //         errorMsg = String.format("Could not load url: %s, exception: %s", url, e.getMessage());
    //     }
  }
}

extension StringUtility on String {
  /// Returns true if the string is null or empty.
  bool get isNullOrWhiteSpace {
    if (this == null) {
      return true;
    }
    if (trim().isEmpty) {
      return true;
    }
    return false;
  }
}
