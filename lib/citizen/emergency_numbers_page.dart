import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/shared_app_bar.dart';
import '../components/role_protected_page.dart';
import '../services/theme_service.dart';

// New Interactive Slide to Call Button Widget
class InteractiveSlideToCallButton extends StatefulWidget {
  final double height;
  final double thumbSize;
  final Color trackColor;
  final Color fillColor;
  final Color thumbColor;
  final IconData thumbIcon;
  final Color iconColor;
  final String labelText;
  final TextStyle labelStyle;
  final VoidCallback onSlideComplete;
  final Duration animationDuration;

  const InteractiveSlideToCallButton({
    Key? key,
    this.height = 60.0,
    this.thumbSize = 52.0, // Ensure thumbSize < height for padding
    this.trackColor = Colors.black12,
    this.fillColor = Colors.green,
    this.thumbColor = Colors.white,
    this.thumbIcon = Icons.phone,
    this.iconColor = Colors.green,
    this.labelText = 'Slide to Call',
    this.labelStyle = const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 16),
    required this.onSlideComplete,
    this.animationDuration = const Duration(milliseconds: 250),
  }) : super(key: key);

  @override
  _InteractiveSlideToCallButtonState createState() =>
      _InteractiveSlideToCallButtonState();
}

class _InteractiveSlideToCallButtonState extends State<InteractiveSlideToCallButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _currentSlidePosition = 0.0; // Normalized from 0.0 to 1.0
  bool _isDragging = false;
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      value: _currentSlidePosition,
    )..addListener(() {
        if (!_isDragging) {
          setState(() {
            _currentSlidePosition = _animationController.value;
          });
        }
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    if (_isConfirmed) return;
    _animationController.stop();
    _isDragging = true;
  }

  void _handleDragUpdate(DragUpdateDetails details, double trackWidth) {
    if (_isConfirmed || !_isDragging) return;
    
    final slideableWidth = trackWidth - widget.thumbSize;
    if (slideableWidth <= 0) return;

    setState(() {
      _currentSlidePosition = (_currentSlidePosition + (details.primaryDelta! / slideableWidth)).clamp(0.0, 1.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;
    if (_isConfirmed) return;

    if (_currentSlidePosition >= 0.85) {
      setState(() {
        _isConfirmed = true;
      });
      _animationController.animateTo(1.0, curve: Curves.easeOut).then((_) {
        if (mounted && _isConfirmed) {
          widget.onSlideComplete();
        }
      });
    } else {
      _animationController.animateTo(0.0, curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        if (trackWidth < widget.thumbSize) return const SizedBox.shrink(); // Not enough space

        final slideableWidth = trackWidth - widget.thumbSize;
        final thumbLeftOffset = _currentSlidePosition * slideableWidth;

        return GestureDetector(
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate: (d) => _handleDragUpdate(d, trackWidth),
          onHorizontalDragEnd: _handleDragEnd,
          child: Container(
            height: widget.height,
            width: trackWidth,
            decoration: BoxDecoration(
              color: widget.trackColor,
              borderRadius: BorderRadius.circular(widget.height / 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Fill Layer
                AnimatedContainer(
                  duration: _isDragging ? Duration.zero : widget.animationDuration,
                  curve: Curves.easeOut,
                  height: widget.height,
                  width: thumbLeftOffset + widget.thumbSize, // Fill up to the end of the thumb
                  decoration: BoxDecoration(
                    color: _isConfirmed ? widget.fillColor : widget.fillColor.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(widget.height / 2),
                  ),
                ),

                // Label Text
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 100),
                  opacity: _isConfirmed ? 0.0 : (1 - _currentSlidePosition * 2).clamp(0.0, 1.0),
                  child: Text(widget.labelText, style: widget.labelStyle),
                ),

                // Thumb
                Positioned(
                  left: thumbLeftOffset,
                  top: (widget.height - widget.thumbSize) / 2,
                  child: Container(
                    width: widget.thumbSize,
                    height: widget.thumbSize,
                    decoration: BoxDecoration(
                      color: widget.thumbColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        widget.thumbIcon,
                        color: _isConfirmed ? widget.fillColor : widget.iconColor, // Use fillColor on confirm
                        size: widget.thumbSize * 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class EmergencyNumbersPage extends StatelessWidget {
  const EmergencyNumbersPage({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      await launchUrl(launchUri);
    } catch (e) {
      debugPrint('Could not launch $launchUri: $e');
    }
  }

  void _showEmergencyDialog({
    required BuildContext context,
    required String title,
    required String number,
    String? description,
    required Color color,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Container(
          width: MediaQuery.of(dialogContext).size.width * 0.75, 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch, 
            children: [
              if (description != null) ...[
                Text(description),
                const SizedBox(height: 16),
              ],
              Text(
                'Call $number',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              InteractiveSlideToCallButton(
                fillColor: color, // Use the emergency contact's color for fill
                iconColor: color, // Use the emergency contact's color for icon
                labelText: 'Slide to Call $number',
                onSlideComplete: () {
                  // Dialog might be dismissed by the slide action itself if not handled carefully
                  // Ensure we only pop if it's still there.
                  if (Navigator.of(dialogContext, rootNavigator: true).canPop()) {
                     Navigator.of(dialogContext, rootNavigator: true).pop();
                  }
                  _makePhoneCall(number);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = Colors.red.shade700;
    
    return RoleProtectedPage(
      requiredRole: 'citizen',
      child: Scaffold(
        appBar: const SharedAppBar(
          title: "Emergency Numbers",
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency Contacts',
                      style: ThemeService.headingStyle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap on any card for emergency assistance',
                      style: TextStyle(fontSize: 16, color: themeColor),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Road Rescue Service (with description)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Road Services', style: ThemeService.subheadingStyle),
              ),
              
              _buildEmergencyNumberCard(
                context: context,
                title: 'Road Rescue',
                number: '126',
                icon: Icons.car_crash_outlined,
                color: Colors.amber.shade700,
                description: 'For vehicle breakdowns, road accidents and emergency assistance on highways and roads. Available 24/7 across the country.',
                hasDescription: true,
              ),
              
              const SizedBox(height: 16),
              
              // Emergency Services
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Emergency Services', style: ThemeService.subheadingStyle),
              ),
              
              _buildEmergencyNumberCard(
                context: context,
                title: 'National Emergency',
                number: '911',
                icon: Icons.local_police_outlined,
                color: Colors.red,
                description: 'Police, Fire & Medical emergencies',
              ),
              
              _buildEmergencyNumberCard(
                context: context,
                title: 'Ambulance',
                number: '123',
                icon: Icons.medical_services_outlined,
                color: Colors.green,
                description: 'Medical emergency services',
              ),
              
              _buildEmergencyNumberCard(
                context: context,
                title: 'Fire Department',
                number: '122',
                icon: Icons.local_fire_department_outlined,
                color: Colors.orange,
                description: 'Fire & rescue services',
              ),
              
              // Helplines
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Text('Helplines', style: ThemeService.subheadingStyle),
              ),
              
              _buildEmergencyNumberCard(
                context: context,
                title: 'Child Helpline',
                number: '16000',
                icon: Icons.child_care_outlined,
                color: Colors.blue,
                description: 'Child protection services',
              ),
              
              _buildEmergencyNumberCard(
                context: context,
                title: 'Women\'s Helpline',
                number: '15115',
                icon: Icons.woman_outlined,
                color: Colors.purple,
                description: 'Support for women in distress',
              ),
              
              _buildEmergencyNumberCard(
                context: context,
                title: 'Tourism Police',
                number: '126',
                icon: Icons.travel_explore_outlined,
                color: Colors.teal,
                description: 'Assistance for tourists',
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmergencyNumberCard({
    required BuildContext context,
    required String title,
    required String number,
    required IconData icon,
    required Color color,
    required String description,
    bool hasDescription = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            if (hasDescription) {
              _showEmergencyDialog(
                context: context,
                title: title,
                number: number,
                description: description,
                color: color,
              );
            } else {
              _showEmergencyDialog(
                context: context,
                title: title,
                number: number,
                color: color,
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 30, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        hasDescription ? 'Tap for more information' : description,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        number,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.phone, size: 16, color: color),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 