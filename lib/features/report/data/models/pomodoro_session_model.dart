import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Để dùng @required hoặc cho các tiện ích khác

class PomodoroSessionRecordModel {
  final String id; // Document ID từ Firestore (sẽ được gán khi đọc)
  final String? taskId; // ID của task liên quan, có thể là "none" hoặc null
  final DateTime startTime;
  final DateTime endTime;
  final int durationInSeconds; // Thời lượng thực tế của phiên làm việc/nghỉ
  final bool isWorkSession; // True nếu là phiên làm việc, false nếu là phiên nghỉ
  final DateTime sessionDate; // Chỉ chứa thông tin ngày (YYYY-MM-DD), giờ phút giây đặt về 0 (UTC)
  final String? projectId; // ID của project liên quan (nếu taskId có và task đó thuộc project)
  // final String? soundUsed; // Bạn có thể bỏ comment nếu vẫn muốn lưu và sử dụng trường này

  PomodoroSessionRecordModel({
    required this.id,
    this.taskId,
    required this.startTime,
    required this.endTime,
    required this.durationInSeconds,
    required this.isWorkSession,
    required this.sessionDate,
    this.projectId,
    // this.soundUsed,
  });

  // Factory constructor để tạo instance từ DocumentSnapshot của Firestore
  factory PomodoroSessionRecordModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Tính toán durationInSeconds nếu nó không được lưu trực tiếp
    // (nhưng chúng ta đã thống nhất sẽ lưu nó)
    int calculatedDuration = data['durationInSeconds'] as int? ?? 0;
    if (calculatedDuration == 0 && data['startTime'] != null && data['endTime'] != null) {
      final start = (data['startTime'] as Timestamp).toDate();
      final end = (data['endTime'] as Timestamp).toDate();
      calculatedDuration = end.difference(start).inSeconds;
    }

    // Xử lý sessionDate nếu nó không được lưu trực tiếp
    // (nhưng chúng ta đã thống nhất sẽ lưu nó)
    DateTime parsedSessionDate;
    if (data['sessionDate'] != null) {
      parsedSessionDate = (data['sessionDate'] as Timestamp).toDate();
    } else if (data['endTime'] != null) {
      final end = (data['endTime'] as Timestamp).toDate();
      parsedSessionDate = DateTime.utc(end.year, end.month, end.day); // Đảm bảo là UTC
    } else {
      // Fallback nếu cả sessionDate và endTime đều null, điều này không nên xảy ra
      parsedSessionDate = DateTime.now().toUtc();
      print("Cảnh báo: sessionDate và endTime đều null cho PomodoroSessionRecordModel id: ${doc.id}");
    }


    return PomodoroSessionRecordModel(
      id: doc.id,
      taskId: data['taskId'] as String?,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      durationInSeconds: calculatedDuration,
      isWorkSession: data['isWorkSession'] as bool? ?? true, // Mặc định là true nếu thiếu
      sessionDate: parsedSessionDate,
      projectId: data['projectId'] as String?,
      // soundUsed: data['soundUsed'] as String?,
    );
  }

  // Hàm toJson để có thể chuyển đổi lại thành Map, hữu ích cho việc debug
  // hoặc nếu sau này bạn muốn lưu model này vào Hive chẳng hạn.
  Map<String, dynamic> toJson() {
    return {
      // 'id': id, // Thường không lưu id của document Firestore vào bên trong chính document đó
      'taskId': taskId,
      'startTime': Timestamp.fromDate(startTime.toUtc()), // Lưu dưới dạng UTC
      'endTime': Timestamp.fromDate(endTime.toUtc()),     // Lưu dưới dạng UTC
      'durationInSeconds': durationInSeconds,
      'isWorkSession': isWorkSession,
      'sessionDate': Timestamp.fromDate(sessionDate), // sessionDate đã là UTC và có giờ phút giây = 0
      'projectId': projectId,
      // 'soundUsed': soundUsed,
    };
  }

  PomodoroSessionRecordModel copyWith({
    String? id,
    String? taskId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationInSeconds,
    bool? isWorkSession,
    DateTime? sessionDate,
    String? projectId,
    // String? soundUsed,
  }) {
    return PomodoroSessionRecordModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      isWorkSession: isWorkSession ?? this.isWorkSession,
      sessionDate: sessionDate ?? this.sessionDate,
      projectId: projectId ?? this.projectId,
      // soundUsed: soundUsed ?? this.soundUsed,
    );
  }

  @override
  String toString() {
    return 'PomodoroSessionRecordModel(id: $id, taskId: $taskId, startTime: $startTime, endTime: $endTime, durationInSeconds: $durationInSeconds, isWorkSession: $isWorkSession, sessionDate: $sessionDate, projectId: $projectId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PomodoroSessionRecordModel &&
        other.id == id &&
        other.taskId == taskId &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.durationInSeconds == durationInSeconds &&
        other.isWorkSession == isWorkSession &&
        other.sessionDate == sessionDate &&
        other.projectId == projectId;
    // other.soundUsed == soundUsed;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    taskId.hashCode ^
    startTime.hashCode ^
    endTime.hashCode ^
    durationInSeconds.hashCode ^
    isWorkSession.hashCode ^
    sessionDate.hashCode ^
    projectId.hashCode;
    // soundUsed.hashCode;
  }
}