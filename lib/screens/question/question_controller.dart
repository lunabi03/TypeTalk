import 'package:get/get.dart';
import 'package:typetalk/routes/app_routes.dart';

class QuestionController extends GetxController {
  final RxInt currentIndex = 0.obs;

  final List<String> questions = const [
    '나는 새로운 사람들을\n만나는 것을 즐긴다',
    '계획을 세우고 그에 맞춰\n행동하는 편이다',
    '중요한 결정을 할 때\n직관을 믿는 편이다',
    '여유 시간에는 혼자만의 시간을\n보내는 것을 선호한다',
    '즉흥적인 아이디어가 떠오르면\n바로 실행해본다',
    '갈등 상황에서 상대를\n배려하려 노력한다',
    '세부 사항보다 큰 그림을\n먼저 본다',
    '약속 시간에 늦지 않도록\n미리 준비한다',
    '감정보다 사실과 논리를\n우선시한다',
    '관심 있는 주제는\n깊게 파고드는 편이다',
  ];

  // 선택한 답변 인덱스 (-1: 미선택)
  late final RxList<int> selectedIndexByQuestion;

  List<String> get options => const [
        '매우 그렇다',
        '그렇다',
        '보통이다',
        '아니다',
        '전혀 아니다',
      ];

  int get total => questions.length;

  @override
  void onInit() {
    super.onInit();
    selectedIndexByQuestion = List<int>.filled(total, -1).obs;
  }

  void selectAnswer(int optionIndex) {
    selectedIndexByQuestion[currentIndex.value] = optionIndex;
  }

  void goNext() {
    if (currentIndex.value < total - 1) {
      currentIndex.value += 1;
    } else {
      final String type = _computeMbtiType();
      Get.toNamed(
        AppRoutes.result,
        arguments: {
          'type': type,
          'title': _typeToTitle[type] ?? type,
        },
      );
    }
  }

  void goBack() {
    if (currentIndex.value > 0) {
      currentIndex.value -= 1;
    } else {
      Get.back();
    }
  }

  // ----- MBTI 산출 로직 -----
  // 차원 인덱스: 0: E/I, 1: S/N, 2: T/F, 3: J/P
  static const List<List<int>> _questionMapping = [
    // [dimensionIndex, direction], direction: +1이면 '매우 그렇다'가 앞 글자(E/S/T/J)에 가산, -1이면 뒷 글자(I/N/F/P)에 가산
    [0, 1], // 1) 새로운 사람들: E
    [3, 1], // 2) 계획/준수: J
    [1, -1], // 3) 직관 신뢰: N
    [0, -1], // 4) 혼자 선호: I
    [3, -1], // 5) 즉흥 실행: P
    [2, -1], // 6) 배려: F
    [1, -1], // 7) 큰 그림: N
    [3, 1], // 8) 시간 준수: J
    [2, 1], // 9) 사실/논리: T
    [0, -1], // 10) 깊게 파고듦: I(성향 가정)
  ];

  String _computeMbtiType() {
    final List<int> scores = List<int>.filled(4, 0);
    for (int i = 0; i < total; i++) {
      final int selected = selectedIndexByQuestion[i];
      if (selected == -1) continue; // 미응답은 0점
      final int agreeScore = 2 - selected; // 0..4 -> +2..-2
      final int dim = _questionMapping[i][0];
      final int dir = _questionMapping[i][1];
      scores[dim] += agreeScore * dir;
    }

    final List<String> first = ['E', 'S', 'T', 'J'];
    final List<String> second = ['I', 'N', 'F', 'P'];

    final StringBuffer buf = StringBuffer();
    for (int d = 0; d < 4; d++) {
      if (scores[d] >= 0) {
        buf.write(first[d]);
      } else {
        buf.write(second[d]);
      }
    }
    return buf.toString();
  }

  static const Map<String, String> _typeToTitle = {
    'ISTJ': '청렴결백한 ISTJ',
    'ISFJ': '용감한 수호자 ISFJ',
    'INFJ': '선의의 옹호자 INFJ',
    'INTJ': '용의주도한 전략가 INTJ',
    'ISTP': '만능 재주꾼 ISTP',
    'ISFP': '호기심 많은 예술가 ISFP',
    'INFP': '열정적인 중재자 INFP',
    'INTP': '논리적인 사색가 INTP',
    'ESTP': '모험을 즐기는 사업가 ESTP',
    'ESFP': '자유로운 영혼의 연예인 ESFP',
    'ENFP': '재기 발랄한 ENFP',
    'ENTP': '뜨거운 논쟁을 즐기는 변론가 ENTP',
    'ESTJ': '엄격한 관리자 ESTJ',
    'ESFJ': '사교적인 외교관 ESFJ',
    'ENFJ': '정의로운 사회운동가 ENFJ',
    'ENTJ': '대담한 통솔자 ENTJ',
  };
}

