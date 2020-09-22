import 'dart:convert';

import 'package:YoutubeExtract/lib/cipher/CachedCipherFactory.dart';
import 'package:YoutubeExtract/lib/cipher/CipherInterface.dart';

import 'package:YoutubeExtract/lib/extractor/DefaultExtractor.dart';
import 'package:YoutubeExtract/lib/extractor/Extractor.dart';
import 'package:YoutubeExtract/lib/model/Extensions.dart';
import 'package:YoutubeExtract/lib/model/YouDetails.dart';
import 'package:YoutubeExtract/lib/model/formats/AudioFormat.dart';
import 'package:YoutubeExtract/lib/model/formats/AudioVideoFormat.dart';
import 'package:YoutubeExtract/lib/model/formats/Format.dart';
import 'package:YoutubeExtract/lib/model/formats/VideoFormat.dart';
import 'package:YoutubeExtract/lib/model/itag.dart';
import 'package:YoutubeExtract/lib/model/quality/enums.dart';
import 'package:YoutubeExtract/lib/model/type.dart';
import 'package:YoutubeExtract/lib/parser/Parser.dart';
import 'package:http/http.dart' as http;

class DefaultParser implements Parser {
  // private static final Pattern subtitleLangCodeRegex = Pattern.compile("lang_code=\"(.{2,3})\"");
  // private static final Pattern textNumberRegex = Pattern.compile("[0-9, ']+");

  Extractor extractor;
  CipherFactory cipherFactory;

  DefaultParser() {
    extractor = DefaultExtractor();

    //  this.cipherFactory = new CachedCipherFactory(extractor);
  }

  // @Override
  // public Extractor getExtractor() {
  //     return extractor;
  // }

  // @Override
  // public CipherFactory getCipherFactory() {
  //     return cipherFactory;
  // }

  @override
  Future<dynamic> getPlayerConfig(String htmlUrl) async {
    String htmled = await extractor.loadUrl(htmlUrl);
    // print(html);

    //print(html);

    var ytPlayerConfig = extractor.extractYtPlayerConfig(htmled);
    // var uri = Uri.splitQueryString(ytPlayerConfig);
    //var jso = json.decode(uri['args']);

    return ytPlayerConfig;

    // return ind;
  }

  @override
  String getJsUrl(var config) {
    return "https://youtube.com" + config["assets"]["js"];
  }

  @override
  VideoDetails getVideoDetails(var config) {
    var args = config["args"];
    var playerResponse = json.decode(args["player_response"]);

    // if (playerResponse.containsKey("videoDetails")) {

    // }
    var videoDetails = playerResponse["videoDetails"];
    var streamingData = playerResponse['streamingData'];

    String liveHLSUrl = null;

    var isLive = videoDetails['isLive'];

    liveHLSUrl = streamingData['hlsManifestUrl'];

    return new VideoDetails(videoDetails, liveHLSUrl);
  }

  // @Override
  // public List<SubtitlesInfo> getSubtitlesInfoFromCaptions(JSONObject config) {
  //     JSONObject args = config.getJSONObject("args");
  //     JSONObject playerResponse = args.getJSONObject("player_response");

  //     if (!playerResponse.containsKey("captions")) {
  //         return Collections.emptyList();
  //     }
  //     JSONObject captions = playerResponse.getJSONObject("captions");

  //     JSONObject playerCaptionsTracklistRenderer = captions.getJSONObject("playerCaptionsTracklistRenderer");
  //     if (playerCaptionsTracklistRenderer == null || playerCaptionsTracklistRenderer.isEmpty()) {
  //         return Collections.emptyList();
  //     }

  //     JSONArray captionsArray = playerCaptionsTracklistRenderer.getJSONArray("captionTracks");
  //     if (captionsArray == null || captionsArray.isEmpty()) {
  //         return Collections.emptyList();
  //     }

  //     List<SubtitlesInfo> subtitlesInfo = new ArrayList<>();
  //     for (int i = 0; i < captionsArray.size(); i++) {
  //         JSONObject subtitleInfo = captionsArray.getJSONObject(i);
  //         String language = subtitleInfo.getString("languageCode");
  //         String url = subtitleInfo.getString("baseUrl");
  //         String vssId = subtitleInfo.getString("vssId");

  //         if (language != null && url != null && vssId != null) {
  //             boolean isAutoGenerated = vssId.startsWith("a.");
  //             subtitlesInfo.add(new SubtitlesInfo(url, language, isAutoGenerated));
  //         }
  //     }
  //     return subtitlesInfo;
  // }

  // @Override
  // public List<SubtitlesInfo> getSubtitlesInfo(String videoId) throws YoutubeException {
  //     String xmlUrl = "https://video.google.com/timedtext?hl=en&type=list&v=" + videoId;

  //     String subtitlesXml = extractor.loadUrl(xmlUrl);

  //     Matcher matcher = subtitleLangCodeRegex.matcher(subtitlesXml);

  //     if (!matcher.find()) {
  //         return Collections.emptyList();
  //     }

  //     List<SubtitlesInfo> subtitlesInfo = new ArrayList<>();
  //     do {
  //         String language = matcher.group(1);
  //         String url = String.format("https://www.youtube.com/api/timedtext?lang=%s&v=%s",
  //                 language, videoId);
  //         subtitlesInfo.add(new SubtitlesInfo(url, language, false));
  //     } while (matcher.find());

  //     return subtitlesInfo;
  // }

  @override
  Future<List<Format>> parseFormats(var config) async {
    var args = config["args"] ?? null;
    var playerResponse = json.decode(args["player_response"]);

    var streamingData = playerResponse["streamingData"];

    var jsonFormats = [];

    var adaptive = streamingData["adaptiveFormats"];
    jsonFormats.addAll(adaptive);

    var formats = streamingData["formats"] ?? null;
    jsonFormats.addAll(formats);

    List<Format> format = [];

    for (Map<String, dynamic> json in jsonFormats) {
      var parseformat = await parseFormat(json, config);

      format.add(parseformat);
      //  format = await parseFormat(json, config);
    }

    // print(format);

    // for (int i = 0; i < jsonFormats.size(); i++) {
    //     JSONObject json = jsonFormats.getJSONObject(i);
    //     if ("FORMAT_STREAM_TYPE_OTF".equals(json.getString("type")))
    //         continue; // unsupported otf formats which cause 404 not found
    //     try {
    //         Format format = parseFormat(json, config);
    //         formats.add(format);
    //     } catch (YoutubeException.CipherException e) {
    //         throw e;
    //     } catch (YoutubeException e) {
    //         System.err.println("Error parsing format: " + json);
    //     } catch (Exception e) {
    //         e.printStackTrace();
    //     }
    // }
    return format;
  }

  // @Override
  // public JSONObject getInitialData(String htmlUrl) throws YoutubeException {
  //     String html = extractor.loadUrl(htmlUrl);

  //     String ytInitialData = extractor.extractYtInitialData(html);
  //     try {
  //         return JSON.parseObject(ytInitialData);
  //     } catch (Exception e) {
  //         throw new YoutubeException.BadPageException("Could not parse initial data json");
  //     }
  // }

  // @Override
  // public PlaylistDetails getPlaylistDetails(String playlistId, JSONObject initialData) {
  //     String title = initialData.getJSONObject("metadata")
  //             .getJSONObject("playlistMetadataRenderer")
  //             .getString("title");
  //     JSONArray sideBarItems = initialData.getJSONObject("sidebar").getJSONObject("playlistSidebarRenderer").getJSONArray("items");
  //     String author = sideBarItems.getJSONObject(1)
  //             .getJSONObject("playlistSidebarSecondaryInfoRenderer")
  //             .getJSONObject("videoOwner")
  //             .getJSONObject("videoOwnerRenderer")
  //             .getJSONObject("title")
  //             .getJSONArray("runs")
  //             .getJSONObject(0)
  //             .getString("text");
  //     JSONArray stats = sideBarItems.getJSONObject(0)
  //             .getJSONObject("playlistSidebarPrimaryInfoRenderer")
  //             .getJSONArray("stats");
  //     int videoCount = extractNumber(stats.getJSONObject(0).getJSONArray("runs").getJSONObject(0).getString("text"));
  //     int viewCount = extractNumber(stats.getJSONObject(1).getString("simpleText"));

  //     return new PlaylistDetails(playlistId, title, author, videoCount, viewCount);
  // }

  // @Override
  // public List<PlaylistVideoDetails> getPlaylistVideos(JSONObject initialData, int videoCount) throws YoutubeException {
  //     JSONObject content;

  //     try {
  //         content = initialData.getJSONObject("contents")
  //                 .getJSONObject("twoColumnBrowseResultsRenderer")
  //                 .getJSONArray("tabs").getJSONObject(0)
  //                 .getJSONObject("tabRenderer")
  //                 .getJSONObject("content")
  //                 .getJSONObject("sectionListRenderer")
  //                 .getJSONArray("contents").getJSONObject(0)
  //                 .getJSONObject("itemSectionRenderer")
  //                 .getJSONArray("contents").getJSONObject(0)
  //                 .getJSONObject("playlistVideoListRenderer");
  //     } catch (NullPointerException e) {
  //         throw new YoutubeException.BadPageException("Playlist initial data not found");
  //     }

  //     List<PlaylistVideoDetails> videos;
  //     if (videoCount > 0) {
  //         videos = new ArrayList<>(videoCount);
  //     } else {
  //         videos = new LinkedList<>();
  //     }
  //     populatePlaylist(content, videos, getClientVersion(initialData));
  //     return videos;
  // }

  Future<Format> parseFormat(var json, var config) async {
    if (json.containsKey("signatureCipher")) {
      Map<String, dynamic> jsonCipher = {};

      var signatureCipher = json["signatureCipher"];
      var signatureCiphered =
          signatureCipher.replaceAll("\\u0026", "&").split("&") ?? null;

      for (String s in signatureCiphered) {
        var keyValue = s.split('=') ?? null;

        // list[0] is your key and list[1] is your value
        jsonCipher[keyValue[0]] = keyValue[1];
      }

      String urlWithSig = jsonCipher["url"] ?? null;

      String urlsig = utf8.decode(urlWithSig.runes.toList());
      

      String s = jsonCipher["s"] ?? null;
      s = utf8.decode(s.runes.toList());

      String jsUrl = getJsUrl(config) ?? null;

      http.Client httped = http.Client();

    //  String signature = await decipherUrl(jsUrl, s, httped);

   //  String decipheredUrl = urlWithSig + "&sig=" + signature;

   //  json['url'] = decipheredUrl;

      
    }

   

    
    // Itag itag;

    int tag = json["itag"];
    type ig = Itag.valueOf(tag);

    bool hasVideo = ig.isVideo();

    bool hasAudio = ig.isAudio();

    
    //var af = AudioFormat(json);
    //print(af);
    // return null;
    // throw ArgumentError('  unknown itag');

    if (hasVideo && hasAudio)
      return AudioVideoFormat(json);
    else if (hasAudio)
      return AudioFormat(json);
    else if (hasVideo) return VideoFormat(json);
    return null;
    //throw ArgumentError('  unknown itag');
  }

  // private void populatePlaylist(JSONObject content, List<PlaylistVideoDetails> videos, String clientVersion) throws YoutubeException {
  //     JSONArray contents = content.getJSONArray("contents");
  //     for (int i = 0; i < contents.size(); i++) {
  //         videos.add(new PlaylistVideoDetails(contents.getJSONObject(i).getJSONObject("playlistVideoRenderer")));
  //     }
  //     if (content.containsKey("continuations")) {
  //     	String continuation = content.getJSONArray("continuations")
  //                 .getJSONObject(0)
  //                 .getJSONObject("nextContinuationData")
  //                 .getString("continuation");
  //         loadPlaylistContinuation(continuation, videos, clientVersion);
  //     }
  // }

  // private void loadPlaylistContinuation(String continuation, List<PlaylistVideoDetails> videos, String clientVersion) throws YoutubeException {
  //     JSONObject content;

  //     String url = "https://www.youtube.com/browse_ajax?ctoken=" + continuation
  //             + "&continuation=" + continuation;

  //     getExtractor().setRequestProperty("X-YouTube-Client-Name", "1");
  //     getExtractor().setRequestProperty("X-YouTube-Client-Version", clientVersion);
  //     String html = getExtractor().loadUrl(url);

  //     try {
  //         JSONArray response = JSON.parseArray(html);
  //         content = response.getJSONObject(1)
  //                 .getJSONObject("response")
  //                 .getJSONObject("continuationContents")
  //                 .getJSONObject("playlistVideoListContinuation");
  //         populatePlaylist(content, videos, clientVersion);
  //     } catch (YoutubeException e) {
  //         throw e;
  //     } catch (Exception e) {
  //         throw new YoutubeException.BadPageException("Could not parse playlist continuation json");
  //     }
  // }

  // private String getClientVersion(JSONObject json) {
  //     JSONArray trackingParams = json.getJSONObject("responseContext")
  //             .getJSONArray("serviceTrackingParams");
  //     if (trackingParams == null) {
  //         return "2.20200720.00.02";
  //     }
  //     for (int ti = 0; ti < trackingParams.size(); ti++) {
  //         JSONArray params = trackingParams.getJSONObject(ti).getJSONArray("params");
  //         for (int pi = 0; pi < params.size(); pi ++) {
  //             if (params.getJSONObject(pi).getString("key").equals("cver")) {
  //                 return params.getJSONObject(pi).getString("value");
  //             }
  //         }
  //     }
  //     return null;
  // }

  // private static int extractNumber(String text) {
  //     Matcher matcher = textNumberRegex.matcher(text);
  //     if (matcher.find()) {
  //         return Integer.parseInt(matcher.group(0).replaceAll("[, ']", ""));
  //     }
  //     return 0;
  // }
}
