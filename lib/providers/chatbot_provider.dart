import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe_model.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatbotState {
  final List<ChatMessage> messages;
  final List<Recipe> lastRecipes;
  final bool isLoading;

  ChatbotState({
    this.messages = const [],
    this.lastRecipes = const [],
    this.isLoading = false,
  });

  ChatbotState copyWith({
    List<ChatMessage>? messages,
    List<Recipe>? lastRecipes,
    bool? isLoading,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      lastRecipes: lastRecipes ?? this.lastRecipes,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatbotNotifier extends StateNotifier<ChatbotState> {
  ChatbotNotifier() : super(ChatbotState());

  void addMessage(String text, bool isUser) {
    final newMessage = ChatMessage(text: text, isUser: isUser);
    state = state.copyWith(messages: [...state.messages, newMessage]);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setLastRecipes(List<Recipe> recipes) {
    state = state.copyWith(lastRecipes: recipes);
  }

  void clearLastRecipes() {
    state = state.copyWith(lastRecipes: []);
  }
}

final chatbotProvider = StateNotifierProvider<ChatbotNotifier, ChatbotState>((
  ref,
) {
  return ChatbotNotifier();
});
