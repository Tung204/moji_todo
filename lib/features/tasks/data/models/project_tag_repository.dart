import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/task_cubit.dart';
import '../models/project_model.dart';
import '../models/tag_model.dart';

class ProjectTagRepository {
  final Box<Project> projectBox;
  final Box<Tag> tagBox;

  ProjectTagRepository({
    required this.projectBox,
    required this.tagBox,
  });

  Future<void> addProject(Project project) async {
    await projectBox.add(project);
  }

  Future<void> updateProject(int index, Project project) async {
    await projectBox.putAt(index, project);
  }

  Future<void> archiveProject(int index) async {
    final project = projectBox.getAt(index);
    if (project != null) {
      await projectBox.putAt(index, Project(
        name: project.name,
        color: project.color,
        isArchived: true,
      ));
    }
  }

  Future<void> restoreProject(int index) async {
    final project = projectBox.getAt(index);
    if (project != null) {
      await projectBox.putAt(index, Project(
        name: project.name,
        color: project.color,
        isArchived: false,
      ));
    }
  }

  Future<void> deleteProject(int index, BuildContext context) async {
    final project = projectBox.getAt(index);
    if (project != null) {
      await context.read<TaskCubit>().updateTasksOnProjectDeletion(project.name);
      await projectBox.deleteAt(index);
    }
  }

  List<Project> getProjects() {
    return projectBox.values.where((project) => !project.isArchived).toList();
  }

  List<Project> getArchivedProjects() {
    return projectBox.values.where((project) => project.isArchived).toList();
  }

  Future<void> addTag(Tag tag) async {
    await tagBox.add(tag);
  }

  Future<void> updateTag(int index, Tag tag) async {
    await tagBox.putAt(index, tag);
  }

  Future<void> archiveTag(int index) async {
    final tag = tagBox.getAt(index);
    if (tag != null) {
      await tagBox.putAt(index, Tag(
        name: tag.name,
        backgroundColor: tag.backgroundColor,
        textColor: tag.textColor,
        isArchived: true,
      ));
    }
  }

  Future<void> restoreTag(int index) async {
    final tag = tagBox.getAt(index);
    if (tag != null) {
      await tagBox.putAt(index, Tag(
        name: tag.name,
        backgroundColor: tag.backgroundColor,
        textColor: tag.textColor,
        isArchived: false,
      ));
    }
  }

  Future<void> deleteTag(int index, BuildContext context) async {
    final tag = tagBox.getAt(index);
    if (tag != null) {
      await context.read<TaskCubit>().updateTasksOnTagDeletion(tag.name);
      await tagBox.deleteAt(index);
    }
  }

  List<Tag> getTags() {
    return tagBox.values.where((tag) => !tag.isArchived).toList();
  }

  List<Tag> getArchivedTags() {
    return tagBox.values.where((tag) => tag.isArchived).toList();
  }
}