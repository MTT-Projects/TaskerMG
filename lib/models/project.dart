import "package:dos/models/task.dart";

class Project {
  final int? id;
  final String? name;
  final String? description;
  final String? imageurl;
  final List<Task>? tasks;

  Project({
    this.id,
    this.name, 
    this.description, 
    this.imageurl,
    this.tasks
    });
}
