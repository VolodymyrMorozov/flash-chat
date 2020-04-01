import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = Firestore.instance;
FirebaseUser loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';
  static const String messagesCollectionName = 'messages';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final textEditingController = TextEditingController();

  String messageText;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (ex) {
      print(ex);
    }
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
                try {
                  _auth.signOut();
                } catch (ex) {
                  print(ex);
                }
                Navigator.pushNamed(context, WelcomeScreen.id);
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
                      controller: textEditingController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      textEditingController.clear();
                      try {
                        if (messageText.isNotEmpty) {
                          _firestore
                              .collection(ChatScreen.messagesCollectionName)
                                ..add({
                                  'text': messageText,
                                  'sender': loggedInUser.email,
                                  'timeStampUTC':
                                      DateTime.now().millisecondsSinceEpoch
                                });
                          messageText = '';
                        }
                      } catch (ex) {
                        print(ex);
                      }
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
          .collection(ChatScreen.messagesCollectionName)
          .orderBy("timeStampUTC")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
              child: CircularProgressIndicator(
            backgroundColor: Colors.lightBlueAccent,
          ));
        }
        List<MessageBubble> messageBubbles = [];
        final messages = snapshot.data.documents.reversed;
        for (var message in messages) {
          messageBubbles.add(
            MessageBubble(
                text: message.data['text'], sender: message.data['sender']),
          );
        }
        return Expanded(
          child: ListView(
            reverse: true,
            children: messageBubbles,
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String sender;
  final String text;
  MessageBubble({this.sender, this.text});

  @override
  Widget build(BuildContext context) {
    if (loggedInUser == null) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: loggedInUser.email == sender
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sender,
            style: TextStyle(color: Colors.black54, fontSize: 12.0),
          ),
          Material(
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30.0),
                  bottomRight: Radius.circular(30.0),
                  topLeft: Radius.circular(
                      loggedInUser.email == sender ? 30.0 : 0.0),
                  topRight: Radius.circular(
                      loggedInUser.email == sender ? 0.0 : 30.0)),
              elevation: 5.0,
              color: loggedInUser.email == sender
                  ? Colors.lightBlueAccent
                  : Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 20.0),
                child: Text(text,
                    style: TextStyle(
                        fontSize: 15.0,
                        color: loggedInUser.email == sender
                            ? Colors.white
                            : Colors.black54)),
              )),
        ],
      ),
    );
  }
}
