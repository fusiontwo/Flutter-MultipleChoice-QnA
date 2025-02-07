import 'package:flutter/material.dart';
import 'package:ui_qna_module/widgets/vertical_img_text_button.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class QnaScreen extends StatefulWidget {
  const QnaScreen({super.key});

  @override
  State<QnaScreen> createState() => _QnaScreenState();
}

class _QnaScreenState extends State<QnaScreen> {
  Map<String, dynamic>? _data;
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {}; 
  final Map<int, String> _subjectiveAnswers = {};

  // Real API Gateway URL
  final String apiGatewayUrl = 'https://{apigateway-api-id}.execute-api.ap-northeast-2.amazonaws.com/default/gpt-api-lambda';

  late BuildContext dialogContext;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final String response = await rootBundle.loadString('assets/qna_content.json');
    final data = json.decode(response);
    setState(() {
      _data = data;
    });
  }

  Widget _buildQuestionAndAnswers() {
    if (_data == null) {
      return Center(child: CircularProgressIndicator());
    }

    var question = _data!['questions'][_currentQuestionIndex];
    List<bool> _pressedAnswers = List.generate(
      question['answers'].length,
      (index) => _selectedAnswers[_currentQuestionIndex] == index,
    );

    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "18개 중 ${_currentQuestionIndex + 1}번째 질문",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 25),
        Padding(
          padding: const EdgeInsets.only(left: 35, right: 35),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyan),
                ),
                child: Text(
                  question['question'],
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Positioned(
                top: -20,
                left: -10,
                child: Image.asset(
                  "assets/flower_img/pink_flower.png",
                  width: 50,
                  height: 50,
                ),
              ),
              Positioned(
                top: -20,
                right: -10,
                child: Image.asset(
                  "assets/flower_img/top_right_leaf.png",
                  width: 50,
                  height: 50,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          height: 370,
          child: GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.2,
            ),
            itemCount: question['answers'].length,
            itemBuilder: (context, index) {
              var answer = question['answers'][index];
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: verticalImageTextButton(
                      imagePath: _currentQuestionIndex <= 4
                        ? 'assets/qna_button_img/q${_currentQuestionIndex + 1}${answer['id'].toLowerCase()}.png'
                        : 'assets/qna_button_img/temporary_img.png',
                      buttonText: answer['text'],
                      onPressed: () {
                        setState(() {
                          _selectedAnswers[_currentQuestionIndex] = index;
                          debugPrint("현재 선택된 답변 리스트(질문 인덱스 : 답변 인덱스): $_selectedAnswers");
                        });
                      },
                      isSelected: _pressedAnswers[index],
                    ),
                  ),
                  if (_pressedAnswers[index])
                    Positioned(
                      top: -10,
                      right: 0,
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 30,
                      ),
                    ),
                ],
              );
            },
          ),
        ),

        if (_subjectiveAnswers.containsKey(_currentQuestionIndex))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.yellow[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _subjectiveAnswers[_currentQuestionIndex] ?? '',
                style: TextStyle(fontSize: 14, color: Colors.black),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }

  void _changeQuestion(bool isNext) {
    setState(() {
      if (isNext) {
        if (_currentQuestionIndex < _data!['questions'].length - 1) {
          _currentQuestionIndex++;
        }
      } else {
        if (_currentQuestionIndex > 0) {
          _currentQuestionIndex--;
        }
      }
    });
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        dialogContext = context; 
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("AI 건강비서가 분석을 진행중입니다.\n잠시만 기다려주세요 🤗"),
            ],
          ),
        );
      },
    );
  }

  void _hideLoadingDialog() {
    Navigator.of(dialogContext).pop();
  }

  Future<void> _sendResponseToLambda() async {
    var sortedAnswers = Map.fromEntries(
      _selectedAnswers.entries.toList()
        ..sort((e1, e2) => e1.key.compareTo(e2.key)),
    );

    var choiceResult = [];

    if (_data != null) {
      for (var entry in sortedAnswers.entries) {
        var questionIndex = entry.key;
        var answerIndex = entry.value;
        var question = _data!['questions'][questionIndex];
        var answer = question['answers'][answerIndex];
        choiceResult.add({
          'question': question['question'],
          'answer': answer['text'],
        });
      }

      _subjectiveAnswers.forEach((questionIndex, subjectiveAnswer) {
        choiceResult.add({
          'question': _data!['questions'][questionIndex]['question'],
          'answer': subjectiveAnswer,
        });
      });
    }

    debugPrint("선택된 답변 목록: $choiceResult");

    _showLoadingDialog();

    var response = await http.post(
      Uri.parse(apiGatewayUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'choice_result': choiceResult,
      }),
    );

    _hideLoadingDialog();

    if (response.statusCode == 200) {
      print('Response from Lambda: ${response.body}');
      if (mounted) {
        _showResponseDialog(response.body);
      }
    } else {
      print('Failed to send data to Lambda. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }

  void _showResponseDialog(String responseBody) {
    Map<String, dynamic> jsonResponse = json.decode(responseBody);
    String analysisText = jsonResponse['analysis'];
    String result = analysisText.replaceAll(r'\n', '\n');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Image.asset(
                'assets/flower_img/pink_flower.png',
                width: 50,
                height: 50,
              ),
              SizedBox(width: 10),
              Text(
                'AI 분석 결과',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                result,
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                '확인',
                style: TextStyle(fontSize: 18, color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSubjectiveAnswerDialog() {
    TextEditingController controller = TextEditingController();
    controller.text = _subjectiveAnswers[_currentQuestionIndex] ?? '';  // 이전 값 불러오기

    showDialog(
      context: context,
      builder: (BuildContext context) {
        Future.delayed(Duration(milliseconds: 100), () {
          FocusScope.of(context).requestFocus(FocusNode());
        });

        return AlertDialog(
          title: Text("기타 답변 입력"),
          content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0), // 좌우 패딩 추가
            child: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: "답변을 입력해주세요."),
              maxLines: 3,
              autofocus: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _subjectiveAnswers[_currentQuestionIndex] = controller.text; // 답변 저장
                });
                Navigator.of(context).pop();
              },
              child: Text("저장"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("취소"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Qna 스크린 테스트"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildQuestionAndAnswers(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_currentQuestionIndex > 0)
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () => _changeQuestion(false),
                      ),
                      Text("이전", style: TextStyle(fontSize: 16, color: Colors.black)),
                    ],
                  )
                else
                  SizedBox(width: 70),

                const SizedBox(width: 40),
                if (_currentQuestionIndex < 17)
                  Row(
                    children: [
                      Text("다음", style: TextStyle(fontSize: 16, color: Colors.black)),
                      IconButton(
                        icon: Icon(Icons.arrow_forward),
                        onPressed: () => _changeQuestion(true),
                      ),
                    ],
                  )
                else
                  ElevatedButton(
                    onPressed: _sendResponseToLambda,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[200],
                      foregroundColor: Colors.black, 
                      textStyle: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16,
                      ),
                    ),
                    child: Text("응답 마치기"),
                  ),
              ],
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSubjectiveAnswerDialog,
        child: Icon(Icons.edit),
        backgroundColor: Colors.orange,
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "홈"),
          NavigationDestination(icon: Icon(Icons.search), label: "검색"),
          NavigationDestination(icon: Icon(Icons.person), label: "프로필"),
        ],
      ),
    );
  }
}
