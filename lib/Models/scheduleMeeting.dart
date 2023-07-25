class ScheduleMeeting {
  String? title;
  String? meetingId;
  String? meetingPassword;
  String? startTime;
  String? hostId;
  String? hostName;
  String? isExpire;
  int? duration;
  String? usersList;
  String? createdById;
  bool? isWebinar;
  ScheduleMeeting(
      {this.title,
        this.meetingId,
        this.meetingPassword,
        this.startTime,
        this.hostId,
        this.hostName,
        this.isExpire,
        this.duration,
        this.usersList,
        this.createdById,
        this.isWebinar,
      });
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'meetingId': meetingId,
      'meetingPassword': meetingPassword,
      'startTime': startTime,
      'hostId': hostId,
      'hostName': hostName,
      'isExpire': isExpire,
      'duration': duration,
      'usersList': usersList,
      'createdById': createdById,
      'isWebinar': isWebinar,
    };
  }

  factory ScheduleMeeting.fromMap(Map<String, dynamic> map) {
    return ScheduleMeeting(
      title: map['title'] ?? 'la',
      meetingId: map['meetingId'] ?? 'la',
      meetingPassword: map['meetingPassword'] ?? 'la',
      startTime: map['startTime'] ?? 'la',
      hostId: map['hostId'] ?? 'la',
      hostName: map['hostName'] ?? 'la',
      isExpire: map['isExpire'] ?? 'la',
      duration: map['duration'] ?? 60,
      usersList: map['usersList'] ?? "",
      createdById: map['createdById'] ?? "",
      isWebinar: map['isWebinar'] ?? false,
    );
  }

}