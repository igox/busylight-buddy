import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/busylight_color.dart';
import '../models/busylight_status.dart';
import '../models/color_preset.dart';
import '../providers/busylight_provider.dart';
import '../providers/presets_provider.dart';
import '../widgets/brightness_slider.dart';
import '../widgets/status_button.dart';
import 'settings_screen.dart';

// ── App bar shared between screens ───────────────────────────────────────────

AppBar _buildAppBar(BuildContext context) => AppBar(
  backgroundColor: Colors.black,
  title: const Text('BusyLight', style: TextStyle(color: Colors.white)),
  actions: [
    IconButton(
      icon: const Icon(Icons.settings_outlined, color: Colors.white),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ),
    ),
  ],
);

// ── HomeScreen ────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot    = ref.watch(busylightSnapshotProvider);
    final statusAsync = ref.watch(busylightStatusProvider);

    // Start background polling (no-op if already running)
    ref.watch(pollingProvider);

    if (!snapshot.hasValue && !snapshot.hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(context),
        body: const Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }
    if (snapshot.hasError && !statusAsync.hasValue) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(context),
        body: _ErrorView(
          message: snapshot.error.toString(),
          onRetry: () => ref.invalidate(busylightSnapshotProvider),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(context),
      // _Body reads all providers itself — no props passed down
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(busylightStatusProvider.notifier).refresh(),
        ),
        data: (_) => const _Body(),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────
// ConsumerStatefulWidget so ref is stable across rebuilds and dialogs.
// Reads all providers itself — receives NO props from HomeScreen.

class _Body extends ConsumerStatefulWidget {
  const _Body();

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  BusylightStatus? _pendingStatus;
  String? _pendingPresetId;

  Color _statusColor(BusylightStatus status, BusylightColor color) {
    switch (status) {
      case BusylightStatus.available: return Colors.green;
      case BusylightStatus.away:      return Colors.orange;
      case BusylightStatus.busy:      return Colors.red;
      case BusylightStatus.on:        return Colors.white;
      case BusylightStatus.off:       return Colors.grey.shade900;
      case BusylightStatus.colored:   return color.toFlutterColor();
    }
  }

  Future<void> _setStatus(BusylightStatus s) async {
    setState(() => _pendingStatus = s);
    await ref.read(busylightStatusProvider.notifier).setStatus(s);
    if (mounted) setState(() => _pendingStatus = null);
  }

  Future<void> _applyPreset(ColorPreset preset) async {
    setState(() => _pendingPresetId = preset.id);
    await ref.read(colorProvider.notifier).set(preset.color);
    ref.read(busylightStatusProvider.notifier).setLocalStatus(BusylightStatus.colored);
    if (mounted) setState(() => _pendingPresetId = null);
  }

  void _editPreset(ColorPreset preset) {
    _openColorPicker(preset.color, ref.read(brightnessProvider), editingPreset: preset);
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(busylightStatusProvider);
    final brightness  = ref.watch(brightnessProvider);
    final color       = ref.watch(colorProvider);
    final presets     = ref.watch(presetsProvider);

    final status = statusAsync.valueOrNull ?? BusylightStatus.off;
    final displayColor = _statusColor(status, color);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Live color preview dot
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: status == BusylightStatus.off
                  ? Colors.grey.shade900
                  : displayColor.withOpacity(brightness),
              boxShadow: status != BusylightStatus.off
                  ? [BoxShadow(
                      color: displayColor.withOpacity(0.5 * brightness),
                      blurRadius: 40,
                      spreadRadius: 8,
                    )]
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            status.label.toUpperCase(),
            style: const TextStyle(color: Colors.grey, letterSpacing: 2, fontSize: 13),
          ),
        ),
        const SizedBox(height: 36),

        // Quick status
        const _SectionLabel('Quick status'),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: [
            BusylightStatus.available,
            BusylightStatus.away,
            BusylightStatus.busy,
            BusylightStatus.on,
            BusylightStatus.off,
          ].map((s) => StatusButton(
            status: s,
            isActive: status == s,
            isPending: _pendingStatus == s,
            onTap: _pendingStatus == null ? () => _setStatus(s) : () {},
          )).toList(),
        ),
        const SizedBox(height: 32),

        // Custom presets + add button (horizontal scroll, never pushes content down)
        _PresetsScroller(
          presets: presets,
          pendingPresetId: _pendingPresetId,
          onPresetTap: (_pendingStatus == null && _pendingPresetId == null)
              ? _applyPreset
              : (_) {},
          onPresetDelete: (preset) => ref.read(presetsProvider.notifier).remove(preset.id),
          onPresetEdit: _editPreset,
          onAddTap: () => _openColorPicker(color, brightness),
        ),
        const SizedBox(height: 32),

        // Brightness
        const _SectionLabel('Brightness'),
        const SizedBox(height: 8),
        BrightnessSlider(
          value: brightness,
          onChanged: (v) => ref.read(brightnessProvider.notifier).set(v),
        ),
        const SizedBox(height: 40),

        // Refresh
        Center(
          child: TextButton.icon(
            onPressed: () => ref.invalidate(busylightSnapshotProvider),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh status'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
          ),
        ),
      ],
    );
  }

  // ── Color picker dialog ───────────────────────────────────────────────────

  void _openColorPicker(BusylightColor currentColor, double currentBrightness, {ColorPreset? editingPreset}) {
    Color pickerColor = currentColor.toFlutterColor();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text(
            editingPreset != null ? 'Edit color' : 'Pick a color',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ColorPicker(
                  pickerColor: pickerColor,
                  onColorChanged: (c) => setDialogState(() => pickerColor = c),
                  pickerAreaHeightPercent: 0.7,
                  enableAlpha: false,
                  displayThumbColor: true,
                  labelTypes: const [],
                ),
                SlidePicker(
                  pickerColor: pickerColor,
                  onColorChanged: (c) => setDialogState(() => pickerColor = c),
                  colorModel: ColorModel.rgb,
                  enableAlpha: false,
                  displayThumbColor: true,
                  showParams: true,
                  showIndicator: false,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            if (editingPreset == null)
              OutlinedButton(
                onPressed: () {
                  final picked = BusylightColor.fromFlutterColor(
                    pickerColor, brightness: currentBrightness,
                  );
                  Navigator.pop(ctx);
                  ref.read(colorProvider.notifier).set(picked);
                  ref.read(busylightStatusProvider.notifier).setLocalStatus(BusylightStatus.colored);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Apply only'),
              ),
            ElevatedButton.icon(
              onPressed: () {
                final picked = BusylightColor.fromFlutterColor(
                  pickerColor, brightness: currentBrightness,
                );
                Navigator.pop(ctx);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _openNameDialog(picked, editingPreset: editingPreset);
                });
              },
              icon: const Icon(Icons.bookmark_outline, size: 16, color: Colors.black),
              label: Text(
                editingPreset != null ? 'Save' : 'Save & Apply',
                style: const TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            ),
          ],
        ),
      ),
    );
  }

  // ── Preset name dialog ────────────────────────────────────────────────────

  void _openNameDialog(BusylightColor color, {ColorPreset? editingPreset}) {
    showDialog(
      context: context,
      builder: (ctx) => _NamePresetDialog(
        initialName: editingPreset?.name ?? '',
        onSave: (name) {
          if (editingPreset != null) {
            // Edit mode: only update the saved preset, do not touch the BusyLight
            ref.read(presetsProvider.notifier).update(editingPreset.id, name, color);
          } else {
            // Create mode: save preset and apply color to BusyLight
            ref.read(presetsProvider.notifier).add(name, color);
            ref.read(colorProvider.notifier).set(color);
            ref.read(busylightStatusProvider.notifier).setLocalStatus(BusylightStatus.colored);
          }
        },
      ),
    );
  }
}

// ── Presets scroller with overflow indicator ──────────────────────────────────

class _PresetsScroller extends StatefulWidget {
  final List<ColorPreset> presets;
  final String? pendingPresetId;
  final ValueChanged<ColorPreset> onPresetTap;
  final ValueChanged<ColorPreset> onPresetDelete;
  final ValueChanged<ColorPreset> onPresetEdit;
  final VoidCallback onAddTap;

  const _PresetsScroller({
    required this.presets,
    required this.onPresetTap,
    required this.onPresetDelete,
    required this.onPresetEdit,
    required this.onAddTap,
    this.pendingPresetId,
  });

  @override
  State<_PresetsScroller> createState() => _PresetsScrollerState();
}

class _PresetsScrollerState extends State<_PresetsScroller> {
  final _scrollController = ScrollController();
  bool _hasOverflow = false;
  int _hiddenCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateOverflow());
  }

  @override
  void didUpdateWidget(_PresetsScroller old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateOverflow());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() => _updateOverflow();

  void _updateOverflow() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final overflow = pos.maxScrollExtent - pos.pixels;
    final hasMore = overflow > 10;

    // Estimate hidden count: avg chip ~110px wide + 10px gap
    // Subtract 1 to exclude the "+ New" chip from the count
    final hidden = hasMore ? ((overflow / 120).ceil() - 1).clamp(0, 999) : 0;

    if (hasMore != _hasOverflow || hidden != _hiddenCount) {
      setState(() {
        _hasOverflow = hasMore;
        _hiddenCount = hidden;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: "Custom" label + overflow count on the same line
        Row(
          children: [
            Text(
              'Custom',
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 13,
                letterSpacing: 0.3,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_hasOverflow && _hiddenCount > 0) ...[
              const SizedBox(width: 8),
              Text(
                '· +$_hiddenCount more',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...widget.presets.map((preset) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _PresetChip(
                      preset: preset,
                      isPending: widget.pendingPresetId == preset.id,
                      onTap: () => widget.onPresetTap(preset),
                      onDelete: () => widget.onPresetDelete(preset),
                      onEdit: widget.onPresetEdit,
                    ),
                  )),
                  GestureDetector(
                    onTap: widget.onAddTap,
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade800, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.grey.shade600, size: 16),
                          const SizedBox(width: 6),
                          Text('New', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Fade + arrow overlay on the right edge
            if (_hasOverflow)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Colors.black.withOpacity(0), Colors.black],
                      ),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.chevron_right, color: Colors.grey.shade500, size: 20),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Name preset dialog ────────────────────────────────────────────────────────

class _NamePresetDialog extends StatefulWidget {
  final ValueChanged<String> onSave;
  final String initialName;
  const _NamePresetDialog({required this.onSave, this.initialName = ''});

  @override
  State<_NamePresetDialog> createState() => _NamePresetDialogState();
}

class _NamePresetDialogState extends State<_NamePresetDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    // Select all text so user can type a new name immediately
    _controller.selection = TextSelection(
      baseOffset: 0, extentOffset: widget.initialName.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context);
    widget.onSave(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      title: Text(
        widget.initialName.isNotEmpty ? 'Rename preset' : 'Name this preset',
        style: const TextStyle(color: Colors.white),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 20,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'e.g. Love, Focus, Chill…',
          hintStyle: TextStyle(color: Colors.grey.shade600),
          counterStyle: TextStyle(color: Colors.grey.shade600),
          filled: true,
          fillColor: Colors.grey.shade800,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
          child: const Text('Save', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }
}

// ── Preset chip ───────────────────────────────────────────────────────────────

class _PresetChip extends StatelessWidget {
  final ColorPreset preset;
  final bool isPending;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<ColorPreset> onEdit;

  const _PresetChip({
    required this.preset,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = preset.color.toFlutterColor();
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showOptions(context),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: chipColor.withOpacity(0.08),
          border: Border.all(color: chipColor.withOpacity(0.5), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isPending
                ? SizedBox(
                    width: 9,
                    height: 9,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation(chipColor),
                    ),
                  )
                : Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(color: chipColor, shape: BoxShape.circle),
                  ),
            const SizedBox(width: 8),
            Text(preset.name, style: TextStyle(color: Colors.grey.shade200, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: preset.color.toFlutterColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    preset.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFF2a2a2a)),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.white),
              title: const Text('Edit', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                onEdit(preset);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
              title: Text('Delete', style: TextStyle(color: Colors.red.shade400)),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: Colors.grey.shade300,
      fontSize: 13,
      letterSpacing: 0.3,
      fontWeight: FontWeight.w600,
    ),
  );
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatefulWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  State<_ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<_ErrorView> {
  bool _showDetails = false;

  String get _friendlyMessage {
    const hint = '\nAlso double-check the device address in ⚙ Settings.';
    final m = widget.message.toLowerCase();
    if (m.contains('socket') || m.contains('network') || m.contains('connection refused'))
      return 'Make sure your BusyLight is powered on and connected to the same Wi-Fi network.$hint';
    if (m.contains('timeout'))
      return 'Connection timed out. Your BusyLight may be out of range or busy.$hint';
    if (m.contains('404') || m.contains('not found'))
      return 'BusyLight was reached but returned an unexpected response.$hint';
    if (m.contains('host') || m.contains('lookup'))
      return 'Could not find your BusyLight on the network.$hint';
    return 'Could not connect to your BusyLight.$hint';
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, color: Colors.grey, size: 48),
          const SizedBox(height: 16),
          const Text('Cannot reach BusyLight',
              style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 8),
          Text(_friendlyMessage,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),

          // Collapsible details
          GestureDetector(
            onTap: () => setState(() => _showDetails = !_showDetails),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Details',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showDetails ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey.shade600,
                  size: 16,
                ),
              ],
            ),
          ),
          if (_showDetails) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: Text(
                widget.message,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('Retry', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    ),
  );
}