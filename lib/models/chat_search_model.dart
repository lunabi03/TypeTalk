import 'package:typetalk/models/chat_model.dart';
import 'package:typetalk/models/message_model.dart';

// 검색 타입 열거형
enum SearchType {
  all('all'),
  chats('chats'),
  messages('messages'),
  participants('participants');

  const SearchType(this.value);
  final String value;

  static SearchType fromString(String value) {
    return SearchType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SearchType.all,
    );
  }
}

// 검색 필터 모델
class SearchFilter {
  final SearchType type;
  final String? chatId;
  final String? senderId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final List<String>? messageTypes;
  final List<String>? mbtiTypes;
  final bool? hasMedia;
  final bool? hasReactions;

  SearchFilter({
    this.type = SearchType.all,
    this.chatId,
    this.senderId,
    this.dateFrom,
    this.dateTo,
    this.messageTypes,
    this.mbtiTypes,
    this.hasMedia,
    this.hasReactions,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.value,
      'chatId': chatId,
      'senderId': senderId,
      'dateFrom': dateFrom?.toIso8601String(),
      'dateTo': dateTo?.toIso8601String(),
      'messageTypes': messageTypes,
      'mbtiTypes': mbtiTypes,
      'hasMedia': hasMedia,
      'hasReactions': hasReactions,
    };
  }

  factory SearchFilter.fromMap(Map<String, dynamic> map) {
    return SearchFilter(
      type: SearchType.fromString(map['type'] ?? 'all'),
      chatId: map['chatId'],
      senderId: map['senderId'],
      dateFrom: map['dateFrom'] != null ? DateTime.parse(map['dateFrom']) : null,
      dateTo: map['dateTo'] != null ? DateTime.parse(map['dateTo']) : null,
      messageTypes: map['messageTypes'] != null 
          ? List<String>.from(map['messageTypes'])
          : null,
      mbtiTypes: map['mbtiTypes'] != null 
          ? List<String>.from(map['mbtiTypes'])
          : null,
      hasMedia: map['hasMedia'],
      hasReactions: map['hasReactions'],
    );
  }

  SearchFilter copyWith({
    SearchType? type,
    String? chatId,
    String? senderId,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? messageTypes,
    List<String>? mbtiTypes,
    bool? hasMedia,
    bool? hasReactions,
  }) {
    return SearchFilter(
      type: type ?? this.type,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      messageTypes: messageTypes ?? this.messageTypes,
      mbtiTypes: mbtiTypes ?? this.mbtiTypes,
      hasMedia: hasMedia ?? this.hasMedia,
      hasReactions: hasReactions ?? this.hasReactions,
    );
  }

  // 필터가 설정되어 있는지 확인
  bool get hasFilters {
    return chatId != null ||
           senderId != null ||
           dateFrom != null ||
           dateTo != null ||
           (messageTypes != null && messageTypes!.isNotEmpty) ||
           (mbtiTypes != null && mbtiTypes!.isNotEmpty) ||
           hasMedia != null ||
           hasReactions != null;
  }

  // 날짜 범위가 설정되어 있는지 확인
  bool get hasDateRange => dateFrom != null || dateTo != null;

  // 메시지 타입 필터가 설정되어 있는지 확인
  bool get hasMessageTypeFilter => messageTypes != null && messageTypes!.isNotEmpty;

  // MBTI 타입 필터가 설정되어 있는지 확인
  bool get hasMBTIFilter => mbtiTypes != null && mbtiTypes!.isNotEmpty;
}

// 검색 결과 모델
class SearchResult<T> {
  final T item;
  final double relevance;
  final String? highlight;
  final Map<String, dynamic>? metadata;

  SearchResult({
    required this.item,
    required this.relevance,
    this.highlight,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'item': item,
      'relevance': relevance,
      'highlight': highlight,
      'metadata': metadata,
    };
  }

  // 관련성 점수에 따른 정렬
  int compareTo(SearchResult other) {
    return other.relevance.compareTo(relevance); // 내림차순 정렬
  }
}

// 채팅 검색 결과 모델
class ChatSearchResult extends SearchResult<ChatModel> {
  ChatSearchResult({
    required ChatModel item,
    required double relevance,
    String? highlight,
    Map<String, dynamic>? metadata,
  }) : super(
    item: item,
    relevance: relevance,
    highlight: highlight,
    metadata: metadata,
  );

  // MBTI 호환성 점수 계산
  double calculateMBTICompatibility(String userMBTI) {
    if (item.targetMBTI == null || item.targetMBTI!.isEmpty) {
      return 0.5; // 기본 점수
    }
    
    if (item.targetMBTI!.contains(userMBTI)) {
      return 1.0; // 완벽한 호환
    }
    
    // 부분 호환성 계산
    final userCategory = _getMBTICategory(userMBTI);
    final targetCategories = item.targetMBTI!.map(_getMBTICategory).toSet();
    
    if (targetCategories.contains(userCategory)) {
      return 0.8; // 카테고리 호환
    }
    
    return 0.3; // 낮은 호환성
  }

  String _getMBTICategory(String mbti) {
    if (mbti.length >= 2) {
      return mbti.substring(1, 3); // NT, NF, ST, SF
    }
    return mbti;
  }
}

// 메시지 검색 결과 모델
class MessageSearchResult extends SearchResult<MessageModel> {
  MessageSearchResult({
    required MessageModel item,
    required double relevance,
    String? highlight,
    Map<String, dynamic>? metadata,
  }) : super(
    item: item,
    relevance: relevance,
    highlight: highlight,
    metadata: metadata,
  );

  // 메시지 내용에서 검색어 하이라이트
  String getHighlightedContent(String searchTerm) {
    if (highlight != null) return highlight!;
    
    final content = item.content;
    if (searchTerm.isEmpty) return content;
    
    // 간단한 하이라이트 구현
    final lowerContent = content.toLowerCase();
    final lowerTerm = searchTerm.toLowerCase();
    
    if (lowerContent.contains(lowerTerm)) {
      final index = lowerContent.indexOf(lowerTerm);
      final before = content.substring(0, index);
      const highlightStart = '**';
      const highlightEnd = '**';
      final term = content.substring(index, index + searchTerm.length);
      final after = content.substring(index + searchTerm.length);
      
      return '$before$highlightStart$term$highlightEnd$after';
    }
    
    return content;
  }

  // 메시지가 최근인지 확인 (24시간 이내)
  bool get isRecent {
    final age = DateTime.now().difference(item.createdAt);
    return age.inHours < 24;
  }

  // 메시지가 오래되었는지 확인 (7일 이상)
  bool get isOld {
    final age = DateTime.now().difference(item.createdAt);
    return age.inDays > 7;
  }
}

// 검색 통계 모델
class SearchStats {
  final int totalResults;
  final int chatResults;
  final int messageResults;
  final int participantResults;
  final Duration searchTime;
  final String? query;
  final SearchFilter? filter;

  const SearchStats({
    required this.totalResults,
    this.chatResults = 0,
    this.messageResults = 0,
    this.participantResults = 0,
    required this.searchTime,
    this.query,
    this.filter,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalResults': totalResults,
      'chatResults': chatResults,
      'messageResults': messageResults,
      'participantResults': participantResults,
      'searchTime': searchTime.inMilliseconds,
      'query': query,
      'filter': filter?.toMap(),
    };
  }

  // 검색 성능 점수 (낮을수록 좋음)
  double get performanceScore {
    if (totalResults == 0) return 0.0;
    return searchTime.inMilliseconds / totalResults;
  }

  // 결과가 있는지 확인
  bool get hasResults => totalResults > 0;

  // 빠른 검색인지 확인 (100ms 이내)
  bool get isFastSearch => searchTime.inMilliseconds < 100;

  // 느린 검색인지 확인 (1초 이상)
  bool get isSlowSearch => searchTime.inMilliseconds > 1000;
}

// 검색 도우미 클래스
class SearchHelper {
  // 텍스트 관련성 점수 계산
  static double calculateTextRelevance(String text, String searchTerm) {
    if (searchTerm.isEmpty) return 0.0;
    
    final lowerText = text.toLowerCase();
    final lowerTerm = searchTerm.toLowerCase();
    
    if (lowerText == lowerTerm) return 1.0; // 완벽한 일치
    if (lowerText.startsWith(lowerTerm)) return 0.9; // 시작 부분 일치
    if (lowerText.endsWith(lowerTerm)) return 0.8; // 끝 부분 일치
    if (lowerText.contains(lowerTerm)) return 0.7; // 포함
    
    // 부분 일치 점수 계산
    double partialScore = 0.0;
    final words = lowerText.split(' ');
    final termWords = lowerTerm.split(' ');
    
    for (final word in words) {
      for (final termWord in termWords) {
        if (word.contains(termWord) || termWord.contains(word)) {
          partialScore += 0.3;
        }
      }
    }
    
    return partialScore.clamp(0.0, 0.6);
  }

  // 날짜 관련성 점수 계산
  static double calculateDateRelevance(DateTime date, DateTime? from, DateTime? to) {
    if (from == null && to == null) return 0.5;
    
    final now = DateTime.now();
    final age = now.difference(date);
    
    if (from != null && date.isBefore(from)) return 0.0;
    if (to != null && date.isAfter(to)) return 0.0;
    
    // 최근일수록 높은 점수
    if (age.inDays == 0) return 1.0;
    if (age.inDays <= 7) return 0.8;
    if (age.inDays <= 30) return 0.6;
    if (age.inDays <= 90) return 0.4;
    
    return 0.2;
  }

  // 검색 결과 정렬
  static List<SearchResult> sortResults(List<SearchResult> results) {
    results.sort((a, b) => a.compareTo(b));
    return results;
  }

  // 검색 결과 필터링
  static List<SearchResult> filterResults(
    List<SearchResult> results,
    SearchFilter filter,
  ) {
    if (!filter.hasFilters) return results;
    
    return results.where((result) {
      if (filter.chatId != null && result.item is ChatModel) {
        final chat = result.item as ChatModel;
        if (chat.chatId != filter.chatId) return false;
      }
      
      if (filter.senderId != null && result.item is MessageModel) {
        final message = result.item as MessageModel;
        if (message.senderId != filter.senderId) return false;
      }
      
      if (filter.dateFrom != null || filter.dateTo != null) {
        DateTime? date;
        if (result.item is MessageModel) {
          date = (result.item as MessageModel).createdAt;
        } else if (result.item is ChatModel) {
          date = (result.item as ChatModel).createdAt;
        }
        
        if (date != null) {
          if (filter.dateFrom != null && date.isBefore(filter.dateFrom!)) {
            return false;
          }
          if (filter.dateTo != null && date.isAfter(filter.dateTo!)) {
            return false;
          }
        }
      }
      
      return true;
    }).toList();
  }
}
