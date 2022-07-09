import 'dart:typed_data';

import 'package:crypto_chateau_dart/client/response.dart';
import 'package:crypto_chateau_dart/dh/dh.dart';

import '../transport/conn_bloc.dart';
import 'models.dart';

class ClientController {
  late void Function(Response) onEndpointMessageReceived;

  ClientController({required this.onEndpointMessageReceived});
}

class ConnectParams {
  String host;
  int port;
  bool isEncryptionEnabled;

  ConnectParams(
      {required this.host,
      required this.port,
      required this.isEncryptionEnabled});
}

class Client {
  ClientController clientController;
  ConnectParams connectParams;
  KeyStore keyStore = KeyStore();

  Client({required this.clientController, required this.connectParams}) {
    keyStore.GeneratePrivateKey();
    keyStore.GeneratePublicKey();
  }

  void onEndpointMessageReceived(TcpBloc tcpBloc, Uint8List data) {
    tcpBloc.close();

    int lastMethodNameIndex = getLastMethodNameIndex(data);
    String methodName =
        String.fromCharCodes(data.sublist(0, lastMethodNameIndex));

    Uint8List body = data.sublist(lastMethodNameIndex + 1);
    Response response = GetResponse(methodName, body);
    clientController.onEndpointMessageReceived(response);
  }

  //handlers
  GetUser(GetUserRequest request) async {
    TcpBloc tcpBloc = TcpBloc(keyStore: keyStore);

    onEncryptEnabled() {
      tcpBloc.sendMessage(SendMessage(message: request.Marshal()));
    }

    TcpController tcpController = TcpController(
        onEncryptionEnabled: onEncryptEnabled,
        onEndpointMessageReceived: onEndpointMessageReceived);

    tcpBloc.connect(
        tcpController,
        Connect(
            host: connectParams.host,
            port: connectParams.port,
            encryptionEnabled: connectParams.isEncryptionEnabled));
  }

  // SendCode(SendCodeRequest request) async {
  //   TcpBloc tcpBloc = TcpBloc();

  //   onEncryptEnabled() {
  //     tcpBloc.sendMessage(SendMessage(message: request.Marshal()));
  //   }

  //   TcpController tcpController = TcpController(
  //       onEncryptionEnabled: onEncryptEnabled,
  //       onEndpointMessageReceived: onEndpointMessageReceived);

  //   tcpBloc.connect(
  //       tcpController,
  //       Connect(
  //           host: connectParams.host,
  //           port: connectParams.port,
  //           encryptionEnabled: connectParams.isEncryptionEnabled));
  // }

  //streams

  void ListenUpdates() async {
    TcpBloc tcpBloc = TcpBloc(keyStore: keyStore);

    onEncryptEnabled() {}

    TcpController tcpController = TcpController(
        onEncryptionEnabled: onEncryptEnabled,
        onEndpointMessageReceived: onEndpointMessageReceived);

    tcpBloc.connect(
        tcpController,
        Connect(
            host: connectParams.host,
            port: connectParams.port,
            encryptionEnabled: connectParams.isEncryptionEnabled));
  }
}

int getLastMethodNameIndex(Uint8List data) {
  int finalIndex = 0;

  for (var i = 0; i < data.length; i++) {
    if (data[i] == Uint8List.fromList("#".codeUnits)[0]) {
      finalIndex = i;
    }
  }

  return finalIndex;
}
