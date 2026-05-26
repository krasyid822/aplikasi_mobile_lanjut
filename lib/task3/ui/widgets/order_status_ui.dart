import 'package:flutter/material.dart';

const week3AdminStatusOptions = <String>[
  'baru',
  'diproses',
  'selesai',
  'permohonan_batal',
  'dibatalkan',
];

bool week3IsCurrentOrderStatus(String status) {
  return switch (status) {
    'baru' || 'diproses' || 'permohonan_batal' => true,
    _ => false,
  };
}

bool week3CanCustomerCancelDirectly(String status) {
  return status == 'baru';
}

bool week3CanCustomerRequestCancellation(String status) {
  return switch (status) {
    'baru' || 'permohonan_batal' || 'dibatalkan' => false,
    _ => true,
  };
}

String week3OrderStatusLabel(String status) {
  return switch (status) {
    'baru' => 'Baru',
    'diproses' => 'Diproses',
    'selesai' => 'Selesai',
    'permohonan_batal' => 'Permohonan Batal',
    'dibatalkan' => 'Dibatalkan',
    _ => status,
  };
}

String week3FormatOrderTimestamp(DateTime? timestamp) {
  if (timestamp == null) {
    return '-';
  }

  final day = timestamp.day.toString().padLeft(2, '0');
  final month = timestamp.month.toString().padLeft(2, '0');
  final year = timestamp.year.toString();
  final hour = timestamp.hour.toString().padLeft(2, '0');
  final minute = timestamp.minute.toString().padLeft(2, '0');
  final second = timestamp.second.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute:$second';
}

String week3FormatElapsedSince(DateTime? timestamp) {
  if (timestamp == null) {
    return '-';
  }

  final elapsed = DateTime.now().difference(timestamp);
  final totalSeconds = elapsed.inSeconds < 0 ? 0 : elapsed.inSeconds;
  final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
  final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$hours jam $minutes menit $seconds detik';
}

String week3FormatRemainingUntilExpiry(
  DateTime? timestamp, {
  Duration retention = const Duration(hours: 1),
}) {
  if (timestamp == null) {
    return '-';
  }

  final remaining = retention - DateTime.now().difference(timestamp);
  final totalSeconds = remaining.inSeconds <= 0 ? 0 : remaining.inSeconds;
  final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
  final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

IconData week3OrderStatusIcon(String status) {
  return switch (status) {
    'baru' => Icons.fiber_new_rounded,
    'diproses' => Icons.local_shipping_outlined,
    'selesai' => Icons.task_alt_rounded,
    'permohonan_batal' => Icons.gpp_maybe_outlined,
    'dibatalkan' => Icons.cancel_outlined,
    _ => Icons.receipt_long_outlined,
  };
}

class Week3OrderStatusColors {
  const Week3OrderStatusColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

Week3OrderStatusColors week3OrderStatusColors(
  BuildContext context,
  String status,
) {
  final scheme = Theme.of(context).colorScheme;
  final base = Theme.of(context).colorScheme.surfaceContainerHighest;

  Color blend(Color color, double opacity) {
    return Color.alphaBlend(color.withValues(alpha: opacity), base);
  }

  return switch (status) {
    'baru' => Week3OrderStatusColors(
      background: blend(scheme.primary, 0.15),
      foreground: scheme.primary,
      border: scheme.primary.withValues(alpha: 0.28),
    ),
    'diproses' => Week3OrderStatusColors(
      background: blend(scheme.tertiary, 0.18),
      foreground: scheme.tertiary,
      border: scheme.tertiary.withValues(alpha: 0.28),
    ),
    'selesai' => Week3OrderStatusColors(
      background: blend(scheme.secondary, 0.18),
      foreground: scheme.secondary,
      border: scheme.secondary.withValues(alpha: 0.28),
    ),
    'permohonan_batal' => Week3OrderStatusColors(
      background: blend(scheme.error, 0.12),
      foreground: scheme.error,
      border: scheme.error.withValues(alpha: 0.2),
    ),
    'dibatalkan' => Week3OrderStatusColors(
      background: blend(scheme.error, 0.22),
      foreground: scheme.error,
      border: scheme.error.withValues(alpha: 0.3),
    ),
    _ => Week3OrderStatusColors(
      background: base,
      foreground: scheme.onSurfaceVariant,
      border: scheme.outlineVariant,
    ),
  };
}

class Week3OrderStatusBadge extends StatelessWidget {
  const Week3OrderStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = week3OrderStatusColors(context, status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            week3OrderStatusIcon(status),
            size: compact ? 16 : 18,
            color: colors.foreground,
          ),
          const SizedBox(width: 6),
          Text(
            week3OrderStatusLabel(status),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class Week3OrderExpiryBadge extends StatelessWidget {
  const Week3OrderExpiryBadge({
    super.key,
    required this.completedAt,
    this.compact = false,
  });

  final DateTime? completedAt;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const orangeBase = Color(0xFFF57C00);
    const orangeAccent = Color(0xFFFF9800);
    final background = Color.alphaBlend(
      orangeAccent.withValues(alpha: 0.2),
      Theme.of(context).colorScheme.surfaceContainerHighest,
    );
    final foreground = Color.lerp(orangeBase, orangeAccent, 0.25) ?? orangeBase;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.28)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: compact ? 16 : 18,
              color: foreground,
            ),
            const SizedBox(width: 6),
            Text(
              '${week3FormatRemainingUntilExpiry(completedAt)} lagi orderan akan dihapus',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
