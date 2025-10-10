import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/api_service.dart';
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

  const MessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.conversationTitle,
  });

  MessagesState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    String? conversationTitle,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
      conversationTitle: conversationTitle ?? this.conversationTitle,
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

  MessagesNotifier(this._apiService, this.conversationId) : super(const MessagesState());

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
      final response = await _apiService.sendMessage(
        conversationId: conversationId,
        content: content,
        recipientType: recipientType,
      );
      
      if (response['success'] == true) {
        final List<Message> newMessages = [];
        
        // Add user message
        if (response['userMessage'] != null) {
          newMessages.add(Message.fromJson(response['userMessage']));
        }
        
        // Add AI response if exists
        if (response['aiResponse'] != null) {
          newMessages.add(Message.fromJson(response['aiResponse']));
        }
        
        final updatedMessages = [...state.messages, ...newMessages];
        
        state = state.copyWith(
          messages: updatedMessages,
          isSending: false,
        );
      }
    } catch (e) {
      // Error handled by API service
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
