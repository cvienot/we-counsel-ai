import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/realtime_service.dart';
import '../services/streaming_message_service.dart';
import 'auth_provider.dart';

// Conversations state
class ConversationsState {
  final List<Conversation> conversations;
  final bool isLoading;
  final String? error;

  const ConversationsState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
  });

  ConversationsState copyWith({
    List<Conversation>? conversations,
    bool? isLoading,
    String? error,
  }) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Messages state
class MessagesState {
  final List<Message> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final String? conversationTitle;
  final Map<String, bool> typingUsers;
  final Map<String, String> streamingMessages;
  final Set<String> streamingMessageIds;

  const MessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.conversationTitle,
    this.typingUsers = const {},
    this.streamingMessages = const {},
    this.streamingMessageIds = const {},
  });

  MessagesState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    String? conversationTitle,
    Map<String, bool>? typingUsers,
    Map<String, String>? streamingMessages,
    Set<String>? streamingMessageIds,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
      conversationTitle: conversationTitle ?? this.conversationTitle,
      typingUsers: typingUsers ?? this.typingUsers,
      streamingMessages: streamingMessages ?? this.streamingMessages,
      streamingMessageIds: streamingMessageIds ?? this.streamingMessageIds,
    );
  }
}

// Main Thread state
class MainThreadState {
  final Conversation? mainThread;
  final bool isLoading;
  final String? error;

  const MainThreadState({
    this.mainThread,
    this.isLoading = false,
    this.error,
  });

  MainThreadState copyWith({
    Conversation? mainThread,
    bool? isLoading,
    String? error,
  }) {
    return MainThreadState(
      mainThread: mainThread ?? this.mainThread,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Main Thread provider
class MainThreadNotifier extends StateNotifier<MainThreadState> {
  final ApiService _apiService;
  final Ref _ref;

  MainThreadNotifier(this._apiService, this._ref) : super(const MainThreadState());

  Future<void> loadMainThread() async {
    // Only load if user has a partner
    final hasPartner = _ref.read(hasPartnerProvider);
    if (!hasPartner) {
      state = state.copyWith(mainThread: null);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.getMainThread();
      
      if (response['success'] == true && response['mainThread'] != null) {
        final mainThread = Conversation.fromJson(response['mainThread']);
        state = state.copyWith(
          mainThread: mainThread,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

// Conversations provider
class ConversationsNotifier extends StateNotifier<ConversationsState> {
  final ApiService _apiService;
  final Ref _ref;

  ConversationsNotifier(this._apiService, this._ref) : super(const ConversationsState());

  Future<void> loadConversations() async {
    // Only load if user has a partner
    final hasPartner = _ref.read(hasPartnerProvider);
    if (!hasPartner) {
      state = state.copyWith(conversations: []);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.getConversations();
      
      if (response['success'] == true) {
        final List<dynamic> conversationsJson = response['conversations'] ?? [];
        final conversations = conversationsJson
            .map((json) => Conversation.fromJson(json))
            .toList();
        
        state = state.copyWith(
          conversations: conversations,
          isLoading: false,
        );
      }
    } catch (e) {
      // Error handled by API service
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> createConversation({
    required String title,
    String? topic,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.createConversation(
        title: title,
        topic: topic,
      );
      
      if (response['success'] == true && response['conversation'] != null) {
        final conversation = Conversation.fromJson(response['conversation']);
        final updatedConversations = [conversation, ...state.conversations];
        
        state = state.copyWith(
          conversations: updatedConversations,
          isLoading: false,
        );
      }
    } catch (e) {
      // Error handled by API service
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> updateConversation({
    required String conversationId,
    required String title,
    String? topic,
  }) async {
    try {
      final response = await _apiService.updateConversation(
        conversationId: conversationId,
        title: title,
        topic: topic,
      );
      
      if (response['success'] == true && response['conversation'] != null) {
        final updatedConversation = Conversation.fromJson(response['conversation']);
        final updatedConversations = state.conversations.map((conv) {
          return conv.conversationId == conversationId ? updatedConversation : conv;
        }).toList();
        
        state = state.copyWith(conversations: updatedConversations);
      }
    } catch (e) {
      // Error handled by API service
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _apiService.deleteConversation(conversationId);
      
      final updatedConversations = state.conversations
          .where((conv) => conv.conversationId != conversationId)
          .toList();
      
      state = state.copyWith(conversations: updatedConversations);
    } catch (e) {
      // Error handled by API service
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Messages provider
class MessagesNotifier extends StateNotifier<MessagesState> {
  final ApiService _apiService;
  final String conversationId;
  final RealtimeService _realtimeService = RealtimeService();
  final StreamingMessageService _streamingService = StreamingMessageService();
  
  StreamSubscription? _newMessageSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _aiStreamSubscription;
  Timer? _typingTimer;

  MessagesNotifier(this._apiService, this.conversationId) : super(const MessagesState()) {
    _setupRealtimeListeners();
  }

  void _setupRealtimeListeners() {
    // Listen for new messages
    _newMessageSubscription = _realtimeService.newMessageStream.listen((message) {
      if (message.conversationId == conversationId) {
        _addNewMessage(message);
      }
    });

    // Listen for typing updates
    _typingSubscription = _realtimeService.typingStream.listen((data) {
      if (data['conversationId'] == conversationId) {
        _updateTypingStatus(data);
      }
    });

    // Listen for AI streaming chunks
    _aiStreamSubscription = _realtimeService.aiStreamStream.listen((data) {
      if (data['conversationId'] == conversationId) {
        _handleAIStreamChunk(data);
      }
    });
  }

  void _addNewMessage(Message message) {
    final updatedMessages = List<Message>.from(state.messages);
    updatedMessages.add(message);
    updatedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    state = state.copyWith(messages: updatedMessages);
  }

  void _updateTypingStatus(Map<String, dynamic> data) {
    final userId = data['userId'] as String;
    final isTyping = data['isTyping'] as bool;
    
    final updatedTypingUsers = Map<String, bool>.from(state.typingUsers);
    
    if (isTyping) {
      updatedTypingUsers[userId] = true;
    } else {
      updatedTypingUsers.remove(userId);
    }
    
    state = state.copyWith(typingUsers: updatedTypingUsers);
  }

  void _handleAIStreamChunk(Map<String, dynamic> data) {
    final messageId = data['messageId'] as String;
    final chunk = data['chunk'] as String;
    final isComplete = data['isComplete'] as bool;
    
    _streamingService.handleAIStreamChunk(messageId, chunk, isComplete);
    
    final updatedStreamingMessages = Map<String, String>.from(state.streamingMessages);
    final updatedStreamingIds = Set<String>.from(state.streamingMessageIds);
    
    if (!isComplete) {
      updatedStreamingMessages[messageId] = _streamingService.getStreamingContent(messageId);
      updatedStreamingIds.add(messageId);
    } else {
      // Create the complete AI message and add to messages list
      final completeContent = _streamingService.getStreamingContent(messageId);
      if (completeContent.isNotEmpty) {
        final aiMessage = Message(
          messageId: messageId,
          conversationId: conversationId,
          senderId: 'ai-counsellor',
          senderName: 'Dr. Sarah (AI Counsellor)',
          senderType: MessageSenderType.ai,
          content: completeContent,
          recipientType: MessageRecipientType.both,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          createdAt: DateTime.now(),
        );
        
        _addNewMessage(aiMessage);
      }
      
      updatedStreamingMessages.remove(messageId);
      updatedStreamingIds.remove(messageId);
      _streamingService.cleanupStream(messageId);
    }
    
    state = state.copyWith(
      streamingMessages: updatedStreamingMessages,
      streamingMessageIds: updatedStreamingIds,
    );
  }

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.getMessages(conversationId);
      
      if (response['success'] == true) {
        final List<dynamic> messagesJson = response['messages'] ?? [];
        final messages = messagesJson
            .map((json) => Message.fromJson(json))
            .where((message) => !message.isDeleted)
            .toList();
        
        state = state.copyWith(
          messages: messages,
          conversationTitle: response['conversationTitle'],
          isLoading: false,
        );
      }
    } catch (e) {
      // Error handled by API service
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> sendMessage({
    required String content,
    String recipientType = 'both',
  }) async {
    state = state.copyWith(isSending: true, error: null);
    
    try {
      // Use streaming message service for AI responses
      final userMessage = await _streamingService.sendMessageWithStreaming(
        conversationId,
        content,
        recipientType: recipientType,
      );
      
      if (userMessage != null) {
        // Add user message immediately
        _addNewMessage(userMessage);
      }
      
      state = state.copyWith(isSending: false);
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> editMessage({
    required String messageId,
    required String content,
  }) async {
    try {
      final response = await _apiService.editMessage(
        messageId: messageId,
        content: content,
      );
      
      if (response['success'] == true && response['updatedMessage'] != null) {
        final updatedMessage = Message.fromJson(response['updatedMessage']);
        final updatedMessages = state.messages.map((msg) {
          return msg.messageId == messageId ? updatedMessage : msg;
        }).toList();
        
        state = state.copyWith(messages: updatedMessages);
      }
    } catch (e) {
      // Error handled by API service
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _apiService.deleteMessage(messageId);
      
      // Mark message as deleted locally
      final updatedMessages = state.messages.map((msg) {
        return msg.messageId == messageId 
            ? msg.copyWith(isDeleted: true, deletedAt: DateTime.now())
            : msg;
      }).toList();
      
      state = state.copyWith(messages: updatedMessages);
    } catch (e) {
      // Error handled by API service
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> sendMessageWithStreaming({
    required String content,
    String recipientType = 'both',
  }) async {
    await sendMessage(content: content, recipientType: recipientType);
  }

  void startTyping() {
    _typingTimer?.cancel();
    _realtimeService.sendTypingStatus(conversationId, true);
    
    // Auto-stop typing after 3 seconds
    _typingTimer = Timer(const Duration(seconds: 3), () {
      stopTyping();
    });
  }

  void stopTyping() {
    _typingTimer?.cancel();
    _realtimeService.sendTypingStatus(conversationId, false);
  }

  Stream<String> getAIMessageStream(String messageId) {
    return _streamingService.getAIMessageStream(messageId);
  }

  String getStreamingContent(String messageId) {
    return state.streamingMessages[messageId] ?? '';
  }

  bool isMessageStreaming(String messageId) {
    return state.streamingMessageIds.contains(messageId);
  }

  @override
  void dispose() {
    _newMessageSubscription?.cancel();
    _typingSubscription?.cancel();
    _aiStreamSubscription?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }
}

// Providers
final mainThreadProvider = StateNotifierProvider<MainThreadNotifier, MainThreadState>((ref) {
  return MainThreadNotifier(ref.read(apiServiceProvider), ref);
});

final conversationsProvider = StateNotifierProvider<ConversationsNotifier, ConversationsState>((ref) {
  return ConversationsNotifier(ref.read(apiServiceProvider), ref);
});

final messagesProvider = StateNotifierProvider.family<MessagesNotifier, MessagesState, String>((ref, conversationId) {
  return MessagesNotifier(ref.read(apiServiceProvider), conversationId);
});

// Helper providers
final activeConversationsProvider = Provider<List<Conversation>>((ref) {
  final conversations = ref.watch(conversationsProvider).conversations;
  return conversations.where((conv) => conv.isActive).toList();
});
