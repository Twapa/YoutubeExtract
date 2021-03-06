import 'package:http/http.dart' as http;

import 'operations.dart';

final _deciphererFuncNameExp = RegExp(
    r'(\w+)=function\(\w+\){(\w+)=\2\.split\(\x22{2}\);.*?return\s+\2\.join\(\x22{2}\)}');

final _deciphererDefNameExp = RegExp(r'([\$_\w]+).\w+\(\w+,\d+\);');

final _calledFuncNameExp = RegExp(r'\w+(?:.|\[)(\"?\w+(?:\")?)\]?\(');

final _indexExp = RegExp(r'\(\w+,(\d+)\)');

final _cipherCache = <String, List<CipherOperation>>{};

/// Returns a [Future] that completes with a [List] of [CipherOperation]
Future<List<CipherOperation>> getCipherOperations(
    String playerSourceUrl, http.Client client) async {
  if (_cipherCache.containsKey(playerSourceUrl)) {
    return _cipherCache[playerSourceUrl];
  }

  var raw = (await client.get(playerSourceUrl)).body;

  var deciphererFuncName = _deciphererFuncNameExp.firstMatch(raw)?.group(1);

  if (deciphererFuncName.isNullOrWhiteSpace) {
    throw Exception('Could not find decipherer name.');
  }

  var exp = RegExp(r'(?!h\.)'
      '${RegExp.escape(deciphererFuncName)}'
      r'=function\(\w+\)\{(.*?)\}');
  var decipherFuncBody = exp.firstMatch(raw)?.group(1);
  if (decipherFuncBody.isNullOrWhiteSpace) {
    throw Exception('Could not find decipherer body.');
  }

  var deciphererFuncBodyStatements = decipherFuncBody.split(';');
  var deciphererDefName =
      _deciphererDefNameExp.firstMatch(decipherFuncBody)?.group(1);

  exp = RegExp(
      r'var\s+'
      '${RegExp.escape(deciphererDefName)}'
      r'=\{(\w+:function\(\w+(,\w+)?\)\{(.*?)\}),?\};',
      dotAll: true);
  var deciphererDefBody = exp.firstMatch(raw)?.group(0);

  var operations = <CipherOperation>[];

  for (var statement in deciphererFuncBodyStatements) {
    var calledFuncName = _calledFuncNameExp.firstMatch(statement)?.group(1);
    if (calledFuncName.isNullOrWhiteSpace) {
      continue;
    }

    final funcNameEsc = RegExp.escape(calledFuncName);

    var exp =
        RegExp('$funcNameEsc' r':\bfunction\b\([a],b\).(\breturn\b)?.?\w+\.');

    // Slice
    if (exp.hasMatch(deciphererDefBody)) {
      var index = int.parse(_indexExp.firstMatch(statement).group(1));
      operations.add(SliceCipherOperation(index));
      continue;
    }

    // Swap
    exp = RegExp('$funcNameEsc' r':\bfunction\b\(\w+\,\w\).\bvar\b.\bc=a\b');
    if (exp.hasMatch(deciphererDefBody)) {
      var index = int.parse(_indexExp.firstMatch(statement).group(1));
      operations.add(SwapCipherOperation(index));
      continue;
    }

    // Reverse
    exp = RegExp('$funcNameEsc' r':\bfunction\b\(\w+\)');
    if (exp.hasMatch(deciphererDefBody)) {
      operations.add(ReverseCipherOperation());
    }
  }

  return _cipherCache[playerSourceUrl] = operations;
}

/// Returns a Uri with a signature.
/// The result is cached for the [playerSourceUrl]
Future<Uri> decipherUrl(
    String playerSourceUrl, String cipher, http.Client client) async {
  var cipherDic = Uri.splitQueryString(cipher);

  var url = Uri.parse(cipherDic['url']);
  var signature = cipherDic['s'];

  var cipherOperations = await getCipherOperations(playerSourceUrl, client);

  var query = Map<String, dynamic>.from(url.queryParameters);

  signature = cipherOperations.decipher(signature);
  query[cipherDic['sp']] = signature;
  
  return url.replace(queryParameters: query);
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

  static final _exp = RegExp(r'\D');

  /// Strips out all non digit characters.
  String get stripNonDigits => replaceAll(_exp, '');
}

extension ListDecipher on List<CipherOperation> {
  /// Apply the every CipherOperation on the [signature]
  String decipher(String signature) {
    for (var operation in this) {
      signature = operation.decipher(signature);
    }

    return signature;
  }
}
