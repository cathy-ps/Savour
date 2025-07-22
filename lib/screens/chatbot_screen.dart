import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import '../providers/home_search_provider.dart';
import '../widgets/recipe_card_for_bot.dart';
import 'recipe_detail.dart';
import '../services/gemini_service.dart';
import '../models/recipe_model.dart';
//import 'package:savourai/screens/recipe_detail.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final List<ChatMessage> _messages = [];
  bool _loading = false;
  List<Recipe> _lastRecipes = [];

  void _handleSend(String text) async {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _loading = true;
    });

    // Simple check: if user input contains commas, treat as ingredients
    if (text.contains(',')) {
      await ref.read(homeSearchProvider.notifier).searchRecipes(text);
      final recipes = ref.read(homeSearchProvider).recipes;
      setState(() {
        _lastRecipes = recipes;
        _messages.add(
          ChatMessage(
            text: recipes.isNotEmpty
                ? 'Here are some recipes you can make!'
                : 'Sorry, I could not find any recipes.',
            isUser: false,
          ),
        );
        _loading = false;
      });
    } else {
      // Otherwise, treat as a question for GeminiService
      final gemini = GeminiService();
      final response = await gemini.getCookingTipOrAnswer(text);
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        // Do NOT clear _lastRecipes; keep the grid visible
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SavourAI Assistant')),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return Align(
                        alignment: msg.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: msg.isUser
                                ? Colors.blue[100]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(msg.text),
                        ),
                      );
                    },
                  ),
                ),
                if (_lastRecipes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: _lastRecipes.length,
                      itemBuilder: (context, i) {
                        final recipe = _lastRecipes[i];
                        return RecipeCardForBot(
                          recipe: recipe,
                          imageUrl: recipe.imageUrl,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => RecipeDetailScreen(
                                  recipe: recipe,
                                  recipeId: recipe.id,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          ChatInputBar(
            onSend: _handleSend,
            hintText: 'Type ingredients (comma separated) or ask a question...',
          ),
        ],
      ),
    );
  }
}

class ChatInputBar extends StatefulWidget {
  final void Function(String) onSend;
  final String hintText;
  const ChatInputBar({required this.onSend, this.hintText = '', Key? key})
    : super(key: key);

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          IconButton(icon: const Icon(Icons.send), onPressed: _submit),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}
