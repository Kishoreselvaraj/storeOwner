import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        leading: TextButton(
          onPressed: () {},
          child: const Text(
            "Edit",
            style: TextStyle(color: Colors.orange, fontSize: 16),
          ),
        ),
        title: const Text(
          "Chats",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.orange),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  hintText: "Search",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // ✅ Chat List
          Expanded(
            child: ListView(
              children: [
                chatTile("Haley James", "Stand up for what you believe in", 9),
                chatTile("Nathan Scott",
                    "One day you're seventeen and planning for someday...", 0),
                chatTile("Brooke Davis", "I am who I am. No excuses.", 2),
                chatTile("Jamie Scott",
                    "Some people are a little different. I think that's cool.",
                    0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget chatTile(String name, String message, int unreadCount) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.orange.shade200,
        child: const Icon(Icons.person, color: Colors.white),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: unreadCount > 0
          ? Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
          : null,
    );
  }
}
