import 'package:flutter/material.dart';
import '../components/role_protected_page.dart';
import '../components/shared_app_bar.dart';
import '../services/advertisement_service.dart';
import '../models/advertisement.dart';
import '../services/theme_service.dart';
import 'package:intl/intl.dart';

class ViewAdvertisementsPage extends StatelessWidget {
  const ViewAdvertisementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleProtectedPage(
      requiredRole: 'citizen',
      child: Scaffold(
        appBar: const SharedAppBar(title: "Posted Advertisements"),
        body: StreamBuilder<List<Advertisement>>(
          stream: AdvertisementService().getActiveAdvertisements(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              print('Error loading advertisements: ${snapshot.error}');
              // Try fallback method with approved advertisements
              return StreamBuilder<List<Advertisement>>(
                stream: AdvertisementService().getApprovedAdvertisements(),
                builder: (context, fallbackSnapshot) {
                  if (fallbackSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  if (fallbackSnapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading advertisements',
                            style: ThemeService.subheadingStyle.copyWith(
                              color: Colors.red.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please try again later',
                            style: ThemeService.bodyStyle.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Trigger rebuild
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const ViewAdvertisementsPage()),
                              );
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final advertisements = fallbackSnapshot.data ?? [];
                  return _buildAdvertisementsList(context, advertisements, isFiltered: false);
                },
              );
            }

            final advertisements = snapshot.data ?? [];
            return _buildAdvertisementsList(context, advertisements, isFiltered: true);
          },
        ),
      ),
    );
  }

  Widget _buildAdvertisementsList(BuildContext context, List<Advertisement> advertisements, {required bool isFiltered}) {
    if (advertisements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No advertisements available',
              style: ThemeService.subheadingStyle.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new advertisements',
              style: ThemeService.bodyStyle.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (!isFiltered)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing all approved advertisements (date filtering disabled)',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: advertisements.length,
            itemBuilder: (context, index) {
              final ad = advertisements[index];
              return _buildAdvertisementCard(context, ad);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdvertisementCard(BuildContext context, Advertisement ad) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showAdvertisementDetails(context, ad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Advertisement Image
            if (ad.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    ad.imageUrls.first,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade300,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Image not available',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            
            // Advertisement Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ad.businessType,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Title
                  Text(
                    ad.title,
                    style: ThemeService.subheadingStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Business Name
                  Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ad.businessName,
                          style: ThemeService.bodyStyle.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    ad.description,
                    style: ThemeService.bodyStyle.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Footer with date and "tap to view"
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Valid until ${DateFormat.yMMMd().format(ad.endDate)}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          'Tap to view',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdvertisementDetails(BuildContext context, Advertisement ad) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ad.businessType,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Title
                      Text(
                        ad.title,
                        style: ThemeService.headingStyle,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Business Name
                      Row(
                        children: [
                          Icon(
                            Icons.business,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ad.businessName,
                              style: ThemeService.subheadingStyle.copyWith(
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Images
                      if (ad.imageUrls.isNotEmpty) ...[
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: ad.imageUrls.length,
                            itemBuilder: (context, index) => Container(
                              margin: EdgeInsets.only(
                                right: index < ad.imageUrls.length - 1 ? 12 : 0,
                              ),
                              width: 300,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  ad.imageUrls[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.grey.shade300,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image_not_supported_outlined,
                                          size: 48,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Image not available',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Description
                      Text(
                        'Description',
                        style: ThemeService.subheadingStyle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ad.description,
                        style: ThemeService.bodyStyle.copyWith(
                          height: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Details
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: ThemeService.cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Advertisement Details',
                              style: ThemeService.subheadingStyle,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              'Start Date',
                              DateFormat.yMMMd().format(ad.startDate),
                              Icons.calendar_today,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'End Date',
                              DateFormat.yMMMd().format(ad.endDate),
                              Icons.event,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'Posted',
                              DateFormat.yMMMd().add_jm().format(ad.createdAt),
                              Icons.schedule,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
} 