import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // holds whatever is typed in the search bar.
  final TextEditingController _searchChatController = TextEditingController();

  // reads the user list out of firestore.
  final ChatService _chatService = ChatService();

  // reads the saved login details from the device.
  final UserService _userService = UserService();

  // both are used to leave the logged in user out of their own chat list.
  String? _currentUserEmail;
  String? _currentUserId;

  // the lower cased text being searched for right now.
  String _searchText = '';

  // built once, so typing in the search bar does not reload the list.
  late final Stream<List<Map<String, dynamic>>> _usersStream;

  @override
  void initState() {
    super.initState();

    _usersStream = _chatService.getUsersStream();

    // the uid is ready right away, the email has to be read from storage.
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadCurrentUserEmail();
  }

  // loads the signed in email so it can be skipped in the list.
  Future<void> _loadCurrentUserEmail() async {
    final userData = await _userService.getUserData();

    // the screen may already be closed when this finishes.
    if (!mounted) return;
    setState(() {
      _currentUserEmail = userData['email'];
    });
  }

  @override
  void dispose() {
    _searchChatController.dispose();
    super.dispose();
  }

  // Enhancement 1: the logged in user should not see their own row.
  bool _isCurrentUser(Map<String, dynamic> user) {
    final uid = (user['uid'] ?? '').toString();
    final email = (user['email'] ?? '').toString().toLowerCase();

    // firebase logins are matched by uid.
    if (_currentUserId != null &&
        _currentUserId!.isNotEmpty &&
        uid == _currentUserId) {
      return true;
    }

    // the email is the fallback because a dummyjson login has no uid.
    if (_currentUserEmail != null &&
        _currentUserEmail!.isNotEmpty &&
        email == _currentUserEmail!.toLowerCase()) {
      return true;
    }

    return false;
  }

  // Enhancement 2: match the typed text against the name or the email.
  bool _matchesSearch(Map<String, dynamic> user) {
    // an empty search bar shows everyone.
    if (_searchText.isEmpty) return true;

    final firstName = (user['firstName'] ?? '').toString().toLowerCase();
    final lastName = (user['lastName'] ?? '').toString().toLowerCase();
    final username = (user['username'] ?? '').toString().toLowerCase();
    final email = (user['email'] ?? '').toString().toLowerCase();

    // a hit on any of the fields keeps the user in the list.
    return firstName.contains(_searchText) ||
        lastName.contains(_searchText) ||
        username.contains(_searchText) ||
        email.contains(_searchText);
  }

  // picks the best name a user document can offer.
  String _displayName(Map<String, dynamic> user) {
    final firstName = (user['firstName'] ?? '').toString().trim();
    final lastName = (user['lastName'] ?? '').toString().trim();

    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) return fullName;

    // older accounts may only have the username or the email saved.
    final username = (user['username'] ?? '').toString().trim();
    if (username.isNotEmpty) return username;

    final email = (user['email'] ?? '').toString().trim();
    if (email.isNotEmpty) return email;

    return 'Unknown';
  }

  // keeps the empty and error states looking the same.
  Widget _messageBox(String message) {
    return SizedBox(
      height: ScreenUtil().screenHeight * 0.6,
      child: Center(
        child: CustomText(
          text: message,
          fontSize: 16.sp,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 20.h),

          // Enhancement 2: search bar on top of the chat list.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 23.w),
            child: TextField(
              controller: _searchChatController,
              textInputAction: TextInputAction.search,
              // filters the list on every keystroke.
              onChanged: (value) {
                setState(() {
                  _searchText = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle: const TextStyle(fontFamily: 'Poppins'),
                filled: true,
                fillColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.colorScheme.primary,
                ),
                // the clear button only shows once something is typed.
                suffixIcon: (_searchChatController.text.isNotEmpty)
                    ? IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.cancel),
                        onPressed: () {
                          setState(() {
                            _searchChatController.clear();
                            _searchText = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),

          // Users Stream
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _usersStream,
            builder: (context, snapshot) {
              // still fetching the users.
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: ScreenUtil().screenHeight * 0.6,
                  child: const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _messageBox('Error loading users');
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _messageBox('No users found');
              }

              // Enhancement 1 and 2: drop myself, then apply the search.
              final users = snapshot.data!
                  .where((user) => !_isCurrentUser(user))
                  .where(_matchesSearch)
                  .toList();

              // the wording depends on whether a search is active.
              if (users.isEmpty) {
                return _messageBox(
                  _searchText.isEmpty
                      ? 'No other users yet...'
                      : 'No user matches that name or email',
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];

                  final name = _displayName(user);
                  final email = (user['email'] ?? '').toString();

                  // the avatar letter comes from whatever name was found.
                  final initial = name != 'Unknown'
                      ? name[0].toUpperCase()
                      : '?';

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: theme.colorScheme.outline),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      // opens the conversation with the tapped user.
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailsScreen(
                              currentUserEmail: _currentUserEmail ?? '',
                              tappedUser: user,
                            ),
                          ),
                        );
                      },
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        child: CustomText(
                          text: initial,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      title: CustomText(
                        text: name,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      subtitle: CustomText(
                        text: email.isNotEmpty ? email : 'No email',
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }
}
