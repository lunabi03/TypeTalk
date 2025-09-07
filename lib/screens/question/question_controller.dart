import 'package:get/get.dart';
import 'package:typetalk/routes/app_routes.dart';

class QuestionController extends GetxController {
  final RxInt currentIndex = 0.obs;

  final List<String> questions = const [
    // E/I 차원 (외향성/내향성) - 8개 질문
    '나는 새로운 사람들을\n만나는 것을 즐긴다',
    '여러 사람과 함께 있을 때\n에너지를 얻는다',
    '파티나 모임에서\n적극적으로 참여한다',
    '혼자만의 시간을 보내는 것을\n선호한다',
    '조용한 환경에서\n집중력이 더 좋다',
    '모르는 사람과도 쉽게\n대화를 시작한다',
    '사람들과 어울리는 것보다\n혼자 있는 시간이 더 소중하다',
    '그룹 활동에서 리더 역할을\n맡는 것을 좋아한다',
    
    // S/N 차원 (감각/직관) - 8개 질문
    '중요한 결정을 할 때\n직관을 믿는 편이다',
    '세부 사항보다 큰 그림을\n먼저 본다',
    '구체적인 사실과 데이터를\n중요하게 생각한다',
    '새로운 아이디어나 가능성을\n상상하는 것을 좋아한다',
    '실용적이고 현실적인\n해결책을 선호한다',
    '미래의 가능성에 대해\n생각하는 것을 즐긴다',
    '단계별로 차근차근\n진행하는 것을 좋아한다',
    '추상적인 개념이나 이론에\n흥미를 느낀다',
    
    // T/F 차원 (사고/감정) - 7개 질문
    '갈등 상황에서 상대를\n배려하려 노력한다',
    '감정보다 사실과 논리를\n우선시한다',
    '공정성과 객관성을\n중요하게 생각한다',
    '다른 사람의 감정을\n이해하려고 노력한다',
    '논리적 분석을 통해\n결정을 내린다',
    '사람들의 기분을\n배려하는 것이 중요하다',
    '효율성과 결과를\n최우선으로 생각한다',
    
    // J/P 차원 (판단/인식) - 7개 질문
    '계획을 세우고 그에 맞춰\n행동하는 편이다',
    '즉흥적인 아이디어가 떠오르면\n바로 실행해본다',
    '약속 시간에 늦지 않도록\n미리 준비한다',
    '유연하고 개방적인\n접근을 선호한다',
    '일정을 미리 정해두고\n따르는 것을 좋아한다',
    '새로운 기회가 생기면\n즉시 반응한다',
    '체계적이고 정리된\n환경을 선호한다',
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
    // E/I 차원 (외향성/내향성) - 8개 질문
    [0, 1], // 1) 새로운 사람들: E
    [0, 1], // 2) 여러 사람과 함께 에너지: E
    [0, 1], // 3) 파티/모임 적극 참여: E
    [0, -1], // 4) 혼자 시간 선호: I
    [0, -1], // 5) 조용한 환경 집중: I
    [0, 1], // 6) 모르는 사람과 대화: E
    [0, -1], // 7) 혼자 시간이 소중: I
    [0, 1], // 8) 리더 역할 선호: E
    
    // S/N 차원 (감각/직관) - 8개 질문
    [1, -1], // 9) 직관 신뢰: N
    [1, -1], // 10) 큰 그림: N
    [1, 1], // 11) 구체적 사실/데이터: S
    [1, -1], // 12) 새로운 아이디어 상상: N
    [1, 1], // 13) 실용적/현실적 해결책: S
    [1, -1], // 14) 미래 가능성 생각: N
    [1, 1], // 15) 단계별 차근차근: S
    [1, -1], // 16) 추상적 개념/이론: N
    
    // T/F 차원 (사고/감정) - 7개 질문
    [2, -1], // 17) 상대 배려: F
    [2, 1], // 18) 사실/논리 우선: T
    [2, 1], // 19) 공정성/객관성: T
    [2, -1], // 20) 다른 사람 감정 이해: F
    [2, 1], // 21) 논리적 분석: T
    [2, -1], // 22) 사람들 기분 배려: F
    [2, 1], // 23) 효율성/결과 최우선: T
    
    // J/P 차원 (판단/인식) - 7개 질문
    [3, 1], // 24) 계획 세우고 행동: J
    [3, -1], // 25) 즉흥적 아이디어 실행: P
    [3, 1], // 26) 시간 준수: J
    [3, -1], // 27) 유연하고 개방적: P
    [3, 1], // 28) 일정 미리 정하기: J
    [3, -1], // 29) 새로운 기회 즉시 반응: P
    [3, 1], // 30) 체계적/정리된 환경: J
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

