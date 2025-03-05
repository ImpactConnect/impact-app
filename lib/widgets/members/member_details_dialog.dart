import 'package:church_mobile/models/member.dart';
import 'package:flutter/material.dart';

class MemberDetailsDialog extends StatelessWidget {
  const MemberDetailsDialog({Key? key, required this.member}) : super(key: key);
  final Member member;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                image: member.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(member.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: member.imageUrl == null
                  ? const Center(
                      child: Icon(Icons.person, size: 100, color: Colors.grey),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                      Icons.work, member.occupation ?? 'Not specified'),
                  _buildInfoRow(Icons.favorite,
                      member.maritalStatus?.toString() ?? 'Not specified'),
                  if (member.spouseName != null)
                    _buildInfoRow(Icons.people, 'Spouse: ${member.spouseName}'),
                  _buildInfoRow(
                      Icons.cake,
                      member.birthDate != null
                          ? _formatDate(member.birthDate!)
                          : 'Not specified'),
                  if (member.weddingDate != null)
                    _buildInfoRow(Icons.celebration,
                        'Anniversary: ${_formatDate(member.weddingDate!)}'),
                  _buildInfoRow(
                      Icons.phone, member.phoneNumber ?? 'No phone number'),
                  _buildInfoRow(Icons.email, member.email ?? 'No email'),
                  _buildInfoRow(
                      Icons.location_on, member.address ?? 'No address'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
