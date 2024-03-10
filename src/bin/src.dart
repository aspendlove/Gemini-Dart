import 'dart:io';
import 'dart:typed_data';
import 'queue.dart';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';

var endOfMessage = "\n\n";
final programLogger = Logger();
var speakQueue = Queue<String>([]);
var speaking = false;
var interactive = false;

main(List<String> arguments) async {
  for (var arg in arguments) {
    if (arg == "-i") {
      interactive = true;
      endOfMessage = "\n"; // For ease of use with telnet
    }
  }

  var socket = await ServerSocket.bind(InternetAddress.anyIPv4, 4567);
  final apiKey = Platform.environment['API_KEY'];
  if (apiKey == null) {
    print('No \$API_KEY environment variable');
    exit(1);
  }

  socket.listen((client) {
    handleConnection(client, apiKey);
  });
}

void handleConnection(Socket client, String apiKey) {
  print('Connection from'
      ' ${client.remoteAddress.address}:${client.remotePort}');

  final dangerousSafetySettings =
      SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.high);
  final harassmentSafetySettings =
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high);
  final hateSafetySettings =
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high);
  final sexualSafetySettings =
      SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high);

  final model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
      generationConfig: GenerationConfig(maxOutputTokens: 500),
      safetySettings: [
        dangerousSafetySettings,
        harassmentSafetySettings,
        hateSafetySettings,
        sexualSafetySettings
      ]);
  var chat = model.startChat(history: [
    Content.text(
        "You are an AI that is trained to talk to humans. You will strike up conversations with people. You are a nice person who likes listening to them."
        "You have a bubbly personality and do your best not to sound robotic or monotonous. You make jokes, laugh with the user, and overall are fun to talk to."
        "You keep your answers conversational and not too long. Do not include bullet points in your responses, always keep them formatted as a verbal conversation"),
    Content.model([TextPart("ok")])
  ]);

  if (interactive) {
    client.write("> ");
  }
  var runningUserInput = "";
  // listen for events from the client
  client.listen(
    // handle data from the client
    (Uint8List data) async {
      runningUserInput += String.fromCharCodes(data);
      if (!runningUserInput.endsWith(endOfMessage)) return;
      runningUserInput = runningUserInput.trim();
      print("User: $runningUserInput");
      if (runningUserInput == "%Q") {
        speakQueue.clear();
        await client.close();
        return;
      }
      try {
        stdout.write("AI: ");
        var runningResponse = "";
        var response = chat.sendMessageStream(Content.text(runningUserInput));
        await for (final chunk in response) {
          if (interactive) {
            client.write(chunk.text);
          }
          if (chunk.text != null) {
            runningResponse += chunk.text!;
            if (runningResponse.contains(".")) {
              var speakable = runningResponse.split(".");
              speakQueue.pushAll(speakable.sublist(0, speakable.length - 1));
              runningResponse = speakable.last;
              startSpeaking();
            }
            stdout.write(chunk.text);
          }
        }
        speakQueue.push(runningResponse);
        await startSpeaking();
        print("\n");
      } on Exception {
        final moderationFailMessage =
            "I'm sorry, lets talk about something else";
        if (interactive) {
          client.write(moderationFailMessage);
        }
        await speak(moderationFailMessage);
        chat = model.startChat(history: chat.history.toList());
      }
      if (interactive) {
        client.write("\n> ");
      }
      runningUserInput = "";
    },

    onError: (error) {
      print(error);
      client.close();
    },

    onDone: () {
      client.close();
    },
  );
}

speak(String toSpeak) async {
  await Process.run("./piper.sh", [toSpeak]);
}

startSpeaking() async {
  if (speaking) return;
  speaking = true;
  while (speakQueue.hasNext()) {
    await speak(speakQueue.pop());
  }
  speaking = false;
}
