import 'dart:io';
import 'dart:math';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:chatgpt/screens/conversations_screen.dart';
import 'package:chatgpt/services/database_helper.dart';
import 'package:dart_openai/dart_openai.dart' as oa;
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../model/chat_message.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage(
      {Key? key, required this.title, required this.conversationId})
      : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final String conversationId;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String generateRandomString(int len) {
    var r = Random();
    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(len, (index) => _chars[r.nextInt(_chars.length)])
        .join();
  }

  TextEditingController controller = TextEditingController();
  String results = "results";
  //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
  late OpenAI openAI;
  late String conversationId;

  List<ChatMessage> messages = <ChatMessage>[];

  ChatUser userMe = ChatUser(
    id: '1',
    firstName: 'Matteo',
    lastName: 'Menghetti',
  );

  ChatUser openAIUser = ChatUser(
    id: '2',
    firstName: 'ChatGPT',
    lastName: 'AI',
  );

  late FlutterTts flutterTts;
  bool isTTS = false;
  final SpeechToText _speechToText = SpeechToText();

  @override
  void initState() {
    super.initState();
    conversationId = widget.conversationId == ''
        ? generateRandomString(6)
        : widget.conversationId;
    openAI = OpenAI.instance.build(
        token: "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",
        baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 25)),
        enableLog: true);
    flutterTts = FlutterTts();
    oa.OpenAI.apiKey = "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";
    _initSpeech();
    readMsgFromDB();
  }

  Future<void> readMsgFromDB() async {
    List<ChatMsg>? chats =
        await DatabaseHelper.getMessagesConversation(conversationId);
    if (chats!.isNotEmpty) {
      chats.sort((a, b) => b.id.compareTo(a.id));
      List<ChatMessage> listMessages = chats
          .map((e) => ChatMessage(
              user: e.user == '1' ? userMe : openAIUser,
              createdAt: DateTime.parse(e.createdAt),
              text: e.message))
          .toList();

      setState(() {
        messages = listMessages;
      });
    }
  }

  bool _speechEnabled = false;

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      ChatMessage msg = ChatMessage(
          user: userMe,
          createdAt: DateTime.now(),
          text: result.recognizedWords);
      messages.insert(0, msg);
      setState(() {
        messages;
      });
      controller.text = result.recognizedWords;
      chatComplete();
    }
  }

  Future<void> completeWithSSE() async {
    final request = CompleteText(
        prompt: controller.text, maxTokens: 200, model: TextDavinci3Model());
    CompleteResponse? response = await openAI.onCompletion(request: request);
    if (response != null) {
      print(response.choices.last.text);
      results = response.choices.last.text;
      setState(() {
        results;
      });
    }
  }

  void chatComplete() async {
    final request = ChatCompleteText(
        messages: [Messages(role: Role.user, content: controller.text)],
        maxToken: 200,
        model: GptTurbo0301ChatModel());
    controller.text = "";
    final response = await openAI.onChatCompletion(request: request);
    for (var element in response!.choices) {
      results = element.message!.content;
      ChatMessage msg = ChatMessage(
          user: openAIUser,
          createdAt: DateTime.now(),
          text: element.message!.content);
      messages.insert(0, msg);
      if (isTTS) {
        flutterTts.speak(results);
      }

      setState(() {
        results;
      });
    }
  }

  void _generateImage() async {
    var prompt = controller.text;
    controller.text = "";
    final request = GenerateImage(prompt, 1,
        size: ImageSize.size256, responseFormat: Format.url);
    GenImgResponse? response = await openAI.generateImage(request);
    print("img url :${response?.data?.last?.url}");
    ChatMessage msg = ChatMessage(
      user: openAIUser,
      createdAt: DateTime.now(),
      medias: [
        ChatMedia(
            url: response!.data!.last!.url!,
            fileName: "image",
            type: MediaType.image)
      ],
    );
    messages.insert(0, msg);
    setState(() {
      messages;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat GPT"),
        actions: [
          InkWell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                  isTTS ? Icons.record_voice_over : Icons.voice_over_off_sharp),
            ),
            onTap: () {
              if (isTTS) {
                isTTS = false;
                flutterTts.stop();
              } else {
                isTTS = true;
              }
            },
          ),
          InkWell(
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.audiotrack),
            ),
            onTap: () {
              pickAudioFiles();
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "en-US",
                child: Text("English"),
              ),
              const PopupMenuItem(
                value: "fr-FR",
                child: Text("French"),
              ),
              const PopupMenuItem(
                value: "it-IT",
                child: Text("Italian"),
              ),
            ],
            icon: const Icon(Icons.language),
            onSelected: (String newValue) {
              flutterTts.setLanguage(newValue);
            },
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) =>
                      const ConversationsScreen()),
            );
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
                child: DashChat(
              messages: messages,
              currentUser: userMe,
              onSend: (m) {},
              readOnly: true,
            )),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                      child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                            hintText: "Type here...", border: InputBorder.none),
                      ),
                    ),
                  )),
                  ElevatedButton(
                    onPressed: () {
                      _startListening();
                    },
                    style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(20)),
                    child: const Icon(Icons.mic),
                  ),
                  Container(
                    width: 5,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      ChatMessage msg = ChatMessage(
                          user: userMe,
                          createdAt: DateTime.now(),
                          text: controller.text);
                      messages.insert(0, msg);

                      setState(() {
                        messages;
                      });
                      final chatMsg = ChatMsg(
                        id: messages.length,
                        user: userMe.id,
                        createdAt: DateTime.now().toString(),
                        message: controller.text,
                        conversationId: conversationId,
                      );
                      await DatabaseHelper.addNote(chatMsg);
                      if (controller.text
                          .toLowerCase()
                          .startsWith("generate image")) {
                        _generateImage();
                      } else {
                        chatComplete();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(20)),
                    child: const Icon(Icons.send),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> pickAudioFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
    );
    if (result != null) {
      print(result.files.first.path);
      print(result.files.first.extension);
      ChatMessage msg = ChatMessage(
          user: userMe,
          createdAt: DateTime.now(),
          text: result.files.first.name!);
      messages.insert(0, msg);
      setState(() {
        messages;
      });
      oa.OpenAIAudioModel transcription =
          await oa.OpenAI.instance.audio.createTranscription(
        file: File(result.files.first.path! + ".mp3"),
        model: "whisper-1",
        responseFormat: oa.OpenAIAudioResponseFormat.json,
      );
      print(transcription.text);
      ChatMessage msg2 = ChatMessage(
          user: openAIUser,
          createdAt: DateTime.now(),
          text: transcription.text);
      messages.insert(0, msg2);
      setState(() {
        messages;
      });
    }
  }
}
