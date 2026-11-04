import 'package:equatable/equatable.dart';

enum PhotoQuality { dataSaver, fullDetail }

enum AppLanguage {
  english('English'),
  luganda('Luganda');

  const AppLanguage(this.label);

  final String label;
}

/// Per-phone preferences (not synced to the server).
class AppSettings extends Equatable {
  const AppSettings({
    this.videoOnWifiOnly = true,
    this.photoQuality = PhotoQuality.dataSaver,
    this.pushNotifications = true,
    this.requireBiometricToReview = false,
    this.language = AppLanguage.english,
    this.seenJoinIntro = false,
  });

  final bool videoOnWifiOnly;
  final PhotoQuality photoQuality;
  final bool pushNotifications;
  final bool requireBiometricToReview;
  final AppLanguage language;

  /// Site manager has seen "Sarah added you to a project".
  final bool seenJoinIntro;

  AppSettings copyWith({
    bool? videoOnWifiOnly,
    PhotoQuality? photoQuality,
    bool? pushNotifications,
    bool? requireBiometricToReview,
    AppLanguage? language,
    bool? seenJoinIntro,
  }) => AppSettings(
    videoOnWifiOnly: videoOnWifiOnly ?? this.videoOnWifiOnly,
    photoQuality: photoQuality ?? this.photoQuality,
    pushNotifications: pushNotifications ?? this.pushNotifications,
    requireBiometricToReview:
        requireBiometricToReview ?? this.requireBiometricToReview,
    language: language ?? this.language,
    seenJoinIntro: seenJoinIntro ?? this.seenJoinIntro,
  );

  @override
  List<Object?> get props => [
    videoOnWifiOnly,
    photoQuality,
    pushNotifications,
    requireBiometricToReview,
    language,
    seenJoinIntro,
  ];
}
