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
        id: project.id,
        name: project.name,
        color: project.color,
        isArchived: true,
      ));
    }
  }

  Future<void> restoreProject(int index) async {
    final archivedProjects = getArchivedProjects();
    if (index < 0 || index >= archivedProjects.length) return;

    final projectToRestore = archivedProjects[index];
    final boxIndex = projectBox.values.toList().indexWhere((p) => p.id == projectToRestore.id);

    if (boxIndex != -1) {
      final project = projectBox.getAt(boxIndex);
      if (project != null) {
        await projectBox.putAt(boxIndex, Project(
          id: project.id,
          name: project.name,
          color: project.color,
          isArchived: false,
        ));
      }
    }
  }

  Future<void> deleteProject(int index, BuildContext context) async {
    final archivedProjects = getArchivedProjects();
    if (index < 0 || index >= archivedProjects.length) return;

    final projectToDelete = archivedProjects[index];
    final boxIndex = projectBox.values.toList().indexWhere((p) => p.id == projectToDelete.id);

    if (boxIndex != -1) {
      await context.read<TaskCubit>().updateTasksOnProjectDeletion(projectToDelete.name);
      await projectBox.deleteAt(boxIndex);
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
        id: tag.id,
        name: tag.name,
        backgroundColor: tag.backgroundColor,
        textColor: tag.textColor,
        isArchived: true,
      ));
    }
  }

  Future<void> restoreTag(int index) async {
    final archivedTags = getArchivedTags();
    if (index < 0 || index >= archivedTags.length) return;

    final tagToRestore = archivedTags[index];
    // SỬA: Tìm index trong Box dựa trên id
    final boxIndex = tagBox.values.toList().indexWhere((t) => t.id == tagToRestore.id);

    if (boxIndex != -1) {
      final tag = tagBox.getAt(boxIndex);
      if (tag != null) {
        await tagBox.putAt(boxIndex, Tag(
          id: tag.id,
          name: tag.name,
          backgroundColor: tag.backgroundColor,
          textColor: tag.textColor,
          isArchived: false,
        ));
      }
    }
  }

  Future<void> deleteTag(int index, BuildContext context) async {
    final archivedTags = getArchivedTags();
    if (index < 0 || index >= archivedTags.length) return;

    final tagToDelete = archivedTags[index];
    final boxIndex = tagBox.values.toList().indexWhere((t) => t.id == tagToDelete.id);

    if (boxIndex != -1) {
      await context.read<TaskCubit>().updateTasksOnTagDeletion(tagToDelete.name);
      await tagBox.deleteAt(boxIndex);
    }
  }

  List<Tag> getTags() {
    return tagBox.values.where((tag) => !tag.isArchived).toList();
  }

  List<Tag> getArchivedTags() {
    return tagBox.values.where((tag) => tag.isArchived).toList();
  }
}