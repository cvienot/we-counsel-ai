import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/conversation_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/message.dart';
import '../../services/realtime_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class ConversationScreen extends ConsumerStatefulWidget {
  final String conversationId;
  
  const ConversationScreen({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _realtimeService = RealtimeService();
  
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;
  Timer? _typingTimer;
  Set<String> _typingUsers = {};
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messagesProvider(widget.conversationId).notifier).loadMessages();
    });
    
    // Listen to typing events
    _typingSubscription = _realtimeService.typingStream.listen((data) {
      print('👂 RECEIVED TYPING EVENT: $data');
      if (data['conversationId'] == widget.conversationId) {
        final userId = data['userId'];
        final isTyping = data['isTyping'] == true;
        
        print('💬 TYPING UPDATE for conversation ${widget.conversationId}: user $userId is ${isTyping ? "typing" : "not typing"}');
        
        setState(() {
          if (isTyping) {
            _typingUsers.add(userId);
            print('✅ Added user $userId to typing users. Current typing users: $_typingUsers');
          } else {
            _typingUsers.remove(userId);
            print('❌ Removed user $userId from typing users. Current typing users: $_typingUsers');
          }
        });
      } else {
        print('🚫 Typing event for different conversation: ${data['conversationId']} != ${widget.conversationId}');
      }
    });
    
    // Listen to text changes to send typing status
    _messageController.addListener(() {
      debugPrint('🎹 Text controller listener triggered - text: "${_messageController.text}"');
      _handleTextChange();
    });
  }

  @override
  void dispose() {
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    
    // Stop typing when leaving the screen
    if (_isTyping) {
      _realtimeService.sendTypingStatus(widget.conversationId, false);
    }
    
    super.dispose();
  }

  void _handleTextChange() {
    final hasText = _messageController.text.trim().isNotEmpty;
    
    print('🔤 TEXT CHANGE: hasText=$hasText, _isTyping=$_isTyping, text="${_messageController.text}"');
    
    if (hasText && !_isTyping) {
      // Start typing
      _isTyping = true;
      print('▶️ STARTING TYPING for conversation: ${widget.conversationId}');
      _realtimeService.sendTypingStatus(widget.conversationId, true);
    } else if (!hasText && _isTyping) {
      // Text was cleared, stop typing immediately
      _isTyping = false;
      _typingTimer?.cancel();
      print('⏹️ STOPPING TYPING (text cleared) for conversation: ${widget.conversationId}');
      _realtimeService.sendTypingStatus(widget.conversationId, false);
      return;
    }
    
    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        print('⏱️ STOPPING TYPING (timeout) for conversation: ${widget.conversationId}');
        _realtimeService.sendTypingStatus(widget.conversationId, false);
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    
    // Stop typing when sending message
    if (_isTyping) {
      _isTyping = false;
      _typingTimer?.cancel();
      _realtimeService.sendTypingStatus(widget.conversationId, false);
    }

    try {
      await ref
          .read(messagesProvider(widget.conversationId).notifier)
          .sendMessage(content: content);

      // Scroll to bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(messagesProvider(widget.conversationId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(messagesState.conversationTitle ?? 'Conversation'),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : messagesState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error: ${messagesState.error}',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                ref
                                    .read(messagesProvider(widget.conversationId).notifier)
                                    .loadMessages();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : messagesState.messages.isEmpty
                        ? const Center(
                            child: Text('Start the conversation by sending a message!'),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: messagesState.messages.length,
                            itemBuilder: (context, index) {
                              final message = messagesState.messages[index];
                              return _MessageBubble(
                                message: message,
                                isCurrentUser: message.senderId == currentUser?.userId,
                              );
                            },
                          ),
          ),
          
          // Typing indicator
          if (_typingUsers.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_typingUsers.length > 1 ? "Partners are" : "Partner is"} typing',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const _TypingAnimation(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Message input
          if (messagesState.isSending)
            const LinearProgressIndicator(),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                    onChanged: (text) {
                      debugPrint('🔤 onChanged triggered: "$text"');
                      // Don't call _handleTextChange here since the listener should handle it
                    },
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  child: IconButton(
                    onPressed: messagesState.isSending ? null : _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;

  const _MessageBubble({
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final isAI = message.senderType == MessageSenderType.ai;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isCurrentUser && !isAI
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser || isAI) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isAI 
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.primary,
              child: Icon(
                isAI ? Icons.psychology : Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrentUser && !isAI
                    ? Theme.of(context).colorScheme.primary
                    : isAI
                        ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
                        : Theme.of(context).colorScheme.outline.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser || isAI)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isAI ? Theme.of(context).colorScheme.secondary : null,
                        ),
                      ),
                    ),
                  
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isCurrentUser && !isAI
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.createdAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isCurrentUser && !isAI
                              ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      if (message.isEdited) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit,
                          size: 12,
                          color: isCurrentUser && !isAI
                              ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isCurrentUser && !isAI) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingAnimation extends StatefulWidget {
  const _TypingAnimation({Key? key}) : super(key: key);

  @override
  _TypingAnimationState createState() => _TypingAnimationState();
}

class _TypingAnimationState extends State<_TypingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final opacity = ((_animation.value + delay) % 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: AnimatedOpacity(
                opacity: opacity > 0.5 ? 1 - opacity : opacity,
                duration: const Duration(milliseconds: 100),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
