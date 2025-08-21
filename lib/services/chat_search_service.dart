import 'package:get/get.dart';
import 'package:typetalk/models/chat_model.dart';
import 'package:typetalk/models/message_model.dart';
import 'package:typetalk/models/chat_search_model.dart';
import 'package:typetalk/services/real_firebase_service.dart';

// 채팅 검색 서비스 클래스
class ChatSearchService extends GetxService {
  final RealFirebaseService _firestoreService = Get.find<RealFirebaseService>();
  
  // 검색 결과
  final RxList<SearchResult> searchResults = <SearchResult>[].obs;
  final RxList<ChatSearchResult> chatResults = <ChatSearchResult>[].obs;
  final RxList<MessageSearchResult> messageResults = <MessageSearchResult>[].obs;
  
  // 검색 상태
  final RxBool isSearching = false.obs;
  final RxString currentQuery = ''.obs;
  final Rx<SearchFilter> currentFilter = SearchFilter().obs;
  final Rx<SearchStats?> lastSearchStats = Rx<SearchStats?>(null);
  
  // 검색 히스토리
  final RxList<String> searchHistory = <String>[].obs;
  final RxList<SearchFilter> filterHistory = <SearchFilter>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadSearchHistory();
  }

  // 검색 히스토리 로드
  void _loadSearchHistory() {
    // 실제로는 로컬 저장소나 서버에서 로드
    searchHistory.addAll([
      'MBTI',
      '채팅',
      '프로그래밍',
      '음악',
      '영화',
    ]);
  }

  // 통합 검색
  Future<SearchStats> search(String query, {SearchFilter? filter}) async {
    if (query.trim().isEmpty) {
      return SearchStats(
        totalResults: 0,
        searchTime: Duration.zero,
        query: query,
        filter: filter,
      );
    }

    final stopwatch = Stopwatch()..start();
    isSearching.value = true;
    currentQuery.value = query;
    currentFilter.value = filter ?? SearchFilter();

    try {
      // 검색어를 히스토리에 추가
      if (!searchHistory.contains(query)) {
        searchHistory.insert(0, query);
        if (searchHistory.length > 20) {
          searchHistory.removeLast();
        }
      }

      // 필터 히스토리에 추가
      if (filter != null && !filterHistory.contains(filter)) {
        filterHistory.insert(0, filter);
        if (filterHistory.length > 10) {
          filterHistory.removeLast();
        }
      }

      // 검색 실행
      final results = await _executeSearch(query, filter);
      
      // 결과 정렬 및 필터링
      final sortedResults = SearchHelper.sortResults(results);
      final filteredResults = SearchHelper.filterResults(sortedResults, filter ?? SearchFilter());
      
      // 결과 분류
      _categorizeResults(filteredResults);
      
      // 검색 통계 생성
      stopwatch.stop();
      final stats = SearchStats(
        totalResults: filteredResults.length,
        chatResults: chatResults.length,
        messageResults: messageResults.length,
        searchTime: stopwatch.elapsed,
        query: query,
        filter: filter,
      );
      
      lastSearchStats.value = stats;
      return stats;

    } catch (e) {
      print('검색 실패: $e');
      return SearchStats(
        totalResults: 0,
        searchTime: Duration.zero,
        query: query,
        filter: filter,
      );
    } finally {
      isSearching.value = false;
    }
  }

  // 실제 검색 실행
  Future<List<SearchResult>> _executeSearch(String query, SearchFilter? filter) async {
    final results = <SearchResult>[];
    
    try {
      // 채팅방 검색
      if (filter?.type == SearchType.all || filter?.type == SearchType.chats) {
        final chatResults = await _searchChats(query, filter);
        results.addAll(chatResults);
      }
      
      // 메시지 검색
      if (filter?.type == SearchType.all || filter?.type == SearchType.messages) {
        final messageResults = await _searchMessages(query, filter);
        results.addAll(messageResults);
      }
      
      // 참여자 검색 (실제로는 사용자 서비스와 연동)
      if (filter?.type == SearchType.all || filter?.type == SearchType.participants) {
        // 구현 예정
      }
      
    } catch (e) {
      print('검색 실행 실패: $e');
    }
    
    return results;
  }

  // 채팅방 검색
  Future<List<ChatSearchResult>> _searchChats(String query, SearchFilter? filter) async {
    try {
      final chatsSnapshot = await _firestoreService.getCollectionDocuments('chats');
      final results = <ChatSearchResult>[];
      
      for (final chatSnapshot in chatsSnapshot.docs) {
        final chat = ChatModel.fromMap(chatSnapshot.data() as Map<String, dynamic>);
        
        // 검색어 관련성 계산
        double relevance = 0.0;
        
        // 제목 검색
        relevance += SearchHelper.calculateTextRelevance(chat.title, query) * 2.0;
        
        // 설명 검색
        if (chat.description != null) {
          relevance += SearchHelper.calculateTextRelevance(chat.description!, query) * 1.5;
        }
        
        // MBTI 관련성
        if (chat.targetMBTI != null) {
          for (final mbti in chat.targetMBTI!) {
            if (mbti.toLowerCase().contains(query.toLowerCase())) {
              relevance += 1.0;
            }
          }
        }
        
        // 날짜 관련성
        relevance += SearchHelper.calculateDateRelevance(chat.createdAt, filter?.dateFrom, filter?.dateTo);
        
        // MBTI 필터 적용
        if (filter?.hasMBTIFilter == true && filter?.mbtiTypes != null) {
          bool hasMatchingMBTI = false;
          for (final mbti in filter!.mbtiTypes!) {
            if (chat.targetMBTI?.contains(mbti) == true) {
              hasMatchingMBTI = true;
              break;
            }
          }
          if (!hasMatchingMBTI) continue;
        }
        
        if (relevance > 0.1) { // 임계값 이상인 결과만 포함
          results.add(ChatSearchResult(
            item: chat,
            relevance: relevance,
            metadata: {
              'type': 'chat',
              'participantCount': chat.participantCount,
              'messageCount': chat.stats.messageCount,
            },
          ));
        }
      }
      
      return results;
    } catch (e) {
      print('채팅방 검색 실패: $e');
      return [];
    }
  }

  // 메시지 검색
  Future<List<MessageSearchResult>> _searchMessages(String query, SearchFilter? filter) async {
    try {
      final messagesSnapshot = await _firestoreService.getCollectionDocuments('messages');
      final results = <MessageSearchResult>[];
      
      for (final messageSnapshot in messagesSnapshot.docs) {
        final message = MessageModel.fromMap(messageSnapshot.data() as Map<String, dynamic>);
        
        // 검색어 관련성 계산
        double relevance = 0.0;
        
        // 메시지 내용 검색
        relevance += SearchHelper.calculateTextRelevance(message.content, query) * 2.0;
        
        // 발신자 이름 검색
        relevance += SearchHelper.calculateTextRelevance(message.senderName, query) * 1.0;
        
        // MBTI 관련성
        if (message.senderMBTI != null) {
          if (message.senderMBTI!.toLowerCase().contains(query.toLowerCase())) {
            relevance += 0.8;
          }
        }
        
        // 날짜 관련성
        relevance += SearchHelper.calculateDateRelevance(message.createdAt, filter?.dateFrom, filter?.dateTo);
        
        // 채팅방 필터 적용
        if (filter?.chatId != null && message.chatId != filter!.chatId) {
          continue;
        }
        
        // 발신자 필터 적용
        if (filter?.senderId != null && message.senderId != filter!.senderId) {
          continue;
        }
        
        // 메시지 타입 필터 적용
        if (filter?.hasMessageTypeFilter == true && filter?.messageTypes != null) {
          if (!filter!.messageTypes!.contains(message.type)) {
            continue;
          }
        }
        
        // 미디어 필터 적용
        if (filter?.hasMedia == true && !message.hasMedia) {
          continue;
        }
        
        // 반응 필터 적용
        if (filter?.hasReactions == true && !message.hasReactions) {
          continue;
        }
        
        if (relevance > 0.1) { // 임계값 이상인 결과만 포함
          results.add(MessageSearchResult(
            item: message,
            relevance: relevance,
            metadata: {
              'type': 'message',
              'messageType': message.type,
              'hasMedia': message.hasMedia,
              'hasReactions': message.hasReactions,
            },
          ));
        }
      }
      
      return results;
    } catch (e) {
      print('메시지 검색 실패: $e');
      return [];
    }
  }

  // 결과 분류
  void _categorizeResults(List<SearchResult> results) {
    chatResults.clear();
    messageResults.clear();
    
    for (final result in results) {
      if (result is ChatSearchResult) {
        chatResults.add(result);
      } else if (result is MessageSearchResult) {
        messageResults.add(result);
      }
    }
    
    searchResults.value = results;
  }

  // 검색어 자동완성
  List<String> getSuggestions(String partialQuery) {
    if (partialQuery.isEmpty) return [];
    
    final suggestions = <String>[];
    final lowerQuery = partialQuery.toLowerCase();
    
    // 검색 히스토리에서 제안
    for (final history in searchHistory) {
      if (history.toLowerCase().contains(lowerQuery)) {
        suggestions.add(history);
      }
    }
    
    // MBTI 타입 제안
    final mbtiTypes = ['ENFP', 'ENFJ', 'ENTP', 'ENTJ', 'ESFP', 'ESFJ', 'ESTP', 'ESTJ', 
                       'INFP', 'INFJ', 'INTP', 'INTJ', 'ISFP', 'ISFJ', 'ISTP', 'ISTJ'];
    
    for (final mbti in mbtiTypes) {
      if (mbti.toLowerCase().contains(lowerQuery)) {
        suggestions.add(mbti);
      }
    }
    
    // 일반적인 채팅 관련 키워드
    final commonKeywords = ['채팅', '메시지', '그룹', '개인', 'MBTI', '대화', '소통'];
    
    for (final keyword in commonKeywords) {
      if (keyword.toLowerCase().contains(lowerQuery)) {
        suggestions.add(keyword);
      }
    }
    
    return suggestions.take(10).toList(); // 최대 10개 제안
  }

  // 검색 결과 필터링
  void filterResults(SearchFilter filter) {
    currentFilter.value = filter;
    
    if (searchResults.isNotEmpty) {
      final filteredResults = SearchHelper.filterResults(searchResults, filter);
      _categorizeResults(filteredResults);
    }
  }

  // 검색 결과 정렬
  void sortResults() {
    if (searchResults.isNotEmpty) {
      final sortedResults = SearchHelper.sortResults(searchResults);
      _categorizeResults(sortedResults);
    }
  }

  // 검색 히스토리 지우기
  void clearSearchHistory() {
    searchHistory.clear();
  }

  // 필터 히스토리 지우기
  void clearFilterHistory() {
    filterHistory.clear();
  }

  // 검색 결과 지우기
  void clearSearchResults() {
    searchResults.clear();
    chatResults.clear();
    messageResults.clear();
    currentQuery.value = '';
    lastSearchStats.value = null;
  }

  // 검색 통계 가져오기
  SearchStats? getLastSearchStats() {
    return lastSearchStats.value;
  }

  // 검색 성능 분석
  Map<String, dynamic> analyzeSearchPerformance() {
    final stats = lastSearchStats.value;
    if (stats == null) return {};
    
    return {
      'query': stats.query,
      'totalResults': stats.totalResults,
      'searchTime': '${stats.searchTime.inMilliseconds}ms',
      'performanceScore': stats.performanceScore.toStringAsFixed(2),
      'isFastSearch': stats.isFastSearch,
      'isSlowSearch': stats.isSlowSearch,
      'filterApplied': stats.filter?.hasFilters ?? false,
    };
  }
}
