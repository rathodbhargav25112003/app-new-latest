class RegistrationData {
  final String fullName;
  final String dateOfBirth;
  final String preparingValue;
  final String stateValue;
  final List<String> preparingFor;
  final String currentStatus;
  final String phoneNumber;
  final String email;
  final String? standardId;
  final String? preparingId;
  final String? userId;

  RegistrationData({
    required this.fullName,
    required this.dateOfBirth,
    required this.preparingValue,
    required this.stateValue,
    required this.preparingFor,
    required this.currentStatus,
    required this.phoneNumber,
    required this.email,
    this.standardId,
    this.preparingId,
    this.userId,
  });
}