import 'package:intl/intl.dart';

/// ValueFormatters — single home for all human-readable conversion.
///
/// Centralizing here lets us localize once when we add Hindi support,
/// and lets every screen call the same `Fmt.duration(d)` / `Fmt.compactInt(n)`
/// instead of reinventing a `padLeft(2, '0')` snippet on each surface.
class Fmt {
  Fmt._();

  /// "12:34" or "01:23:45" — depending on whether the duration crosses
  /// the 1-hour mark.
  static String duration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    String two(int n) => n.toString().padLeft(2, '0');
    if (hours > 0) return '${two(hours)}:${two(minutes)}:${two(seconds)}';
    return '${two(minutes)}:${two(seconds)}';
  }

  /// "5m", "2h 14m" — compact relative duration. Drops seconds.
  static String relativeDuration(Duration d) {
    if (d.inDays >= 1) return '${d.inDays}d';
    if (d.inHours >= 1) {
      final mins = d.inMinutes.remainder(60);
      return mins == 0 ? '${d.inHours}h' : '${d.inHours}h ${mins}m';
    }
    if (d.inMinutes >= 1) return '${d.inMinutes}m';
    return '${d.inSeconds}s';
  }

  /// "1.2K", "3.4M" — human-friendly large-int formatting.
  static String compactInt(num n) {
    if (n.abs() < 1000) return n.toString();
    if (n.abs() < 1000000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    }
    if (n.abs() < 1000000000) {
      return '${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)}M';
    }
    return '${(n / 1000000000).toStringAsFixed(1)}B';
  }

  /// "₹1,200", "₹15,499.99" — Indian rupee with thousands separator.
  static String inr(num amount, {int decimals = 0}) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: decimals,
    );
    return formatter.format(amount);
  }

  /// "12 May 2025" — readable date.
  static String date(DateTime dt) {
    return DateFormat('d MMM yyyy').format(dt);
  }

  /// "12 May 2025 · 3:45 PM" — readable date + time.
  static String dateTime(DateTime dt) {
    return DateFormat("d MMM yyyy '·' h:mm a").format(dt);
  }

  /// "Just now", "5m ago", "2h ago", "3d ago", "12 May" — relative
  /// timestamp suitable for chat bubbles, notifications, history.
  static String relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 30) return 'Just now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (dt.year == DateTime.now().year) {
      return DateFormat('d MMM').format(dt);
    }
    return DateFormat('d MMM yyyy').format(dt);
  }

  /// "75%" — percentage from a 0..1 ratio. Clamps & rounds.
  static String percent(double ratio, {int decimals = 0}) {
    final pct = (ratio.clamp(0.0, 1.0) * 100);
    return '${pct.toStringAsFixed(decimals)}%';
  }
}
