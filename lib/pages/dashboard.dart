import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  String? _token;
  dynamic _lessonResult;

  final String apiBaseUrl = 'http://10.0.2.2:8080/api';
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    _token = await storage.read(key: 'jwt_token');
    setState(() {});
  }

  Future<void> _createLesson() async {
    if (_formKey.currentState!.validate() &&
        _token != null &&
        _token!.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('$apiBaseUrl/lessons'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
          body: jsonEncode({
            'title': 'New Lesson',
            'text_content': _textController.text,
            'language': 'vi',
          }),
        );

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
        print('Token used: $_token');
        final responseData = jsonDecode(response.body);
        if (response.statusCode == 201) {
          setState(() {
            _lessonResult = responseData;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(responseData['message'])));
          _textController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to create lesson: ${responseData['error'] ?? 'Unknown error'}',
              ),
            ),
          );
        }
      } catch (error) {
        print('Error: $error');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $error')));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No valid token available')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AutoLecture',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Create a lesson'),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _textController,
                      decoration: InputDecoration(
                        labelText: 'Enter lesson content',
                        border: OutlineInputBorder(),
                        hintText: 'Type your lesson text here...',
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _createLesson,
                      child: const Text('Create Lesson'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_lessonResult != null) ...[
                const Text(
                  'Lesson Created:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  _lessonResult['lesson']['text_content'] ??
                      'No content available',
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: 10),
                if (_lessonResult['video'] != null)
                  GestureDetector(
                    onTap: () async {
                      final Uri url = Uri.parse(
                        _lessonResult['video'].replaceAll(
                          'localhost',
                          '10.0.2.2',
                        ),
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not launch video'),
                          ),
                        );
                      }
                    },
                    child: Text(
                      _lessonResult['video'].replaceAll(
                        'localhost',
                        '10.0.2.2',
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                if (_lessonResult['slides'] != null &&
                    _lessonResult['slides'].isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _lessonResult['slides'].map<Widget>((slide) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Tapped Slide ${slide['order_index']}',
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'Slide ${slide['order_index']}: ${slide['image_url']}',
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _textController.text = '';
            _lessonResult = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ready to create new lesson')),
          );
        },
        tooltip: 'New Lesson',
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
