class AppConstants {
  // Collections
  static const String usersCollection = 'users';
  static const String requestsCollection = 'requests';

  // Request Statuses
  static const String statusPending = 'pending';
  static const String statusDelivered = 'delivered';
  static const String statusCancelled = 'cancelled';

  // Arabic Status Translations
  static const Map<String, String> statusTranslations = {
    statusPending: 'في الانتظار',
    statusDelivered: 'تم التوصيل',
    statusCancelled: 'ملغية',
  };
}
