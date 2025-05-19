import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/poll.dart';

class PollService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new poll
  Future<Poll> createPoll(Poll poll) async {
    try {
      DocumentReference docRef = await _firestore.collection('polls').add(poll.toMap());
      DocumentSnapshot doc = await docRef.get();
      return Poll.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to create poll: $e');
    }
  }

  // Get all polls
  Stream<List<Poll>> getPolls() {
    return _firestore
        .collection('polls')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Poll.fromFirestore(doc)).toList();
    });
  }

  // Get active polls
  Stream<List<Poll>> getActivePolls() {
    DateTime now = DateTime.now();
    return _firestore
        .collection('polls')
        .where('startDate', isLessThanOrEqualTo: now)
        .where('endDate', isGreaterThanOrEqualTo: now)
        .where('isActive', isEqualTo: true)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Poll.fromFirestore(doc)).toList();
    });
  }

  // Get poll by ID
  Future<Poll> getPoll(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('polls').doc(id).get();
      return Poll.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get poll: $e');
    }
  }

  // Update poll
  Future<void> updatePoll(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('polls').doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update poll: $e');
    }
  }

  // Delete poll
  Future<void> deletePoll(String id) async {
    try {
      await _firestore.collection('polls').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete poll: $e');
    }
  }

  // Vote on a poll option
  Future<void> vote(String pollId, String optionId, String userId) async {
    try {
      // Get the poll
      DocumentSnapshot doc = await _firestore.collection('polls').doc(pollId).get();
      Poll poll = Poll.fromFirestore(doc);

      // Check if user has already voted
      for (PollOption option in poll.options) {
        if (option.votedBy.contains(userId)) {
          throw Exception('User has already voted on this poll');
        }
      }

      // Update the poll with the new vote
      await _firestore.collection('polls').doc(pollId).update({
        'options': poll.options.map((option) {
          if (option.id == optionId) {
            return {
              ...option.toMap(),
              'votes': option.votes + 1,
              'votedBy': [...option.votedBy, userId],
            };
          }
          return option.toMap();
        }).toList(),
      });
    } catch (e) {
      throw Exception('Failed to vote: $e');
    }
  }

  // Add comment to poll
  Future<void> addComment(String pollId, PollComment comment) async {
    try {
      await _firestore.collection('polls').doc(pollId).update({
        'comments': FieldValue.arrayUnion([comment.toMap()]),
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Delete comment from poll
  Future<void> deleteComment(String pollId, PollComment comment) async {
    try {
      await _firestore.collection('polls').doc(pollId).update({
        'comments': FieldValue.arrayRemove([comment.toMap()]),
      });
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  // Get polls created by a specific user
  Stream<List<Poll>> getPollsByUser(String userId) {
    return _firestore
        .collection('polls')
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Poll.fromFirestore(doc)).toList();
    });
  }

  // Get polls where a user has voted
  Stream<List<Poll>> getPollsVotedByUser(String userId) {
    return _firestore
        .collection('polls')
        .where('options', arrayContains: {'votedBy': userId})
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Poll.fromFirestore(doc)).toList();
    });
  }
} 