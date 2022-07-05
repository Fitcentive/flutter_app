class NotificationDevice {
  String userId;
  String registrationToken;
  String manufacturer;
  String model;
  bool isPhysicalDevice;

  NotificationDevice({
      required this.userId,
      required this.registrationToken,
      required this.manufacturer,
      required this.model,
      required this.isPhysicalDevice
  });
}
