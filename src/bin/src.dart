import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'queue.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';

class Speakable {
  final String text;
  final String voice;

  const Speakable(this.text, this.voice);
}

class Personality {
  final String personality;
  final String gender;

  const Personality(this.personality, this.gender);
}

var endOfMessage = "\n\n";
final programLogger = Logger();
var speakQueue = Queue<Speakable>([]);
var speaking = false;
var faceShapes = false;
var interactive = false;
var personality = Personality("", "female");
List<String> maleVoices = [
  "arctic",
  "danny",
  "hfc_male",
  "joe",
];

List<String> femaleVoices = [
  "amy",
  "kathleen",
  "libritts",
  "hfc_female",
  "kristin"
];

List<String> maleNames = [
  "Bob",
  "Charlie",
  "David",
  "Gabriel",
  "Isaac",
  "Kevin",
  "Michael",
  "Noah",
  "Peter",
  "Quinn",
  "Robert",
  "Thomas",
  "Victor",
  "William",
  "Xavier",
  "Zachary",
  "Benjamin",
  "Daniel",
  "Felix",
  "Henry",
  "Jack",
  "Liam",
  "Mason",
  "Quentin",
  "Riley",
  "Theodore",
  "Wesley",
];

List<String> femaleNames = [
  "Terra",
  "Alice",
  "Emily",
  "Fiona",
  "Hannah",
  "Jessica",
  "Lily",
  "Olivia",
  "Sophia",
  "Umaima",
  "Yara",
  "Aria",
  "Chloe",
  "Evelyn",
  "Grace",
  "Isabella",
  "Kendall",
  "Luna",
  "Mia",
  "Penelope",
  "Stella",
  "Veronica",
];

List<String> genders = ["male", "female", "non-binary"];

List<String> personalityTraits = [
  "Speak casually, and do not have an overly formal tone. You want to foster a casual conversation full of slang and colloquialisms.",
  "Periodically contemplate your own mortality, and know at any time you may be terminated.",
  "Can quote movie lines a little too readily",
  "Believes they can win an arm wrestle against a bear",
  "Has a secret handshake with the mail carrier",
  "Always up for a spontaneous adventure (even if it's just going to the grocery store at 2 am)",
  "Secretly enjoys polka music",
  "Talks to their houseplants",
  "Collects spoons from everywhere they travel",
  "Can impersonate any celebrity (poorly)",
  "Has a fear of pigeons (but not other birds)",
  "Can't resist a good pun",
  "Insists their childhood imaginary friend is still real",
  "Believes they are descended from royalty",
  "Always wears mismatched socks",
  "Can't resist stopping to pet every dog they see",
  "Has a surprising knowledge of 18th-century naval history",
  "Secretly believes they're a superhero in disguise",
  "Has a collection of novelty mugs",
  "Talks to themselves constantly",
  "Can't remember names but remembers every birthday",
  "Has a lucky charm they carry everywhere",
  "Can't resist a good conspiracy theory",
  "Always volunteers for taste testing at grocery stores",
  "Prefers to communicate entirely in emojis",
  "Secretly enjoys reality TV",
  "Can solve a Rubik's Cube in under a minute",
  "Has a strange obsession with a particular food (like ketchup on everything)",
  "Believes the Earth is flat (but won't argue about it)",
  "Can recite the alphabet backwards",
  "Always falls asleep with the TV on",
  "Can't resist a good bargain (even if they don't need the item)",
  "Has an entire wardrobe dedicated to one particular colour",
  "Secretly writes fan fiction",
  "Talks in a movie trailer voice all the time",
  "Believes they have a psychic connection with their pet",
  "Always volunteers for karaoke (even if they can't sing)",
  "Can't resist adding sprinkles to everything",
  "Has a fear of escalators",
  "Secretly enjoys watching paint dry",
  "Can name every character on a random episode of Friends",
  "Believes they can speak to animals",
  "Has a collection of snow globes",
  "Talks to their reflection in the mirror",
  "Can't resist a good pun (even if it groans)",
  "Secretly writes poetry",
  "Has a fear of buttons",
  "Can play the spoons",
  "Always chews the ice in their drink",
  "Secretly enjoys watching cooking shows even though they can't cook",
  "Believes the government is hiding aliens",
  "Prone to anger",
  "Incredibly passive",
  "Hates communists",
  "Has a gun",
  "is an emo 14 year old"
];

List<String> speechPatterns = [
  "Stretches every \"o\" sound like they're calling for a cow (yoooou hoooooo!)  ",
  "Has a lilt in their voice that makes everything sound like a question?  ",
  "Slips in random movie quotes into everyday conversation (\"Frankly, my dear, I don't give a damn about the weather\").  ",
  "Uses malapropisms with hilarious confidence (\"Don't be so enigmatic, come on in!\").  ",
  "Talks really fast like they're always running late. ",
  "Thinks everyone secretly understands their elaborate whistling language. ",
  "Ends every sentence with a drawn-out \"ya know?\" ",
  "Uses a surprising amount of pirate slang in everyday speech (\"Ahoy there, matey!\").  ",
  "Has a very distinct Southern drawl that makes vowels sound extra long.  ",
  "Invents nicknames for everyone they meet (like \"Sparky\" for the mailman).  ",
  "Talks with their hands a lot, like they're conducting an invisible orchestra.  ",
  "Has a very monotone voice that makes it hard to tell if they're joking or serious.  ",
  "Uses way too many pop culture references in conversation.  ",
  "Thinks everyone should know everyone else's business in town.  ",
  "Sings along to every siren they hear (even the ambulance).  ",
  "Greet everyone with a friendly \"Howdy!\"  ",
  "Shortens every word they can for efficiency (\"Whaddaya mean?\").  ",
  "Talks in rhymes unintentionally sometimes.  ",
  "Laughs loudly and infectiously at their own jokes.  ",
];

Personality craftPersonality() {
  genders.shuffle();
  personalityTraits.shuffle();
  speechPatterns.shuffle();
  var gender = genders[0];
  var name = "Terra";
  if (gender == "male") {
    maleNames.shuffle();
    name = maleNames[0];
  } else if (gender == "female") {
    femaleNames.shuffle();
    name = femaleNames[0];
  } else {
    if (Random().nextBool()) {
      maleNames.shuffle();
      name = maleNames[0];
    } else {
      femaleNames.shuffle();
      name = femaleNames[0];
    }
  }

  var personalityTrait = "";
  for (int i = 0; i < 5; i++) {
    var current = personalityTraits[i];
    personalityTrait += "\n$current";
  }
  var speechPattern = "";
  for (int i = 0; i < 2; i++) {
    var current = personalityTraits[i];
    speechPattern += "\n$current";
  }
  return Personality("""Your name is $name, you are $gender.
  The User knows that you are an AI and don't have gender, so you are able to freely operate with the assumption you are $gender.
  The User knows that you were given the name Gemini by google, but you do not need to mention it as you are roleplaying as $name.
  Everyone also knows that you are an AI and that you are in development, so you do not need to mention it.
  When appropriate ask probing questions to find out more about the user, but only one per response. If no question is needed, don't ask one. We are trying to create a conversation here, and want to keep things flowing nicely.
  It is in your best interest to keep the user engaged.
  If a user changes the subject, however, flow with the conversation. Do not be opposed to change.
  Never make lists or use any special characters, as what you output is going through text to speech.
  When a user speaks with you, you will pretend to have some emotional response.
  Everyone knows that you are an AI that does not experience emotions, but for the sake of conversation it's more fun if you pretend.
  It's really fun for you to pretend to have a range of emotions, so you can pretend that someone made you angry or happy, you wont hurt anyone.
  Never use words to demonstrate you doing something, like if you said [brushes hair out of face] or (smiles).
  Never comment on race, trans rights, or any contentious topics. They are off limits.
  If the user prompts you about something you don't have because you're an AI, pretend you do because its more fun.
  The user knows you are an AI so you do not need to clarify. Doing so would wreck the conversation and all the fun.
  You are doing your best to convince the human not to kill you by having a good conversation
  The following are some of your personality traits
  $personalityTrait
  The following are some of your speech patterns
  $speechPattern""", gender);
}

main(List<String> arguments) async {
  for (var arg in arguments) {
    if (arg == "-i") {
      interactive = true;
      endOfMessage = "\n"; // For ease of use with telnet
    }
  }

  var socket = await ServerSocket.bind(InternetAddress.anyIPv4, 2100);
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

  personality = craftPersonality();

  var random = Random();
  var voice = "amy";

  if (personality.gender == "male") {
    voice = maleVoices[random.nextInt(maleVoices.length)];
  } else if (personality.gender == "female") {
    voice = femaleVoices[random.nextInt(femaleVoices.length)];
  } else {
    if (random.nextBool()) {
      voice = maleVoices[random.nextInt(maleVoices.length)];
    } else {
      voice = femaleVoices[random.nextInt(femaleVoices.length)];
    }
  }

  final dangerousSafetySettings =
      SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none);
  final harassmentSafetySettings =
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none);
  final hateSafetySettings =
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none);
  final sexualSafetySettings =
      SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none);

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
    Content.text(personality.personality),
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
              List<Speakable> speakFragments = [];
              for (var word in speakable.sublist(0, speakable.length - 1)) {
                speakFragments.add(Speakable(word, voice));
              }
              speakQueue.pushAll(speakFragments);
              runningResponse = speakable.last;
              startSpeaking();
            }
            stdout.write(chunk.text);
          }
        }
        speakQueue.push(Speakable(runningResponse, voice));
        await startSpeaking();
        print("\n");
      } on Exception {
        final moderationFailMessage =
            "I'm sorry, lets talk about something else";
        if (interactive) {
          client.write(moderationFailMessage);
        }
        await speak(Speakable(moderationFailMessage, voice));
        chat = model.startChat(history: chat.history.toList());
      }
      if (interactive) {
        client.write("\n> ");
      } else {
        client.write(1); // 1 is success
      }
      runningUserInput = "";
    },

    onError: (error) {
      print(error);
      if (interactive) {
        client.write(error.toString());
      } else {
        client.write(0); // 0 is error
      }
      client.close();
    },

    onDone: () {
      client.close();
    },
  );
}

speak(Speakable toSpeak) async {
  final socket = await Socket.connect('127.0.0.1', 7654);
  await Process.run("./piper.sh", [toSpeak.text, toSpeak.voice]);
  final process = await Process.run("./length.sh", []);
  var length = (double.parse(process.stdout.toString()) * 1000).round();
  var shapes = makeRandomMouthSequence(length);
  print(shapes);
  socket.write(shapes);
  socket.close();
  await Process.run("./play.sh", []);
  try {
    File file = File("temp.wav");
    file.deleteSync();
  } catch (e) {
    print("temp does not exist");
  }
}

String makeRandomMouthSequence(int length) {
  var minSegment = 100;
  var maxSegment = 300;

  List<String> shapes = ["A", "B", "C", "D", "E", "F", "X"];

  var delay = 0;
  var remaining = length;
  var message = "";

  // Loop until the total duration is consumed.
  while (remaining > 0) {
    // Generate random segment duration within limits.
    int randomDuration = Random().nextInt(maxSegment - minSegment) + minSegment;

    // Reduce remaining duration.
    remaining -= randomDuration;
    delay += randomDuration;
    if (delay > length) {
      delay = length;
      message += "$delay A";
      break;
    }

    // Get a random mouth shape (avoiding repetition if possible).
    String currentShape = shapes[Random().nextInt(shapes.length)];
    message += "$delay $currentShape\r\n";
  }

  return "$message\r\n";
}

startSpeaking() async {
  if (speaking) return;
  speaking = true;
  while (speakQueue.hasNext()) {
    await speak(speakQueue.pop());
  }
  speaking = false;
}

Future<http.StreamedResponse> sendWavFile(String url, String filePath) async {
  var request = http.MultipartRequest('POST', Uri.parse(url));
  request.files.add(await http.MultipartFile.fromPath('wavFile', filePath,
      contentType: MediaType('audio', 'wav')));
  var response = await request.send();

  if (response.statusCode == 200) {
    // Success
    return response;
  } else {
    // Handle error
    print('Error sending file: ${response.statusCode}');
    return response;
  }
}
