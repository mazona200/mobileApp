import 'package:flutter/material.dart';
import '../models/advertisement.dart';
import '../services/advertisement_service.dart';
import '../widgets/ad_card.dart';

class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  final _adService = AdvertisementService();
  AdvertisementStatus? _selectedStatus;
  String? _errorMessage;

  Future<void> _deleteAdvertisement(String id) async {
    try {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Advertisement'),
          content: const Text(
            'Are you sure you want to delete this advertisement? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _adService.deleteAdvertisement(id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Advertisement deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      _errorMessage = e.toString();
                    });
                  }
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Advertisements'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/advertiser/create-ad');
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<AdvertisementStatus?>(
              segments: const [
                ButtonSegment(
                  value: null,
                  label: Text('All'),
                ),
                ButtonSegment(
                  value: AdvertisementStatus.pending,
                  label: Text('Pending'),
                ),
                ButtonSegment(
                  value: AdvertisementStatus.approved,
                  label: Text('Approved'),
                ),
                ButtonSegment(
                  value: AdvertisementStatus.rejected,
                  label: Text('Rejected'),
                ),
              ],
              selected: {_selectedStatus},
              onSelectionChanged: (Set<AdvertisementStatus?> selected) {
                setState(() {
                  _selectedStatus = selected.first;
                });
              },
            ),
          ),
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Advertisement>>(
              stream: _adService.getAdvertiserAdvertisements(
                status: _selectedStatus,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final advertisements = snapshot.data!;

                if (advertisements.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.campaign_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedStatus == null
                              ? 'No advertisements yet'
                              : 'No ${_selectedStatus.toString().split('.').last} advertisements',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/advertiser/create-ad');
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create Advertisement'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: advertisements.length,
                  itemBuilder: (context, index) {
                    final advertisement = advertisements[index];
                    return AdCard(
                      advertisement: advertisement,
                      onEdit: advertisement.status == AdvertisementStatus.pending
                          ? () {
                              Navigator.pushNamed(
                                context,
                                '/advertiser/edit-ad',
                                arguments: advertisement,
                              );
                            }
                          : null,
                      onDelete: advertisement.status == AdvertisementStatus.pending
                          ? () => _deleteAdvertisement(advertisement.id)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 