class MeetingUserList {
  int? id;
  String? display;
  String? ispublisher;
  bool? isTalking;
  bool? isHost;
  bool? isJoined;
  bool? isVideoOn;
  bool? isAudioOn;
  bool? isModerator;
  String? profile;

  MeetingUserList(
      {this.id,
        this.display,
        this.ispublisher,
        this.isTalking,
        this.isHost,
        this.isJoined,
        this.isVideoOn,
        this.isAudioOn,
        this.isModerator,
        this.profile,
      });

  MeetingUserList.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    display = json['display'];
    ispublisher = json['ispublisher'];
    isTalking = json['isTalking'];
    isHost = json['isHost'];
    isJoined = json['isJoined'];
    isVideoOn = json['isVideoOn'];
    isAudioOn = json['isAudioOn'];
    isModerator = json['isModerator'];
    profile = json['profile'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['display'] = this.display;
    data['ispublisher'] = this.ispublisher;
    data['isTalking'] = this.isTalking;
    data['isHost'] = this.isHost;
    data['isJoined'] = this.isJoined;
    data['isVideoOn'] = this.isVideoOn;
    data['isAudioOn'] = this.isAudioOn;
    data['isModerator'] = this.isModerator;
    data['profile'] = this.profile;
    return data;
  }
}