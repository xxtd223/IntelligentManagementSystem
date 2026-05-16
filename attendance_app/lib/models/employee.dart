class Employee {
  final int id;
  final String employeeNo;
  final String name;
  final String? phone;
  final String? email;
  final String role;
  final String status;
  final String? departmentName;
  final int? departmentId;
  final String? officeLocationName;
  final int? officeLocationId;
  final String? avatarUrl;

  const Employee({
    required this.id,
    required this.employeeNo,
    required this.name,
    this.phone,
    this.email,
    required this.role,
    required this.status,
    this.departmentName,
    this.departmentId,
    this.officeLocationName,
    this.officeLocationId,
    this.avatarUrl,
  });

  bool get isAdmin => role == 'ADMIN';
  bool get isActive => status == 'ACTIVE';

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        id: (json['id'] as num).toInt(),
        employeeNo: json['employeeNo'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        role: json['role'] as String,
        status: json['status'] as String,
        departmentName: json['departmentName'] as String?,
        departmentId: (json['departmentId'] as num?)?.toInt(),
        officeLocationName: json['officeLocationName'] as String?,
        officeLocationId: (json['officeLocationId'] as num?)?.toInt(),
        avatarUrl: json['avatarUrl'] as String?,
      );
}
