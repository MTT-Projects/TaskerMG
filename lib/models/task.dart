class Task {
  int? id;
  int? projectID;
  String? title;
  String? description;
  DateTime? deadline;
  String? priority;
  String? status;
  int? createdUserID;
  DateTime? lastUpdate;

  Task({
    this.id,
    this.projectID,
    this.title,
    this.description,
    this.deadline,
    this.priority,
    this.status,
    this.createdUserID,
    this.lastUpdate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectID': projectID,
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'priority': priority,
      'status': status,
      'createdUserID': createdUserID,
      'lastUpdate': lastUpdate?.toIso8601String(),
    };
  }

  Map<String,dynamic> toJson(){
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['projectID'] = this.projectID;
    data['title'] = this.title;
    data['description'] = this.description;
    data['deadline'] = this.deadline;
    data['priority'] = this.priority;
    data['status'] = this.status;
    data['createdUserID'] = this.createdUserID;
    data['lastUpdate'] = this.lastUpdate;
    return data;
  }

  Task.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    projectID = json['projectID'];
    title = json['title'];
    description = json['description'];
    deadline = json['deadline'];
    priority = json['priority'];
    status = json['status'];
    createdUserID = json['createdUserID'];
    lastUpdate = json['lastUpdate'];
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      projectID: map['projectID'],
      title: map['title'],
      description: map['description'],
      deadline: DateTime.parse(map['deadline']),
      priority: map['priority'],
      status: map['status'],
      createdUserID: map['createdUserID'],
      lastUpdate: DateTime.parse(map['lastUpdate']),
    );
  }
}

