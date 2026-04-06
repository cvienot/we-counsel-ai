import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/conversation_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/active_exercise_banner.dart';
import '../../services/exercise_service.dart';
import '../../services/api_service.dart';
import '../../services/realtime_service.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/ctrl_enter_submit.dart';
import 'dart:async';

class MainThreadScreen extends ConsumerStatefulWidget {
  const MainThreadScreen({super.key});

  @override
  ConsumerState<MainThreadScreen> createState() => _MainThreadScreenState();
}

class _MainThreadScreenState extends ConsumerState<MainThreadScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _realtimeService = RealtimeService();
  late final FocusNode _messageFocusNode;
  final _exerciseService = ExerciseService();
  
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;
  Timer? _typingTimer;
  Timer? _typingHeartbeat;
  Timer? _exercisePollTimer;
  Set<String> _typingUsers = {};
  bool _isTyping = false;

  // Active exercise state
  Map<String, dynamic>? _activeExerciseSession;
  Map<String, dynamic>? _activeExerciseData;
  bool _isCurrentUsersTurnForExercise = false;
  String? _exerciseWaitingForName;

  @override
  void initState() {
    super.initState();
    debugPrint('🏠 MainThreadScreen initState called');
    _messageFocusNode = CtrlEnterSubmit.createFocusNode(_sendMessage);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMainThread();
    });
    
    // Listen to typing events
    _typingSubscription = _realtimeService.typingStream.listen((data) {
      debugPrint('👂 MAIN THREAD - Received typing event: $data');
      // We'll set up conversation ID filtering once we have the main thread loaded
      setState(() {
        if (data['isTyping'] == true) {
          _typingUsers.add(data['userId']);
        } else {
          _typingUsers.remove(data['userId']);
        }
      });
    });
    
    // Listen to text changes to send typing status
    debugPrint('🎹 MAIN THREAD - Adding text controller listener');
    _messageController.addListener(() {
      debugPrint('🎹 MAIN THREAD - Text controller listener triggered - text: "${_messageController.text}"');
      _handleTextChange();
    });
    
    debugPrint('🏠 MainThreadScreen initState completed');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    _typingHeartbeat?.cancel();
    _exercisePollTimer?.cancel();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    
    // Stop typing when leaving the screen
    if (_isTyping) {
      final mainThread = ref.read(mainThreadProvider).mainThread;
      if (mainThread != null) {
        _realtimeService.sendTypingStatus(mainThread.conversationId, false);
      }
    }
    
    super.dispose();
  }

  void _handleTextChange() {
    debugPrint('🔤 MAIN THREAD - _handleTextChange called at ${DateTime.now()}');
    final hasText = _messageController.text.trim().isNotEmpty;
    final mainThread = ref.read(mainThreadProvider).mainThread;
    
    if (mainThread == null) {
      debugPrint('❌ MAIN THREAD - No main thread available for typing status');
      return;
    }
    
    debugPrint('🔤 MAIN THREAD - TEXT CHANGE: hasText=$hasText, _isTyping=$_isTyping, text="${_messageController.text}"');
    
    if (hasText && !_isTyping) {
      // Start typing
      _isTyping = true;
      debugPrint('▶️ MAIN THREAD - STARTING TYPING for conversation: ${mainThread.conversationId}');
      _realtimeService.sendTypingStatus(mainThread.conversationId, true);
      
      // Start heartbeat to keep typing status alive
      _startTypingHeartbeat(mainThread.conversationId);
      
    } else if (!hasText && _isTyping) {
      // Text was cleared, stop typing immediately
      _isTyping = false;
      _typingTimer?.cancel();
      _typingHeartbeat?.cancel();
      debugPrint('⏹️ MAIN THREAD - STOPPING TYPING (text cleared) for conversation: ${mainThread.conversationId}');
      _realtimeService.sendTypingStatus(mainThread.conversationId, false);
      return;
    }
    
    // Cancel any existing timer since we want typing to persist as long as there's text
    _typingTimer?.cancel();
    
    // Only set a timeout if there's text (as a fallback in case of network issues)
    if (hasText) {
      _typingTimer = Timer(const Duration(seconds: 15), () {
        if (_isTyping && mainThread != null) {
          _isTyping = false;
          _typingHeartbeat?.cancel();
          debugPrint('⏱️ MAIN THREAD - STOPPING TYPING (fallback timeout) for conversation: ${mainThread.conversationId}');
          _realtimeService.sendTypingStatus(mainThread.conversationId, false);
        }
      });
    }
  }

  void _startTypingHeartbeat(String conversationId) {
    _typingHeartbeat?.cancel();
    _typingHeartbeat = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isTyping && _messageController.text.trim().isNotEmpty) {
        debugPrint('💓 MAIN THREAD - TYPING HEARTBEAT for conversation: $conversationId');
        _realtimeService.sendTypingStatus(conversationId, true);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadMainThread() async {
    await ref.read(mainThreadProvider.notifier).loadMainThread();
    final mainThread = ref.read(mainThreadProvider).mainThread;
    
    if (mainThread != null) {
      // Load messages for the main thread
      await ref.read(messagesProvider(mainThread.conversationId).notifier).loadMessages();
      // Scroll to bottom after messages are loaded
      _scrollToBottom();
      // Check for active exercise
      _checkActiveExercise(mainThread.conversationId);
      // Poll for exercise changes every 15 seconds
      _startExercisePolling(mainThread.conversationId);
    }
  }

  void _startExercisePolling(String conversationId) {
    _exercisePollTimer?.cancel();
    _exercisePollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkActiveExercise(conversationId);
    });
  }

  Future<void> _checkActiveExercise(String conversationId) async {
    try {
      final token = await ApiService().getToken();
      if (token == null || token.isEmpty) return;

      final result = await _exerciseService.getActiveSession(
        token: token,
        conversationId: conversationId,
      );

      if (!mounted) return;

      if (result == null) {
        // No active exercise
        if (_activeExerciseSession != null) {
          setState(() {
            _activeExerciseSession = null;
            _activeExerciseData = null;
            _isCurrentUsersTurnForExercise = false;
            _exerciseWaitingForName = null;
          });
        }
        return;
      }

      final session = result['session'] as Map<String, dynamic>;
      final exercise = result['exercise'] as Map<String, dynamic>?;
      final status = session['status'] as String? ?? '';

      if (status != 'active') {
        // Session is not active (completed/abandoned)
        if (_activeExerciseSession != null) {
          setState(() {
            _activeExerciseSession = null;
            _activeExerciseData = null;
            _isCurrentUsersTurnForExercise = false;
            _exerciseWaitingForName = null;
          });
        }
        return;
      }

      // Determine whose turn it is
      final currentStep = exercise?['currentStep'] as Map<String, dynamic>?;
      final prompt = currentStep?['prompt'] as String? ?? '';
      final authState = ref.read(authProvider);
      final currentUserFirstName = authState.user?.firstName ?? '';

      final isMyTurn = prompt.isNotEmpty &&
          currentUserFirstName.isNotEmpty &&
          (prompt.startsWith('$currentUserFirstName,') ||
              prompt.startsWith('$currentUserFirstName '));

      // Extract the other partner's name from the prompt
      String? waitingForName;
      if (!isMyTurn && prompt.isNotEmpty) {
        // The prompt starts with the partner's name
        final commaIdx = prompt.indexOf(',');
        final spaceIdx = prompt.indexOf(' ');
        final nameEnd = commaIdx > 0 ? commaIdx : (spaceIdx > 0 ? spaceIdx : prompt.length);
        waitingForName = prompt.substring(0, nameEnd);
      }

      setState(() {
        _activeExerciseSession = session;
        _activeExerciseData = exercise;
        _isCurrentUsersTurnForExercise = isMyTurn;
        _exerciseWaitingForName = waitingForName;
      });
    } catch (e) {
      debugPrint('⚠️ Error checking active exercise: $e');
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final mainThread = ref.read(mainThreadProvider).mainThread;
    if (mainThread == null) return;

    _messageController.clear();
    
    // Stop typing when sending message
    if (_isTyping) {
      _isTyping = false;
      _typingTimer?.cancel();
      _typingHeartbeat?.cancel();
      debugPrint('⏹️ MAIN THREAD - STOPPING TYPING (message sent) for conversation: ${mainThread.conversationId}');
      _realtimeService.sendTypingStatus(mainThread.conversationId, false);
    }

    try {
      await ref
          .read(messagesProvider(mainThread.conversationId).notifier)
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
        showErrorSnackBar(context, AppLocalizations.of(context)!.errorSendingMessage);
      }
    }
  }

  String _getLocalizedTitle(String title, AppLocalizations l10n) {
    // Check if it's the default English title from backend
    if (title == 'Main Conversation') {
      // Changed to "We Coach" instead of localized version
      return 'We Coach';
    }
    return title;
  }

  String _getLocalizedTopic(String topic, AppLocalizations l10n) {
    // Check if it's the default English topic from backend
    if (topic == 'Your ongoing journey together') {
      return l10n.mainConversationTopic;
    }
    return topic;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasPartner = ref.watch(hasPartnerProvider);
    final mainThreadState = ref.watch(mainThreadProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Show waiting room if no partner
    if (!hasPartner) {
      return const _WaitingRoomScreen();
    }

    // Show loading while fetching main thread
    if (mainThreadState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show error if failed to load main thread
    if (mainThreadState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.failedToLoad,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                mainThreadState.error!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadMainThread,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    final mainThread = mainThreadState.mainThread;
    if (mainThread == null) {
      return Scaffold(
        body: Center(child: Text(l10n.failedToLoad)),
      );
    }

    final messagesState = ref.watch(messagesProvider(mainThread.conversationId));

    // Auto-scroll when messages are loaded or streaming content arrives
    ref.listen<MessagesState>(messagesProvider(mainThread.conversationId), (previous, next) {
      // Scroll to bottom when messages are first loaded
      if (previous == null && next.messages.isNotEmpty && !next.isLoading) {
        _scrollToBottom();
      }
      // Scroll to bottom when new streaming content arrives
      else if (previous != null && next.streamingMessages.isNotEmpty) {
        _scrollToBottom();
      }
      // Scroll to bottom when new messages are added
      else if (previous != null && next.messages.length > previous.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getLocalizedTitle(mainThread.title, l10n)),
            if (mainThread.topic.isNotEmpty)
              Text(
                _getLocalizedTopic(mainThread.topic, l10n),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
          ],
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              // TODO: Re-enable when needed
              // PopupMenuItem(
              //   onTap: () => context.push('/conversations'),
              //   child: Row(
              //     children: [
              //       const Icon(Icons.forum),
              //       const SizedBox(width: 8),
              //       Text(l10n.otherConversations),
              //     ],
              //   ),
              // ),
              PopupMenuItem(
                onTap: () => context.push('/profile'),
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Text(l10n.profile),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () => context.push('/language'),
                child: Row(
                  children: [
                    const Icon(Icons.language),
                    const SizedBox(width: 8),
                    Text(l10n.language),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.logout),
                    const SizedBox(width: 8),
                    Text(l10n.logout),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: Column(
        children: [
          // Welcome message for main thread
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.welcomeTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.welcomeMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),

          // Active exercise banner
          if (_activeExerciseSession != null)
            ActiveExerciseBanner(
              exerciseName: _activeExerciseData?['name'] as String? ?? 'Exercise',
              currentStep: _activeExerciseSession!['currentStep'] as int? ?? 1,
              totalSteps: (_activeExerciseData?['steps'] as List?)?.length ?? 1,
              isCurrentUsersTurn: _isCurrentUsersTurnForExercise,
              waitingForName: _exerciseWaitingForName,
              onJoin: () {
                context.push('/exercise', extra: {
                  'conversationId': mainThread.conversationId,
                  'exerciseId': _activeExerciseSession!['exerciseId'] as String,
                }).then((_) {
                  // Refresh exercise state and messages when returning
                  _checkActiveExercise(mainThread.conversationId);
                  ref.read(messagesProvider(mainThread.conversationId).notifier).loadMessages();
                });
              },
            ),

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
                              AppLocalizations.of(context)!.errorLoadingMessages,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                ref.read(messagesProvider(mainThread.conversationId).notifier).loadMessages();
                              },
                              child: Text(AppLocalizations.of(context)!.retry),
                            ),
                          ],
                        ),
                      )
                    : messagesState.messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.startYourConversation,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.shareThoughts,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: messagesState.messages.length + messagesState.streamingMessageIds.length,
                            itemBuilder: (context, index) {
                              // Show regular messages first
                              if (index < messagesState.messages.length) {
                                final message = messagesState.messages[index];
                                final mainThread = ref.read(mainThreadProvider).mainThread;
                                return MessageBubble(
                                  message: message,
                                  isCurrentUser: message.senderId == currentUser?.userId,
                                  onExerciseSuggestion: mainThread != null ? (exerciseId) {
                                    // Navigate to exercise screen
                                    context.push('/exercise', extra: {
                                      'conversationId': mainThread.conversationId,
                                      'exerciseId': exerciseId,
                                    });
                                  } : null,
                                );
                              }
                              
                              // Show streaming messages
                              final streamingIndex = index - messagesState.messages.length;
                              final streamingIds = messagesState.streamingMessageIds.toList();
                              if (streamingIndex < streamingIds.length) {
                                final messageId = streamingIds[streamingIndex];
                                final streamingContent = messagesState.streamingMessages[messageId] ?? '';
                                
                                return _StreamingMessageBubble(
                                  content: streamingContent,
                                  isStreaming: true,
                                );
                              }
                              
                              return const SizedBox.shrink();
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
                          _typingUsers.length > 1 ? l10n.partnersTyping : l10n.partnerTyping,
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    decoration: InputDecoration(
                      hintText: l10n.typeMessage,
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
                      debugPrint('🔤 MAIN THREAD - onChanged triggered: "$text"');
                      // Don't call _handleTextChange here since the listener should handle it
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: messagesState.isSending ? null : _sendMessage,
                  mini: true,
                  child: messagesState.isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _WaitingRoomScreen extends ConsumerWidget {
  const _WaitingRoomScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () => context.push('/profile'),
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Text(l10n.profile),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () => context.push('/language'),
                child: Row(
                  children: [
                    const Icon(Icons.language),
                    const SizedBox(width: 8),
                    Text(l10n.language),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.logout),
                    const SizedBox(width: 8),
                    Text(l10n.logout),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 32),
            Text(
              l10n.waitingForPartnerTitle,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.waitingRoomGreeting(user?.firstName ?? 'there'),
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.whatHappensNext,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.partnerInvitationMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push('/invite'),
              icon: const Icon(Icons.email),
              label: Text(l10n.sendAnotherInvitation),
            ),
          ],
        ),
      ),
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

class _StreamingMessageBubble extends StatelessWidget {
  final String content;
  final bool isStreaming;

  const _StreamingMessageBubble({
    required this.content,
    required this.isStreaming,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
        right: 48.0, // Add margin to keep AI messages from right edge
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: const Icon(
              Icons.psychology,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    AppLocalizations.of(context)!.drSarahAiCounsellor,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.70,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18).copyWith(
                      bottomLeft: const Radius.circular(4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (content.isNotEmpty)
                        Text(
                          content,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      if (isStreaming) ...[
                        if (content.isNotEmpty) const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.typing,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const _TypingAnimation(),
                          ],
                        ),
                      ],
                    ],
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
