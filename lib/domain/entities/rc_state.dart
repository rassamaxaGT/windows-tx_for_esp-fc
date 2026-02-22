import 'package:equatable/equatable.dart';

class RCState extends Equatable {
  final double roll, pitch, yaw, throttle;
  final bool isArm, isMode, isExtra;

  const RCState({
    this.roll = 0,
    this.pitch = 0,
    this.yaw = 0,
    this.throttle = -1,
    this.isArm = false,
    this.isMode = false,
    this.isExtra = false,
  });

  RCState copyWith({
    double? roll,
    double? pitch,
    double? yaw,
    double? throttle,
    bool? isArm,
    bool? isMode,
    bool? isExtra,
  }) {
    return RCState(
      roll: roll ?? this.roll,
      pitch: pitch ?? this.pitch,
      yaw: yaw ?? this.yaw,
      throttle: throttle ?? this.throttle,
      isArm: isArm ?? this.isArm,
      isMode: isMode ?? this.isMode,
      isExtra: isExtra ?? this.isExtra,
    );
  }

  @override
  List<Object?> get props => [
    roll,
    pitch,
    yaw,
    throttle,
    isArm,
    isMode,
    isExtra,
  ];
}
