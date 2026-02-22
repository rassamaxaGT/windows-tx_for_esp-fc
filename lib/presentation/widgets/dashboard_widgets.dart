import 'package:flutter/material.dart';
import 'curve_painter.dart';

class AxisDisplay extends StatelessWidget {
  final String label;
  final double raw, proc;
  final double ex, dz, sc;
  final bool inv;
  final Color color;
  final ValueChanged<bool?> onInv;
  final ValueChanged<double> onEx, onDz, onSc;
  final ValueChanged<String> onLabelChanged;

  const AxisDisplay({
    super.key,
    required this.label,
    required this.raw,
    required this.proc,
    required this.ex,
    required this.dz,
    required this.sc,
    required this.inv,
    required this.color,
    required this.onInv,
    required this.onEx,
    required this.onDz,
    required this.onSc,
    required this.onLabelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF252525),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomPaint(
                      painter: CurvePainter(
                        expo: ex,
                        deadzone: dz,
                        scale: sc,
                        currentValue: raw,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    // ИСПРАВЛЕНО: withValues
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    proc.toStringAsFixed(2),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок и чекбокс
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // ИСПОЛЬЗУЕМ EditableLabel
                          EditableLabel(
                            label: label,
                            onChanged: onLabelChanged,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            "INVERT",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[400],
                            ),
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: inv,
                              onChanged: onInv,
                              // ИСПРАВЛЕНО: activeThumbColor вместо activeColor
                              activeThumbColor: Colors.redAccent,
                              activeTrackColor: Colors.redAccent.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  _ModernSlider(
                    label: "RATE",
                    value: sc,
                    min: 0.1,
                    max: 1.2,
                    onChanged: onSc,
                    color: Colors.blueAccent,
                  ),
                  _ModernSlider(
                    label: "EXPO",
                    value: ex,
                    min: 1.0,
                    max: 3.5,
                    onChanged: onEx,
                    color: Colors.orangeAccent,
                  ),
                  _ModernSlider(
                    label: "DEAD",
                    value: dz,
                    min: 0.0,
                    max: 0.2,
                    onChanged: onDz,
                    color: Colors.redAccent,
                  ),

                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (proc + 1) / 2,
                      color: color,
                      backgroundColor: Colors.white10,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernSlider extends StatelessWidget {
  final String label;
  final double value, min, max;
  final ValueChanged<double> onChanged;
  final Color color;

  const _ModernSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          SizedBox(
            width: 35,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                // ИСПРАВЛЕНО: withValues
                activeTrackColor: color.withValues(alpha: 0.8),
                inactiveTrackColor: Colors.white10,
                thumbColor: Colors.white,
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              value.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}

class SwitchDisplay extends StatelessWidget {
  final String label;
  final bool active;
  final ValueChanged<String> onLabelChanged;
  const SwitchDisplay({
    super.key,
    required this.label,
    required this.active,
    required this.onLabelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        // ИСПРАВЛЕНО: withValues
        color: active
            ? Colors.green.withValues(alpha: 0.2)
            : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          EditableLabel(
            label: label,
            onChanged: onLabelChanged,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: active ? Colors.white : Colors.grey,
            ),
          ),
          
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? Colors.green : Colors.black38,
              boxShadow: active
                  ? [BoxShadow(color: Colors.green, blurRadius: 6)]
                  : [],
            ),
          ),
        ],
      ),
    );
  }
}

// Новый виджет для редактируемого текста
class EditableLabel extends StatelessWidget {
  final String label;
  final ValueChanged<String> onChanged;
  final TextStyle? style;

  const EditableLabel({
    super.key,
    required this.label,
    required this.onChanged,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showEditDialog(context),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: style),
            const SizedBox(width: 4),
            Icon(
              Icons.edit,
              size: 10,
              color: Colors.white.withValues(alpha: 0.3),
            ), // Подсказка
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: label);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: const Text(
          "Rename Label",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter new name",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              onChanged(controller.text);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
