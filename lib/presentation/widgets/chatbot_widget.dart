import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// Simple chatbot provider for state management
final chatMessagesProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier();
});

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([]);

  void addMessage(String text, bool isUser) {
    state = [...state, ChatMessage(text: text, isUser: isUser, timestamp: DateTime.now())];
    
    // Auto-reply for bot messages
    if (!isUser) return;
    
    // Simulate bot thinking
    Future.delayed(const Duration(milliseconds: 500), () {
      _getBotResponse(text);
    });
  }

  void _getBotResponse(String userMessage) {
    String response;
    final lowerMsg = userMessage.toLowerCase();
    
    if (lowerMsg.contains('hello') || lowerMsg.contains('hi')) {
      response = "Hello! How can I help you with your finances today?";
    } else if (lowerMsg.contains('balance') || lowerMsg.contains('money')) {
      response = "You can check your balance on the Dashboard. It shows your total income, expenses, and current balance.";
    } else if (lowerMsg.contains('expense') || lowerMsg.contains('spent')) {
      response = "To add an expense, go to Transactions tab and click the + button. Then select 'Expense' and fill in the details.";
    } else if (lowerMsg.contains('income')) {
      response = "To add income, go to Transactions tab and click the + button. Then select 'Income' and fill in the details.";
    } else if (lowerMsg.contains('category')) {
      response = "Categories help organize your transactions. Default categories include Food, Transport, Housing, Entertainment, and Shopping.";
    } else if (lowerMsg.contains('export') || lowerMsg.contains('csv')) {
      response = "You can export your transactions as CSV from the Settings page. Just tap on 'Export financial summary'.";
    } else if (lowerMsg.contains('help')) {
      response = "I can help you with:\n- Checking balances\n- Adding transactions\n- Understanding categories\n- Exporting data\n- Budgeting tips\n\nWhat would you like to know?";
    } else {
      response = "Thanks for your message! You can check your Dashboard for analytics or add transactions from the Transactions tab. Need help with anything specific?";
    }
    
    state = [...state, ChatMessage(text: response, isUser: false, timestamp: DateTime.now())];
  }

  void clearMessages() {
    state = [];
  }
}

class ChatbotWidget extends ConsumerStatefulWidget {
  const ChatbotWidget({super.key});

  @override
  ConsumerState<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends ConsumerState<ChatbotWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isChatOpen = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    // Fix: Use .notifier to access methods
    ref.read(chatMessagesProvider.notifier).addMessage(text, true);
    _messageController.clear();
    
    // Scroll to bottom after message
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Fix: Properly watch the provider
    final messages = ref.watch(chatMessagesProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Floating Action Button
        if (!_isChatOpen)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isChatOpen = true;
                });
              },
              backgroundColor: Colors.orange,
              child: const Icon(Icons.chat, color: Colors.white),
            ),
          ),
        
        // Chat Popup
        if (_isChatOpen)
          Positioned(
            bottom: 20,
            right: 20,
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.7,
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 600,
                  minWidth: 300,
                  minHeight: 400,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber, Colors.deepOrange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.chat_bubble, color: Colors.orange.shade600, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Finance Assistant',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Online',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _isChatOpen = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Messages
                    Expanded(
                      child: messages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 50,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Ask me anything about your finances!',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try: "How do I add an expense?"',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                return _buildMessageBubble(message, isDarkMode);
                              },
                            ),
                    ),
                    
                    // Input Field
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                hintText: 'Type your message...',
                                hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey.shade600),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white, size: 20),
                              onPressed: _sendMessage,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDarkMode) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: message.isUser
              ? Colors.orange
              : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: message.isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser
                    ? Colors.white
                    : (isDarkMode ? Colors.white : Colors.black),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: message.isUser
                    ? Colors.white70
                    : (isDarkMode ? Colors.white54 : Colors.grey.shade600),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}