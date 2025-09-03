# GEMINI API 설정 가이드

TypeTalk 앱에서 GEMINI AI를 사용하기 위한 설정 방법입니다.

## 1. GEMINI API 키 발급

### 1.1 Google AI Studio 접속
- [Google AI Studio](https://makersuite.google.com/app/apikey)에 접속
- Google 계정으로 로그인

### 1.2 API 키 생성
1. "Create API Key" 버튼 클릭
2. 새 API 키 생성
3. 생성된 API 키를 복사하여 안전한 곳에 보관

## 2. 코드 설정

### 2.1 API 키 설정
`lib/config/gemini_config.dart` 파일에서 API 키를 설정하세요:

```dart
class GeminiConfig {
  // TODO: 실제 API 키로 교체하세요
  static const String apiKey = 'your_actual_gemini_api_key_here';
  // ... 나머지 코드
}
```

### 2.2 환경 변수 사용 (권장)
`.env` 파일을 생성하고 API 키를 저장하세요:

```env
GEMINI_API_KEY=your_actual_gemini_api_key_here
```

그리고 `gemini_config.dart`를 다음과 같이 수정:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiConfig {
  static String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  // ... 나머지 코드
}
```

## 3. 기능 설명

### 3.1 AI 채팅 기능
- **MBTI 기반 개인화**: 사용자의 MBTI 유형을 고려한 맞춤형 답변
- **대화 히스토리**: 이전 대화 내용을 기억하여 맥락 있는 대화
- **빠른 질문**: 자주 묻는 질문에 대한 빠른 접근
- **안전 설정**: 유해한 콘텐츠 필터링

### 3.2 MBTI 특화 기능
- **MBTI 궁합 분석**: 성격 유형별 궁합 정보 제공
- **커뮤니케이션 가이드**: MBTI별 대화 스타일 조언
- **개인 성장 도움**: MBTI 특성에 맞는 조언 제공

## 4. 사용 방법

### 4.1 AI 채팅 시작
1. 메인 화면에서 "AI 어시스턴트와 대화하기" 버튼 클릭
2. AI와 자연스럽게 대화 시작
3. MBTI 관련 질문이나 일반적인 대화 가능

### 4.2 빠른 질문 사용
- "MBTI 궁합에 대해 알려줘"
- "ENFP 성격 특성은?"
- "대화 잘하는 방법"
- "스트레스 해소법"

## 5. 보안 주의사항

### 5.1 API 키 보호
- API 키를 코드에 직접 하드코딩하지 마세요
- `.env` 파일을 `.gitignore`에 추가하세요
- 프로덕션 환경에서는 서버 사이드에서 API 키를 관리하세요

### 5.2 사용량 제한
- GEMINI API는 무료 티어에서 월 사용량 제한이 있습니다
- 사용량 모니터링을 위해 Google Cloud Console을 확인하세요

## 6. 문제 해결

### 6.1 API 오류
- API 키가 올바르게 설정되었는지 확인
- 네트워크 연결 상태 확인
- API 사용량 한도 확인

### 6.2 응답 품질 개선
- `gemini_config.dart`의 `systemPrompt` 수정
- `generationConfig` 파라미터 조정
- 대화 컨텍스트 개선

## 7. 고급 설정

### 7.1 모델 파라미터 조정
```dart
'generationConfig': {
  'temperature': 0.7,      // 창의성 (0.0 ~ 1.0)
  'topK': 40,             // 토큰 선택 다양성
  'topP': 0.95,           // 누적 확률 임계값
  'maxOutputTokens': 1024, // 최대 출력 토큰 수
},
```

### 7.2 안전 설정 커스터마이징
```dart
'safetySettings': [
  {
    'category': 'HARM_CATEGORY_HARASSMENT',
    'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
  },
  // ... 추가 안전 설정
],
```

## 8. 지원 및 문의

문제가 발생하거나 추가 기능이 필요한 경우:
- GitHub Issues 등록
- 개발팀에 문의

---

**참고**: 이 가이드는 GEMINI API의 최신 버전을 기준으로 작성되었습니다. API 변경사항이 있을 수 있으니 [공식 문서](https://ai.google.dev/docs)를 참고하세요.


