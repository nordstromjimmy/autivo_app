import 'package:flutter/material.dart';

/// All features in the app that can be gated by tier
enum AppFeature {
  // Vehicle Management
  addVehicle,
  deleteVehicle,
  editVehicle,
  unlimitedVehicles,

  // Maintenance
  addMaintenance,
  editMaintenance,
  deleteMaintenance,
  unlimitedMaintenance,
  exportMaintenancePDF,

  // Cloud & Sync
  cloudBackup,
  cloudSync,
  multiDeviceSync,

  // Data & Export
  exportAllData,
  importData,

  // Advanced Features
  ocrScanning,
  besiktningReminders,
  customCategories,
  advancedStatistics,

  // Future Features (placeholders)
  fuelTracking,
  expenseAnalytics,
  serviceReminders,
  shareWithMechanic,

  // Premium Perks
  removeAds,
  prioritySupport,
  earlyAccess,
}

/// User tiers
enum UserTier {
  unregistered, // No account
  free, // Has account, no payment
  premium, // Has account + payment
}

/// Feature metadata for UI display
class FeatureInfo {
  final AppFeature feature;
  final String displayName;
  final String description;
  final IconData icon;

  const FeatureInfo({
    required this.feature,
    required this.displayName,
    required this.description,
    required this.icon,
  });
}

/// Display information for all features
class FeatureMetadata {
  static const Map<AppFeature, FeatureInfo> info = {
    AppFeature.unlimitedVehicles: FeatureInfo(
      feature: AppFeature.unlimitedVehicles,
      displayName: 'Obegränsade fordon',
      description: 'Lägg till hur många fordon du vill',
      icon: Icons.directions_car,
    ),
    AppFeature.cloudBackup: FeatureInfo(
      feature: AppFeature.cloudBackup,
      displayName: 'Molnbackup',
      description: 'Säkerhetskopiera din data automatiskt',
      icon: Icons.cloud_upload,
    ),
    AppFeature.cloudSync: FeatureInfo(
      feature: AppFeature.cloudSync,
      displayName: 'Molnsynkronisering',
      description: 'Synka mellan alla dina enheter',
      icon: Icons.sync,
    ),
    AppFeature.multiDeviceSync: FeatureInfo(
      feature: AppFeature.multiDeviceSync,
      displayName: 'Flerenhetssynk',
      description: 'Använd Autivo på flera enheter',
      icon: Icons.devices,
    ),
    AppFeature.exportMaintenancePDF: FeatureInfo(
      feature: AppFeature.exportMaintenancePDF,
      displayName: 'Exportera PDF',
      description: 'Skapa professionella servicehistorik-rapporter',
      icon: Icons.picture_as_pdf,
    ),
    AppFeature.ocrScanning: FeatureInfo(
      feature: AppFeature.ocrScanning,
      displayName: 'OCR-skanning',
      description: 'Scanna kvitton och registreringsnummer automatiskt',
      icon: Icons.document_scanner,
    ),
    AppFeature.besiktningReminders: FeatureInfo(
      feature: AppFeature.besiktningReminders,
      displayName: 'Besiktningspåminnelser',
      description: 'Få påminnelser när det är dags för besiktning',
      icon: Icons.notifications_active,
    ),
    AppFeature.advancedStatistics: FeatureInfo(
      feature: AppFeature.advancedStatistics,
      displayName: 'Avancerad statistik',
      description: 'Detaljerade kostnadsanalyser och trender',
      icon: Icons.analytics,
    ),
    AppFeature.exportAllData: FeatureInfo(
      feature: AppFeature.exportAllData,
      displayName: 'Exportera all data',
      description: 'Exportera komplett fordonshistorik',
      icon: Icons.download,
    ),
    AppFeature.prioritySupport: FeatureInfo(
      feature: AppFeature.prioritySupport,
      displayName: 'Prioriterad support',
      description: 'Få hjälp snabbare med Premium-support',
      icon: Icons.support_agent,
    ),
  };

  /// Get feature info
  static FeatureInfo? get(AppFeature feature) => info[feature];

  /// Get display name for feature
  static String getDisplayName(AppFeature feature) {
    return info[feature]?.displayName ?? feature.name;
  }

  /// Get description for feature
  static String getDescription(AppFeature feature) {
    return info[feature]?.description ?? '';
  }

  /// Get icon for feature
  static IconData getIcon(AppFeature feature) {
    return info[feature]?.icon ?? Icons.star;
  }
}
