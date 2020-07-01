import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = Firestore.instance;
FirebaseUser loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = 'ChatScreen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  String messageText;
  final messageTextController = TextEditingController();

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) loggedInUser = user;
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      messageTextController.clear();
                      _firestore.collection("messages").add({
                        'text': messageText,
                        'sender': loggedInUser.email,
                        'timeStamp': FieldValue.serverTimestamp(),
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
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

class MessagesStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('messages')
            .orderBy('timeStamp', descending: true)
            .snapshots(),
        builder: (context, snapshots) {
          if (!snapshots.hasData) {
            return Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.lightBlueAccent,
              ),
            );
          }

          final messages = snapshots.data.documents;
          List<MessageBubble> messageBubble = [];
          for (var messages in messages) {
            final messageText = messages.data['text'];
            final messageSender = messages.data['sender'];
            final currentUser = loggedInUser.email;
            messageBubble.add(MessageBubble(
              sender: messageSender,
              text: messageText,
              isMe: currentUser == messageSender,
            ));
          }
          return Expanded(
              child: ListView(
            reverse: true,
            children: messageBubble,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          ));
        });
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final String sender;
  final bool isMe;

  MessageBubble({this.sender, this.text, this.isMe});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sender,
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
          Material(
            elevation: 5.0,
            borderRadius: BorderRadius.only(
                topLeft: isMe ? Radius.circular(15) : Radius.zero,
                topRight: isMe ? Radius.zero : Radius.circular(15),
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15)),
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  color: isMe ? Colors.white : Colors.black54,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 2,
          ),
//          Text(
//            '${DateTime.now().hour}:${DateTime.now().minute}',
//            style: TextStyle(fontSize: 8, color: Colors.black45),
//          )
        ],
      ),
    );
  }
}
