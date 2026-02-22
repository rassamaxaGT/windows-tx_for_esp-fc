class RCPreset {
  final String name;
  final bool invRoll, invPitch, invYaw, invThrottle;
  final double exRoll, exPitch, exYaw, exThr;
  final double dzRoll, dzPitch, dzYaw, dzThr;
  final double scRoll, scPitch, scYaw, scThr;
  
  // Новые поля для имен (n - name)
  final String nRoll, nPitch, nYaw, nThr;
  final String nAux1, nAux2, nAux3;

  const RCPreset({
    required this.name,
    this.invRoll = false, this.invPitch = true, this.invYaw = false, this.invThrottle = false,
    this.exRoll = 1.0, this.exPitch = 1.0, this.exYaw = 1.0, this.exThr = 1.0,
    this.dzRoll = 0.04, this.dzPitch = 0.04, this.dzYaw = 0.04, this.dzThr = 0.0,
    this.scRoll = 1.0, this.scPitch = 1.0, this.scYaw = 1.0, this.scThr = 1.0,
    // Дефолтные имена
    this.nRoll = "ROLL", this.nPitch = "PITCH", this.nYaw = "YAW", this.nThr = "THROTTLE",
    this.nAux1 = "ARM", this.nAux2 = "MODE", this.nAux3 = "FS",
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'invRoll': invRoll, 'invPitch': invPitch, 'invYaw': invYaw, 'invThrottle': invThrottle,
    'exRoll': exRoll, 'exPitch': exPitch, 'exYaw': exYaw, 'exThr': exThr,
    'dzRoll': dzRoll, 'dzPitch': dzPitch, 'dzYaw': dzYaw, 'dzThr': dzThr,
    'scRoll': scRoll, 'scPitch': scPitch, 'scYaw': scYaw, 'scThr': scThr,
    // Сохраняем имена
    'nRoll': nRoll, 'nPitch': nPitch, 'nYaw': nYaw, 'nThr': nThr,
    'nAux1': nAux1, 'nAux2': nAux2, 'nAux3': nAux3,
  };

  factory RCPreset.fromJson(Map<String, dynamic> json) => RCPreset(
    name: json['name'],
    invRoll: json['invRoll'], invPitch: json['invPitch'], invYaw: json['invYaw'], invThrottle: json['invThrottle'],
    exRoll: json['exRoll'], exPitch: json['exPitch'], exYaw: json['exYaw'], exThr: json['exThr'],
    dzRoll: json['dzRoll'], dzPitch: json['dzPitch'], dzYaw: json['dzYaw'], dzThr: json['dzThr'],
    scRoll: (json['scRoll'] as num?)?.toDouble() ?? 1.0,
    scPitch: (json['scPitch'] as num?)?.toDouble() ?? 1.0,
    scYaw: (json['scYaw'] as num?)?.toDouble() ?? 1.0,
    scThr: (json['scThr'] as num?)?.toDouble() ?? 1.0,
    // Загружаем имена (с фоллбэком на стандартные)
    nRoll: json['nRoll'] ?? "ROLL",
    nPitch: json['nPitch'] ?? "PITCH",
    nYaw: json['nYaw'] ?? "YAW",
    nThr: json['nThr'] ?? "THROTTLE",
    nAux1: json['nAux1'] ?? "ARM",
    nAux2: json['nAux2'] ?? "MODE",
    nAux3: json['nAux3'] ?? "FS",
  );
}