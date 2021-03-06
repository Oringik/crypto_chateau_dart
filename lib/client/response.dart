import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto_chateau_dart/client/models.dart';

Message GetResponse(String methodName, Uint8List data) {
  Map<String, Uint8List> params = getParams(data);

  switch (methodName) {
    case "SendCode":
      Uint8List? err = params["error"];
      if (err != null) {
        return Error(handlerName: methodName, msg: String.fromCharCodes(err));
      }
      checkCountParams(0, params.length);
      var response = SendCodeResponse();
      return response;
    case "Register":
      Uint8List? err = params["error"];
      if (err != null) {
        return Error(handlerName: methodName, msg: String.fromCharCodes(err));
      }
      checkCountParams(1, params.length);
      var response = RegisterResponse();
      response.Unmarshal(params);
      return response;
    case "HandleCode":
      Uint8List? err = params["error"];
      if (err != null) {
        return Error(handlerName: methodName, msg: String.fromCharCodes(err));
      }
      checkCountParams(0, params.length);
      var response = HandleCodeResponse();
      return response;
    case "AuthToken":
      Uint8List? err = params["error"];
      if (err != null) {
        return Error(handlerName: methodName, msg: String.fromCharCodes(err));
      }
      checkCountParams(0, params.length);
      var response = AuthTokenResponse();
      return response;
    case "AuthCreds":
      Uint8List? err = params["error"];
      if (err != null) {
        return Error(handlerName: methodName, msg: String.fromCharCodes(err));
      }
      checkCountParams(1, params.length);
      var response = AuthCredentialsResponse();
      response.Unmarshal(params);
      return response;
  }

  throw "incorrect method";
}

checkCountParams(int assertCount, int actualCount) {
  if (assertCount != actualCount) {
    throw "incorrect params nums";
  }
}

Map<String, Uint8List> getParams(Uint8List p) {
  Map<String, Uint8List> params = {};

  Uint8List paramBuf = Uint8List(p.length);
  Uint8List valueBuf = Uint8List(p.length);

  int paramBufLast = -1;
  int valueBufLast = -1;
  int paramBufIndex = 0;
  int valueBufIndex = 0;

  bool paramFilled = false;
  bool startedParsingValue = false;

  bool stringParamParsing = false;

  int objectOpenBracketsCount = 0;
  int objectCloseBracketsCount = 0;

  int delimSymb = utf8.encode(',')[0];
  int colonSymb = utf8.encode(':')[0];
  int spaceSymb = utf8.encode(' ')[0];
  int quoteSymb = utf8.encode('"')[0];
  int openBracketSymb = utf8.encode('(')[0];
  int closeBracketSymb = utf8.encode(')')[0];

  for (var i = 0; i < p.length; i++) {
    if ((p[i] == delimSymb &&
            (objectOpenBracketsCount == objectCloseBracketsCount)) ||
        i == p.length - 1) {
      if ((i != p.length - 1) && (p[i + 1] == delimSymb)) {
        continue;
      }

      if (i == p.length - 1 &&
          stringParamParsing == true &&
          p[i] != quoteSymb) {
        throw "incorrect message format: close quote is missing";
      }

      if (i == p.length - 1 &&
          stringParamParsing == false &&
          p[i] != closeBracketSymb) {
        valueBuf[valueBufIndex] = p[i];
        valueBufIndex++;
      }

      if (paramBufLast == paramBufIndex || (valueBufLast == valueBufIndex)) {
        throw "incorrect message format: null value";
      }

      String param = String.fromCharCodes(
          paramBuf.sublist(paramBufLast + 1, paramBufIndex));
      Uint8List value = valueBuf.sublist(valueBufLast + 1, valueBufIndex);
      params[param] = value;

      paramBufLast = paramBufIndex - 1;
      valueBufLast = valueBufIndex - 1;
      paramFilled = false;
      startedParsingValue = false;

      objectOpenBracketsCount = 0;
      objectCloseBracketsCount = 0;
    } else if (p[i] == colonSymb &&
        stringParamParsing == false &&
        objectOpenBracketsCount == objectCloseBracketsCount &&
        startedParsingValue == false) {
      paramFilled = true;
    } else if (p[i] == spaceSymb &&
        stringParamParsing == false &&
        startedParsingValue == false) {
      continue;
    } else if (p[i] == quoteSymb && startedParsingValue == false) {
      stringParamParsing = !stringParamParsing;
    } else if (p[i] == openBracketSymb && startedParsingValue == false) {
      objectOpenBracketsCount++;
    } else if (p[i] == closeBracketSymb && startedParsingValue == false) {
      objectCloseBracketsCount++;
    } else {
      if (!paramFilled) {
        paramBuf[paramBufIndex] = p[i];
        paramBufIndex++;
      } else {
        valueBuf[valueBufIndex] = p[i];
        valueBufIndex++;
        startedParsingValue = true;
      }
    }
  }

  return params;
}
