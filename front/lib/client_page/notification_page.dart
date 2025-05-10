import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/notification_provider.dart';
import '../models/notification.dart' as notification_model;
import '../theme/app_design_system.dart'; // Import our design system
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    // Forcer le rafraîchissement des notifications au chargement de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).forceRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Utiliser le provider
    final notificationProvider = Provider.of<NotificationProvider>(context);

    if (notificationProvider.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.w,
          color: AppColors.primary,
        ),
      );
    }

    if (notificationProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: AppColors.error,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Erreur de chargement',
              style: AppTextStyles.h4.copyWith(color: AppColors.error),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              notificationProvider.error!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh, size: 18.sp),
              label: Text('Réessayer', style: AppTextStyles.buttonMedium),
              onPressed: () => notificationProvider.forceRefresh(),
            ),
          ],
        ),
      );
    }

    if (notificationProvider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 64.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Aucune notification',
              style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh, size: 18.sp),
              label: Text('Actualiser', style: AppTextStyles.buttonMedium),
              onPressed: () => notificationProvider.forceRefresh(),
            ),
          ],
        ),
      );
    }

    // Filtrer les notifications par type
    final transactionNotifications = notificationProvider.notifications
        .where((n) => n.type == 'TRANSACTION')
        .toList();

    final codeNotifications = notificationProvider.notifications
        .where((n) => n.type == 'CODE')
        .toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors
                    .backgroundDark // Replace with an existing or appropriate property
                : AppColors.surfaceLight,
            child: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(
                  text: 'Commandes',
                  icon: Icon(Icons.shopping_cart, size: 20.sp),
                ),
                Tab(
                  text: 'Codes',
                  icon: Icon(Icons.qr_code, size: 20.sp),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (notificationProvider.unreadCount > 0)
                Padding(
                  padding:
                      EdgeInsets.only(right: AppSpacing.md, top: AppSpacing.sm),
                  child: TextButton.icon(
                    icon: Icon(Icons.check_circle_outline, size: 18.sp),
                    label: Text(
                      'Tout marquer comme lu',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    onPressed: () => notificationProvider.markAllAsRead(),
                  ),
                ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Vue des commandes (transactions)
                _buildTransactionNotificationsList(
                    context, transactionNotifications, notificationProvider),

                // Vue des codes
                _buildCodeNotificationsList(
                    context, codeNotifications, notificationProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionNotificationsList(
      BuildContext context,
      List<notification_model.Notification> notifications,
      NotificationProvider provider) {
    if (notifications.isEmpty) {
      return Center(
        child: Text(
          'Aucune notification de commande',
          style:
              AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.forceRefresh(),
      color: AppColors.primary,
      child: AnimationLimiter(
        child: ListView.builder(
          padding: EdgeInsets.all(AppSpacing.sm),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            final metadata = notification.metadata ?? {};

            // Formatage de la date
            final dateFormatter = DateFormat('dd/MM/yyyy à HH:mm');
            final formattedDate = dateFormatter.format(notification.createdAt);

            // Récupérer les détails de la commande depuis les métadonnées
            final double montant = metadata['montant']?.toDouble() ?? 0.0;
            final List<dynamic> produitsData = metadata['produits'] ?? [];

            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Card(
                    margin: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    elevation: AppSpacing.cardElevation,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                    ),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: notification.isUnread
                            ? AppColors.success.withOpacity(0.2)
                            : AppColors.textSecondary.withOpacity(0.1),
                        child: Icon(
                          Icons.receipt,
                          color: notification.isUnread
                              ? AppColors.success
                              : AppColors.textSecondary,
                          size: 20.sp,
                        ),
                      ),
                      title: Text(
                        notification.title,
                        style: notification.isUnread
                            ? AppTextStyles.bodyLarge
                                .copyWith(fontWeight: FontWeight.bold)
                            : AppTextStyles.bodyLarge,
                      ),
                      subtitle: Text(
                        formattedDate,
                        style: AppTextStyles.bodySmall,
                      ),
                      trailing: Text(
                        '${montant.toStringAsFixed(2)} DA',
                        style: AppTextStyles.balanceText,
                      ),
                      onExpansionChanged: (expanded) {
                        if (expanded && notification.isUnread) {
                          provider.markAsRead(notification.id);
                        }
                      },
                      children: [
                        Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.message,
                                style: AppTextStyles.bodyMedium,
                              ),
                              SizedBox(height: AppSpacing.md),
                              Text(
                                'Détails de la commande:',
                                style: AppTextStyles.subtitle.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: AppSpacing.sm),
                              ...produitsData.map<Widget>((produit) {
                                return Padding(
                                  padding:
                                      EdgeInsets.only(bottom: AppSpacing.sm),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${produit['nom']} x${produit['quantite']}',
                                          style: AppTextStyles.bodyMedium,
                                        ),
                                      ),
                                      Text(
                                        '${(produit['prix'] * produit['quantite']).toStringAsFixed(2)} DA',
                                        style:
                                            AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              Divider(thickness: 1.h, color: AppColors.divider),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total:',
                                    style: AppTextStyles.subtitle.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${montant.toStringAsFixed(2)} DA',
                                    style: AppTextStyles.balanceText,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCodeNotificationsList(
      BuildContext context,
      List<notification_model.Notification> notifications,
      NotificationProvider provider) {
    if (notifications.isEmpty) {
      return Center(
        child: Text(
          'Aucune notification de code',
          style:
              AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.forceRefresh(),
      color: AppColors.primary,
      child: AnimationLimiter(
        child: ListView.builder(
          padding: EdgeInsets.all(AppSpacing.sm),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            final metadata = notification.metadata ?? {};

            // Formatage de la date
            final dateFormatter = DateFormat('dd/MM/yyyy à HH:mm');
            final formattedDate = dateFormatter.format(notification.createdAt);

            // Obtenir le statut du code et définir une icône appropriée
            final String codeStatus = metadata['status'] ?? 'generated';
            IconData statusIcon;
            Color statusColor;

            switch (codeStatus.toLowerCase()) {
              case 'used':
                statusIcon = Icons.check_circle;
                statusColor = AppColors.success;
                break;
              case 'cancelled':
                statusIcon = Icons.cancel;
                statusColor = AppColors.error;
                break;
              case 'expired':
                statusIcon = Icons.timer_off;
                statusColor = AppColors.warning;
                break;
              case 'generated':
              default:
                statusIcon = Icons.qr_code;
                statusColor = AppColors.info;
            }

            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Card(
                    margin: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    elevation: AppSpacing.cardElevation,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: notification.isUnread
                            ? statusColor.withOpacity(0.2)
                            : AppColors.textSecondary.withOpacity(0.1),
                        child: Icon(
                          statusIcon,
                          color: notification.isUnread
                              ? statusColor
                              : AppColors.textSecondary,
                          size: 20.sp,
                        ),
                      ),
                      title: Text(
                        notification.title,
                        style: notification.isUnread
                            ? AppTextStyles.bodyLarge
                                .copyWith(fontWeight: FontWeight.bold)
                            : AppTextStyles.bodyLarge,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formattedDate, style: AppTextStyles.bodySmall),
                          SizedBox(height: 4.h),
                          Text(notification.message,
                              style: AppTextStyles.bodyMedium),
                          if (metadata['code'] != null)
                            Text(
                              'Code: ${metadata['code']}',
                              style: AppTextStyles.codeText.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () {
                        if (notification.isUnread) {
                          provider.markAsRead(notification.id);
                        }
                      },
                      // Ajouter un badge pour les codes qui sont utilisés ou annulés
                      trailing: _getStatusBadge(codeStatus),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _getStatusBadge(String status) {
    switch (status.toLowerCase()) {
      case 'used':
        return _buildBadge('Utilisé', AppColors.success);
      case 'cancelled':
        return _buildBadge('Annulé', AppColors.error);
      case 'expired':
        return _buildBadge('Expiré', AppColors.warning);
      case 'generated':
        return _buildBadge('Généré', AppColors.info);
      default:
        return _buildBadge(status, AppColors.textSecondary);
    }
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
