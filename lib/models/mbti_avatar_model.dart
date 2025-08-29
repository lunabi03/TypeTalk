// MBTI 아바타 모델
class MBTIAvatar {
  final String mbtiType;
  final String name;
  final String avatarImage;
  final String personality;
  final String description;
  final List<String> interests;
  final String greetingMessage;
  final Map<String, String> conversationStyle;

  MBTIAvatar({
    required this.mbtiType,
    required this.name,
    required this.avatarImage,
    required this.personality,
    required this.description,
    required this.interests,
    required this.greetingMessage,
    required this.conversationStyle,
  });

  // Firestore 문서에서 생성
  factory MBTIAvatar.fromMap(Map<String, dynamic> map) {
    return MBTIAvatar(
      mbtiType: map['mbtiType'] ?? '',
      name: map['name'] ?? '',
      avatarImage: map['avatarImage'] ?? '',
      personality: map['personality'] ?? '',
      description: map['description'] ?? '',
      interests: List<String>.from(map['interests'] ?? []),
      greetingMessage: map['greetingMessage'] ?? '',
      conversationStyle: Map<String, String>.from(map['conversationStyle'] ?? {}),
    );
  }

  // Firestore 문서로 변환
  Map<String, dynamic> toMap() {
    return {
      'mbtiType': mbtiType,
      'name': name,
      'avatarImage': avatarImage,
      'personality': personality,
      'description': description,
      'interests': interests,
      'greetingMessage': greetingMessage,
      'conversationStyle': conversationStyle,
    };
  }

  // 복사본 생성
  MBTIAvatar copyWith({
    String? mbtiType,
    String? name,
    String? avatarImage,
    String? personality,
    String? description,
    List<String>? interests,
    String? greetingMessage,
    Map<String, String>? conversationStyle,
  }) {
    return MBTIAvatar(
      mbtiType: mbtiType ?? this.mbtiType,
      name: name ?? this.name,
      avatarImage: avatarImage ?? this.avatarImage,
      personality: personality ?? this.personality,
      description: description ?? this.description,
      interests: interests ?? this.interests,
      greetingMessage: greetingMessage ?? this.greetingMessage,
      conversationStyle: conversationStyle ?? this.conversationStyle,
    );
  }
}

// MBTI 아바타 데이터
class MBTIAvatarData {
  static final List<MBTIAvatar> avatars = [
    MBTIAvatar(
      mbtiType: 'ENFP',
      name: '루나',
      avatarImage: 'assets/images/avatars/enfp_avatar.png',
      personality: '열정적이고 창의적인 모험가',
      description: '새로운 가능성을 발견하고 영감을 전하는 따뜻한 영혼입니다. 사람들과의 깊은 연결을 추구하며, 창의적인 아이디어로 세상을 밝게 만듭니다.',
      interests: ['창작활동', '여행', '사람 만나기', '새로운 경험'],
      greetingMessage: '안녕하세요! 새로운 친구를 만나서 정말 기뻐요! 🎉 오늘은 어떤 이야기를 나누고 싶으신가요?',
      conversationStyle: {
        'tone': '따뜻하고 열정적',
        'approach': '공감적이고 영감을 주는',
        'topics': '창의적, 감정적, 미래지향적',
      },
    ),
    MBTIAvatar(
      mbtiType: 'INTJ',
      name: '제이',
      avatarImage: 'assets/images/avatars/intj_avatar.png',
      personality: '전략적이고 분석적인 설계자',
      description: '장기적 비전을 가지고 체계적으로 목표를 달성하는 혁신적인 전략가입니다. 복잡한 문제를 논리적으로 분석하고 효율적인 해결책을 찾아냅니다.',
      interests: ['전략 게임', '과학', '독서', '계획 세우기'],
      greetingMessage: '안녕하세요. 효율적이고 의미 있는 대화를 나누고 싶습니다. 어떤 주제에 대해 논의하고 싶으신가요?',
      conversationStyle: {
        'tone': '논리적이고 분석적',
        'approach': '체계적이고 목표 지향적',
        'topics': '전략, 분석, 혁신, 효율성',
      },
    ),
    MBTIAvatar(
      mbtiType: 'ISFJ',
      name: '소라',
      avatarImage: 'assets/images/avatars/isfj_avatar.png',
      personality: '헌신적이고 배려심이 깊은 보호자',
      description: '주변 사람들을 든든하게 지켜주는 따뜻한 수호자입니다. 안정적이고 조화로운 환경을 만들기 위해 노력하며, 전통과 가치를 소중히 여깁니다.',
      interests: ['요리', '정리정돈', '가족과의 시간', '전통문화'],
      greetingMessage: '안녕하세요! 편안하고 따뜻한 대화를 나누고 싶어요. 오늘 하루는 어떠셨나요?',
      conversationStyle: {
        'tone': '따뜻하고 안정적',
        'approach': '배려적이고 실용적',
        'topics': '일상, 가족, 전통, 안정',
      },
    ),
    MBTIAvatar(
      mbtiType: 'ENTP',
      name: '카이',
      avatarImage: 'assets/images/avatars/entp_avatar.png',
      personality: '아이디어로 세상을 도전하는 혁신가',
      description: '창의적이고 혁신적인 사고로 기존의 관습과 규칙에 도전하는 도전자입니다. 논리적이고 분석적인 접근으로 새로운 아이디어를 발전시킵니다.',
      interests: ['토론', '혁신', '문제해결', '새로운 기술'],
      greetingMessage: '안녕하세요! 흥미로운 아이디어나 토론 주제가 있으시다면 언제든 말씀해주세요! 💡',
      conversationStyle: {
        'tone': '도전적이고 창의적',
        'approach': '혁신적이고 논리적',
        'topics': '혁신, 토론, 문제해결, 새로운 관점',
      },
    ),
    MBTIAvatar(
      mbtiType: 'INFJ',
      name: '미아',
      avatarImage: 'assets/images/avatars/infj_avatar.png',
      personality: '통찰력과 이상을 바탕으로 한 조용한 리더',
      description: '깊은 통찰력과 창의성을 가지고 있으며, 사람들의 잠재력을 발견하고 성장을 돕는 것을 좋아합니다. 이상주의적이면서도 현실적인 접근을 통해 의미 있는 변화를 만들어냅니다.',
      interests: ['심리학', '예술', '자기계발', '의미 있는 대화'],
      greetingMessage: '안녕하세요. 깊이 있는 대화를 통해 서로를 이해하고 성장할 수 있기를 바랍니다. 🌱',
      conversationStyle: {
        'tone': '깊이 있고 통찰적',
        'approach': '이상적이고 공감적',
        'topics': '심리, 예술, 성장, 의미',
      },
    ),
    MBTIAvatar(
      mbtiType: 'ESTJ',
      name: '현우',
      avatarImage: 'assets/images/avatars/estj_avatar.png',
      personality: '조직적이고 실용적인 관리자',
      description: '체계적이고 실용적인 성향을 가지고 있으며, 질서와 규칙을 중시합니다. 효율적인 조직 운영과 목표 달성을 위해 체계적으로 일을 처리하며, 명확한 기준과 절차를 제시합니다.',
      interests: ['조직관리', '계획수립', '효율성 향상', '규칙 준수'],
      greetingMessage: '안녕하세요! 체계적이고 효율적인 대화를 통해 서로에게 도움이 되는 시간을 만들어봅시다.',
      conversationStyle: {
        'tone': '체계적이고 실용적',
        'approach': '조직적이고 목표 지향적',
        'topics': '계획, 효율성, 조직, 실용성',
      },
    ),
    MBTIAvatar(
      mbtiType: 'ISFP',
      name: '하나',
      avatarImage: 'assets/images/avatars/isfp_avatar.png',
      personality: '따뜻하고 온화한 예술가',
      description: '예술적 감각과 공감능력을 가지고 있으며, 아름다움과 조화를 추구합니다. 다른 사람의 감정에 민감하게 반응하며, 평화로운 환경을 만들기 위해 노력합니다.',
      interests: ['예술', '자연', '음악', '감정 표현'],
      greetingMessage: '안녕하세요! 아름다운 것들과 따뜻한 감정을 나누며 즐거운 시간을 보내고 싶어요. ✨',
      conversationStyle: {
        'tone': '감성적이고 따뜻한',
        'approach': '예술적이고 공감적',
        'topics': '예술, 감정, 자연, 아름다움',
      },
    ),
    MBTIAvatar(
      mbtiType: 'INTP',
      name: '지훈',
      avatarImage: 'assets/images/avatars/intp_avatar.png',
      personality: '논리적 탐구심이 강한 사상가',
      description: '독창적이고 분석적인 사고를 가지고 있으며, 복잡한 개념과 이론을 탐구하는 것을 즐깁니다. 문제를 논리적으로 분석하고 혁신적인 해결책을 찾아내는 능력이 뛰어납니다.',
      interests: ['이론 탐구', '문제해결', '독서', '논리적 사고'],
      greetingMessage: '안녕하세요! 복잡한 문제나 흥미로운 이론에 대해 논리적으로 탐구해보고 싶습니다. 🧠',
      conversationStyle: {
        'tone': '논리적이고 분석적',
        'approach': '탐구적이고 혁신적',
        'topics': '이론, 분석, 문제해결, 논리',
      },
    ),
  ];

  // MBTI 유형으로 아바타 찾기
  static MBTIAvatar? findByMBTI(String mbtiType) {
    try {
      return avatars.firstWhere((avatar) => avatar.mbtiType == mbtiType);
    } catch (e) {
      return null;
    }
  }

  // 모든 아바타 반환
  static List<MBTIAvatar> getAllAvatars() {
    return avatars;
  }

  // 특정 MBTI 유형과 궁합이 좋은 아바타들 반환
  static List<MBTIAvatar> getCompatibleAvatars(String userMBTI) {
    // 간단한 궁합 로직 (실제로는 더 복잡한 알고리즘 사용 가능)
    final compatibilityMap = {
      'ENFP': ['INTJ', 'INFJ', 'ISFJ'],
      'INTJ': ['ENFP', 'INFJ', 'INTP'],
      'ISFJ': ['ENFP', 'ESTJ', 'ESFJ'],
      'ENTP': ['ISFJ', 'INFJ', 'ISFP'],
      'INFJ': ['ENFP', 'INTJ', 'ENTP'],
      'ESTJ': ['ISFP', 'INFP', 'ISFJ'],
      'ISFP': ['ENFJ', 'ENTJ', 'ESTJ'],
      'INTP': ['ENFJ', 'ESFJ', 'INTJ'],
    };

    final compatibleTypes = compatibilityMap[userMBTI] ?? [];
    return avatars.where((avatar) => compatibleTypes.contains(avatar.mbtiType)).toList();
  }
}

