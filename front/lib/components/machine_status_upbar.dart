import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/machine_status_service.dart';
import '../theme/app_design_system.dart';
import '../main.dart' show apiBaseUrl;
import 'dart:developer' as developer;

class MachineStatusUpbar extends StatefulWidget {
  final Color primaryColor;
  final VoidCallback? onTap;

  const MachineStatusUpbar({
    Key? key,
    required this.primaryColor,
    this.onTap,
  }) : super(key: key);

  @override
  State<MachineStatusUpbar> createState() => _MachineStatusUpbarState();
}

class _MachineStatusUpbarState extends State<MachineStatusUpbar> {
  final MachineStatusService _machineStatusService = MachineStatusService(baseUrl: apiBaseUrl);
  
  Map<String, dynamic>? _statusData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMachineStatus();
    // Refresh status every 30 seconds
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadMachineStatus();
        _startPeriodicRefresh();
      }
    });
  }

  Future<void> _loadMachineStatus() async {
    try {
      final statusData = await _machineStatusService.getMachineStatusForClient();
      if (mounted) {
        setState(() {
          _statusData = statusData;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error loading machine status for upbar: $e', name: 'MachineStatusUpbar');
      if (mounted) {
        setState(() {
          _statusData = {
            'status': 'OFFLINE',
            'isOperational': false,
            'message': 'Erreur de connexion',
            'lastUpdated': null,
          };
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    final colorString = MachineStatusService.getStatusColor(status);
    switch (colorString) {
      case 'green':
        return AppColors.success;
      case 'orange':
        return AppColors.warning;
      case 'red':
        return AppColors.error;
      case 'yellow':
        return AppColors.warning;
      case 'grey':
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'OPERATIONAL':
        return Icons.check_circle;
      case 'MAINTENANCE':
        return Icons.build;
      case 'ERROR':
        return Icons.error;
      case 'OFFLINE':
        return Icons.wifi_off;
      case 'OUT_OF_SERVICE':
        return Icons.block;
      case 'NEEDS_RESTOCKING':
        return Icons.inventory;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12.w,
              height: 12.h,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
              ),
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              'Vérification...',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_statusData == null) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off,
              color: AppColors.error,
              size: 14.sp,
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              'Hors ligne',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }    final status = _statusData!['status'] ?? 'OFFLINE';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final displayText = MachineStatusService.getStatusDisplayText(status);

    return GestureDetector(
      onTap: widget.onTap ?? () => _showStatusDetails(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4.h),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              statusIcon,
              color: statusColor,
              size: 14.sp,
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              displayText,
              style: AppTextStyles.caption.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusDetails() {
    if (_statusData == null) return;    final status = _statusData!['status'] ?? 'OFFLINE';
    final isOperational = _statusData!['isOperational'] ?? false;
    final message = _statusData!['message'];
    final lastUpdated = _statusData!['lastUpdated'];
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final displayText = MachineStatusService.getStatusDisplayText(status);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              statusIcon,
              color: statusColor,
              size: 24.sp,
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Statut du Distributeur',
              style: AppTextStyles.h4,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            Row(
              children: [
                Text(
                  'Statut: ',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  displayText,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),

            // Message if available
            if (message != null && message.isNotEmpty) ...[
              Text(
                'Message: ',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                message,
                style: AppTextStyles.bodyMedium,
              ),
              SizedBox(height: AppSpacing.sm),
            ],

            // Last updated
            if (lastUpdated != null) ...[
              Text(
                'Dernière mise à jour: ',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatDateTime(lastUpdated),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ] else ...[
              Text(
                'Aucune information de mise à jour disponible',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],

            SizedBox(height: AppSpacing.md),

            // Status indicator
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [                  Icon(
                    isOperational
                        ? Icons.check_circle
                        : Icons.warning,
                    color: statusColor,
                    size: 20.sp,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      isOperational
                          ? 'Le distributeur est disponible pour les commandes'
                          : 'Le distributeur n\'est pas disponible pour les commandes',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: AppTextStyles.buttonMedium.copyWith(
                color: widget.primaryColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadMachineStatus();
            },
            child: Text(
              'Actualiser',
              style: AppTextStyles.buttonMedium.copyWith(
                color: widget.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'Non disponible';
    
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'À l\'instant';
      } else if (difference.inMinutes < 60) {
        return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
      } else if (difference.inHours < 24) {
        return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
      } else {
        return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
      }
    } catch (e) {
      return 'Non disponible';
    }
  }
}
