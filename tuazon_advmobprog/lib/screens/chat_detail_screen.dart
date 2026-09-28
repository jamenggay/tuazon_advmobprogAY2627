import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../widgets/custom_text.dart';

final ChatService chatService = ChatService();

class ChatDetailsScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailsScreen({
    super.key,
    required this.currentUserEmail,
    required this.tappedUser,
  });

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  // holds the message being typed.
  final TextEditingController _msgCtrl = TextEditingController();

  // keeps the keyboard open after a send.
  final FocusNode _msgFocus = FocusNode();

  // used to jump back to the newest message.
  final ScrollController _scrollCtrl = ScrollController();

  // the uid firebase stamps on every message this user sends.
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // true only while the send button is waiting on firestore.
  bool _isSending = false;

  // built once, because a new stream on every rebuild would restart the list.
  late final Stream<QuerySnapshot> _messagesStream;

  // the uid of the person being chatted with.
  String get _tappedUserId => (widget.tappedUser['uid'] ?? '').toString();

  // falls back through the name, the username, then the email.
  String get _tappedUserName {
    final firstName = (widget.tappedUser['firstName'] ?? '').toString().trim();
    final lastName = (widget.tappedUser['lastName'] ?? '').toString().trim();

    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) return fullName;

    final username = (widget.tappedUser['username'] ?? '').toString().trim();
    if (username.isNotEmpty) return username;

    final email = (widget.tappedUser['email'] ?? '').toString().trim();
    return email.isNotEmpty ? email : 'Chat';
  }

  @override
  void initState() {
    super.initState();

    _messagesStream = chatService.getMessage(_currentUserId, _tappedUserId);

    // opening the chat means the other user's messages have been read.
    _markAsSeen();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _markAsSeen() async {
    try {
      await chatService.markMessagesAsSeen(_tappedUserId);
    } catch (_) {
      // seen receipts are optional, a failure should not break the chat.
    }
  }

  // sends whatever is in the composer.
  Future<void> _send() async {
    final text = _msgCtrl.text.trim();

    // nothing to send, or a send is already running.
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    // clear right away so the composer feels responsive.
    _msgCtrl.clear();
    _msgFocus.requestFocus();

    try {
      await chatService.sendMessage(_tappedUserId, text);

      // the list is reversed so offset zero is the newest message.
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        // put the text back so nothing is lost.
        _msgCtrl.text = text;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // turns a firestore timestamp into a short 12 hour time.
  String _formatTime(Object? value) {
    // a brand new message has no server timestamp yet.
    if (value is! Timestamp) return '';

    final date = value.toDate();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onAppBar = theme.appBarTheme.foregroundColor ?? Colors.white;

    // first letter of the name for the app bar avatar.
    final initial = _tappedUserName.isNotEmpty
        ? _tappedUserName[0].toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: onAppBar.withValues(alpha: 0.2),
              child: CustomText(
                text: initial,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: onAppBar,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    text: _tappedUserName,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: onAppBar,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  CustomText(
                    text: (widget.tappedUser['email'] ?? '').toString(),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w300,
                    color: onAppBar.withValues(alpha: 0.8),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // the messages take the space the composer does not use.
          Expanded(child: _buildMessageList(theme)),
          _buildComposer(theme),
        ],
      ),
    );
  }

  // live list of the messages in this conversation.
  Widget _buildMessageList(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        if (snapshot.hasError) {
          return Center(
            child: CustomText(
              text: 'Error loading messages',
              fontSize: 15.sp,
              textAlign: TextAlign.center,
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        // nothing has been sent between the two users yet.
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 48.sp,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(height: 10.h),
                CustomText(
                  text: 'Say hello to $_tappedUserName',
                  fontSize: 15.sp,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollCtrl,
          // newest message sits at the bottom.
          reverse: true,
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            // decides which side the bubble goes on.
            final isMe = (data['senderId'] ?? '').toString() == _currentUserId;

            // a message still on its way to firestore has a pending write.
            final isPending = doc.metadata.hasPendingWrites;

            return _buildBubble(
              theme: theme,
              key: ValueKey(doc.id),
              message: (data['message'] ?? '').toString(),
              time: _formatTime(data['timestamp']),
              isMe: isMe,
              isPending: isPending,
              isSeen: data['seen'] == true,
            );
          },
        );
      },
    );
  }

  // one chat bubble that fades and slides into place.
  Widget _buildBubble({
    required ThemeData theme,
    required Key key,
    required String message,
    required String time,
    required bool isMe,
    required bool isPending,
    required bool isSeen,
  }) {
    // my bubbles use the brand color, theirs use the card color.
    final bubbleColor = isMe
        ? theme.colorScheme.primary
        : (theme.cardTheme.color ?? theme.colorScheme.surface);

    // a null color lets the theme pick the normal text color.
    final textColor = isMe ? theme.colorScheme.onPrimary : null;

    // the time and the checkmarks sit lighter than the message.
    final footerColor = isMe
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.75)
        : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return TweenAnimationBuilder<double>(
      key: key,
      // fade and slide in over a short, gentle curve.
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            // new bubbles slide in from the side they belong to.
            offset: Offset((isMe ? 40 : -40) * (1 - value), 0),
            child: child,
          ),
        );
      },
      // the finished bubble, built once and reused by the animation.
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 6.w),
            padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 13.w),
            // a long message stops at three quarters of the screen.
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              border: isMe
                  ? null
                  : Border.all(color: theme.colorScheme.outline),
              // the squared-off corner points at whoever sent it.
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  text: message.isNotEmpty ? message : '[empty]',
                  fontSize: 15.sp,
                  color: textColor,
                  textAlign: TextAlign.left,
                ),
                SizedBox(height: 3.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      // "sending..." stands in for the time until it lands.
                      text: isMe && isPending ? 'sending...' : time,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w300,
                      color: footerColor,
                    ),
                    // only my own messages show a delivery status.
                    if (isMe) ...[
                      SizedBox(width: 4.w),
                      _buildStatusIcon(
                        theme: theme,
                        isPending: isPending,
                        isSeen: isSeen,
                        footerColor: footerColor,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // clock while sending, one check when delivered, two checks once seen.
  Widget _buildStatusIcon({
    required ThemeData theme,
    required bool isPending,
    required bool isSeen,
    required Color footerColor,
  }) {
    late final IconData icon;
    late final Color color;

    if (isPending) {
      icon = Icons.access_time;
      color = footerColor;
    } else if (isSeen) {
      icon = Icons.done_all;
      color = theme.colorScheme.secondary;
    } else {
      icon = Icons.done;
      color = footerColor;
    }

    // swapping the icon crossfades instead of popping.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Icon(
        icon,
        key: ValueKey(icon),
        size: 13.sp,
        color: color,
      ),
    );
  }

  // the text field and send button at the bottom.
  Widget _buildComposer(ThemeData theme) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 8.h),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outline),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                focusNode: _msgFocus,
                textInputAction: TextInputAction.send,
                minLines: 1,
                maxLines: 4,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(fontFamily: 'Poppins'),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12.h,
                    horizontal: 16.w,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),

            // listening here keeps the typing from rebuilding the messages.
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _msgCtrl,
              builder: (context, value, child) {
                // the button grows in once there is something to send.
                return AnimatedScale(
                  scale: value.text.trim().isEmpty ? 0.85 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: child,
                );
              },
              child: Material(
                color: theme.colorScheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _send,
                  child: Padding(
                    padding: EdgeInsets.all(11.sp),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isSending
                          ? SizedBox(
                              key: const ValueKey('sending'),
                              height: 20.sp,
                              width: 20.sp,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : Icon(
                              Icons.send,
                              key: const ValueKey('send'),
                              size: 20.sp,
                              color: theme.colorScheme.onPrimary,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
