import 'package:flutter/material.dart';
import 'package:ui_qna_module/widgets/vertical_img_text_button.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class QnaScreen extends StatefulWidget {
  const QnaScreen({super.key});

  @override
  State<QnaScreen> createState() => _QnaScreenState();
}

class _QnaScreenState extends State<QnaScreen> {
  Map<String, dynamic>? _data;
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {}; // <질문 번호, 선택한 답변 번호>

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
            "10개 중 ${_currentQuestionIndex + 1}번째 질문",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 25),
        Stack(
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
                  fontSize: 30,
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
        Container(
          padding: const EdgeInsets.all(20),
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
                      imagePath: _currentQuestionIndex <= 2
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
                if (_currentQuestionIndex < 9)
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
                    onPressed: () {
                      var sortedAnswers = Map.fromEntries(
                      _selectedAnswers.entries.toList()
                          ..sort((e1, e2) => e1.key.compareTo(e2.key)),
                      );
                      
                      debugPrint("최종 선택된 답변 리스트(질문 인덱스 : 답변 인덱스): $sortedAnswers");

                      if (_data != null) {
                        for (var entry in sortedAnswers.entries) {
                          var questionIndex = entry.key;
                          var answerIndex = entry.value;
                          var question = _data!['questions'][questionIndex];
                          var answer = question['answers'][answerIndex];

                          debugPrint("질문: ${question['question']}, 선택된 답변: ${answer['text']}");
                        }
                      }
                    },
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
