import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/services/gemini_service.dart';
import '../../tasks/domain/task_cubit.dart';
import '../../tasks/data/models/task_model.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/custom_app_bar.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  List<String> _suggestions = [];
  final GeminiService _geminiService = GeminiService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadSuggestions();
    _messages.add({
      'role': 'assistant',
      'content': 'Xin chào! Mình là trợ lý AI. Bạn có thể nói hoặc nhập câu lệnh như:\n- Làm bài tập toán 25 phút 5 phút nghỉ\n- Ngày mai đi chợ 6 sáng\n- Họp nhóm lúc 3h',
    });
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );
    setState(() {});
  }

  void _loadSuggestions() async {
    final suggestions = await _geminiService.getSmartSuggestions("đang học toán");
    setState(() {
      _suggestions = suggestions;
    });
  }

  Future<void> _handleMessage(String userMessage) async {
    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _isProcessing = true;
    });

    final commandResult = await _geminiService.parseUserCommand(userMessage);
    String response;

    if (commandResult.containsKey('error')) {
      response = commandResult['error'] as String;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $response'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      final taskCubit = context.read<TaskCubit>();
      if (commandResult['type'] == 'task') {
        final task = Task(
          title: commandResult['title'],
          estimatedPomodoros: (commandResult['duration'] / 25).ceil(),
          dueDate: commandResult['due_date'] != null
              ? DateTime.parse(commandResult['due_date'])
              : null,
          priority: commandResult['priority'],
        );
        taskCubit.addTask(task);
        response = 'Đã thêm task: ${task.title}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response),
            backgroundColor: Colors.green,
          ),
        );
      } else if (commandResult['type'] == 'schedule') {
        final task = Task(
          title: commandResult['title'],
          dueDate: DateTime.parse(commandResult['due_date']),
          priority: commandResult['priority'] ?? 'Medium',
        );
        taskCubit.addTask(task);

        final reminderTime = DateTime.parse(commandResult['due_date'])
            .subtract(Duration(minutes: commandResult['reminder_before']));
        final notificationService = NotificationService();
        await notificationService.scheduleNotification(
          title: 'Nhắc nhở: ${task.title}',
          body: 'Sắp đến giờ ${task.title} vào lúc ${commandResult['due_date']}',
          scheduledTime: reminderTime,
        );
        response = 'Đã lên lịch: ${task.title} vào ${task.dueDate}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        response = 'Không hiểu câu lệnh. Vui lòng thử lại!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _messages.add({'role': 'assistant', 'content': response});
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      message['content']!,
                      style: TextStyle(color: isUser ? Colors.black : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          if (_suggestions.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: ActionChip(
                        label: const Text('Làm mới gợi ý'),
                        onPressed: () {
                          setState(() {
                            _suggestions = [];
                          });
                          _loadSuggestions();
                        },
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ActionChip(
                      label: Text(_suggestions[index - 1]),
                      onPressed: () async {
                        await _handleMessage(_suggestions[index - 1]);
                      },
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Nhập câu lệnh...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (_controller.text.isNotEmpty) {
                      final message = _controller.text;
                      _controller.clear();
                      await _handleMessage(message);
                    }
                  },
                ),
                IconButton(
                  icon: Icon(_speechEnabled ? Icons.mic : Icons.mic_off),
                  onPressed: () {
                    if (_speechEnabled) {
                      _speechToText.listen(
                        onResult: (result) async {
                          if (result.finalResult) {
                            await _handleMessage(result.recognizedWords);
                          }
                        },
                        localeId: 'vi_VN',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}