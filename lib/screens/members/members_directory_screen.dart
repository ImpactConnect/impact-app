import 'package:church_mobile/models/member.dart';
import 'package:church_mobile/widgets/members/member_details_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MembersDirectoryScreen extends StatelessWidget {
  const MembersDirectoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Members Directory'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('members')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No members found'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final member = Member.fromFirestore(snapshot.data!.docs[index]);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: member.imageUrl != null
                        ? NetworkImage(member.imageUrl!)
                        : null,
                    child: member.imageUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(member.name),
                  subtitle: Text(member.occupation ?? 'Member'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => MemberDetailsDialog(member: member),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
