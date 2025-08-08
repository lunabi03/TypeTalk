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
      Get.toNamed(AppRoutes.result);
    }
  }

  void goBack() {
    if (currentIndex.value > 0) {
      currentIndex.value -= 1;
    } else {
      Get.back();
    }
  }
}

