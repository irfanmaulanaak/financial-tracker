import 'package:flutter/material.dart';

/// Color palette choice ("Warna" in Settings). [hangat] is the original
/// "Ceria keluarga" look and is the default — every other palette is opt-in.
enum FtPalette { hangat, netral, hutan, laut }

extension FtPaletteLabel on FtPalette {
  String get label => switch (this) {
        FtPalette.hangat => 'Hangat',
        FtPalette.netral => 'Netral',
        FtPalette.hutan => 'Hutan',
        FtPalette.laut => 'Laut',
      };
}

/// One brightness variant of a palette — every color [FtColors] exposes that
/// changes with the "Warna" setting (semantic + category colors stay fixed
/// across palettes, see [FtColors]).
class FtSwatch {
  const FtSwatch({
    required this.bg,
    required this.bgAlt,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.ink4,
    required this.line,
    required this.lineStrong,
    required this.clay,
    required this.navBar,
    required this.navActive,
    required this.navActiveInk,
    required this.navIcon,
    required this.fab,
    required this.onFab,
    required this.peach,
    required this.onPeach,
    required this.hero,
    required this.onHero,
    this.heroDanger = const Color(0xFFA02631),
  });

  final Color bg, bgAlt, surface, surfaceAlt;
  final Color ink, ink2, ink3, ink4;
  final Color line, lineStrong;
  final Color clay;
  final Color navBar, navActive, navActiveInk, navIcon;
  final Color fab, onFab;
  final Color peach, onPeach;

  /// Hero card fill (safe-to-spend) + its on-color. Distinct from [peach] so
  /// every palette keeps real contrast — on Netral, a tinted fill reads as a
  /// deliberate surface instead of grey-on-grey.
  final Color hero, onHero;

  /// Error-state tint for text drawn on [hero]. [hero]'s own brightness
  /// doesn't always track the theme's brightness (Netral's light hero is a
  /// dark fill), so this can't just be the theme's semantic `danger` color —
  /// it has to contrast with this specific swatch's [hero].
  final Color heroDanger;
}

class FtPaletteSwatches {
  const FtPaletteSwatches({required this.light, required this.dark});
  final FtSwatch light;
  final FtSwatch dark;
  FtSwatch pick(bool dark) => dark ? this.dark : light;
}

/// Default palette — exact colors of the original "Ceria keluarga" look.
/// Must never change: this is what every existing install already shows.
const hangatSwatches = FtPaletteSwatches(
  light: FtSwatch(
    bg: Color(0xFFFFF6EC),
    bgAlt: Color(0xFFF7EADB),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFFBF1E6),
    ink: Color(0xFF2A160C),
    ink2: Color(0xFF5A4033),
    ink3: Color(0xFF7A5A48),
    ink4: Color(0xFFB8A294),
    line: Color(0x142A160C),
    lineStrong: Color(0x292A160C),
    clay: Color(0xFFB8431F),
    navBar: Color(0xFFE6CFBA),
    navActive: Color(0xFFFFF6EC),
    navActiveInk: Color(0xFF7A4A30),
    navIcon: Color(0xFF6B4A38),
    fab: Color(0xFF7A4A30),
    onFab: Color(0xFFFFF6EC),
    peach: Color(0xFFFFB38A),
    onPeach: Color(0xFF2A160C),
    hero: Color(0xFFFFB38A),
    onHero: Color(0xFF2A160C),
  ),
  dark: FtSwatch(
    bg: Color(0xFF15110E),
    bgAlt: Color(0xFF1A1512),
    surface: Color(0xFF211B17),
    surfaceAlt: Color(0xFF2A221D),
    ink: Color(0xFFF6ECE4),
    ink2: Color(0xFFD9C8BC),
    ink3: Color(0xFFB39E90),
    ink4: Color(0xFF6E5E54),
    line: Color(0x14F6ECE4),
    lineStrong: Color(0x29F6ECE4),
    clay: Color(0xFFFFB38A),
    navBar: Color(0xFF241D18),
    navActive: Color(0xFF3A2E25),
    navActiveInk: Color(0xFFFFB38A),
    navIcon: Color(0xFFB39E90),
    fab: Color(0xFFFFB38A),
    onFab: Color(0xFF2A160C),
    peach: Color(0xFFFFB38A),
    onPeach: Color(0xFF2A160C),
    hero: Color(0xFFFFB38A),
    onHero: Color(0xFF2A160C),
  ),
);

/// Calm, modern fintech look: off-white/white, near-black text, graphite
/// accent — no warm tint. Hero fill uses a warm cream tint (not plain grey)
/// so it reads as a distinct surface against the grey background.
const netralSwatches = FtPaletteSwatches(
  light: FtSwatch(
    bg: Color(0xFFF4F3F1),
    bgAlt: Color(0xFFEAEAE6),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF6F5F3),
    ink: Color(0xFF1A1A1A),
    ink2: Color(0xFF4D4D4D),
    ink3: Color(0xFF707070),
    ink4: Color(0xFFA6A6A2),
    line: Color(0x141A1A1A),
    lineStrong: Color(0x291A1A1A),
    clay: Color(0xFF363636),
    navBar: Color(0xFFE6E5E1),
    navActive: Color(0xFFFFFFFF),
    navActiveInk: Color(0xFF262626),
    navIcon: Color(0xFF70706C),
    fab: Color(0xFF262626),
    onFab: Color(0xFFFFFFFF),
    peach: Color(0xFFD9D9D5),
    onPeach: Color(0xFF1A1A1A),
    hero: Color(0xFF262626),
    onHero: Color(0xFFF4F3F1),
    // hero is a dark fill here, unlike every other palette — needs a light
    // danger tint to read, not the usual dark red.
    heroDanger: Color(0xFFF29AA5),
  ),
  dark: FtSwatch(
    bg: Color(0xFF121212),
    bgAlt: Color(0xFF181818),
    surface: Color(0xFF1E1E1E),
    surfaceAlt: Color(0xFF242424),
    ink: Color(0xFFF2F2F0),
    ink2: Color(0xFFCFCFCB),
    ink3: Color(0xFFA3A39E),
    ink4: Color(0xFF6E6E6A),
    line: Color(0x14F2F2F0),
    lineStrong: Color(0x29F2F2F0),
    clay: Color(0xFFD8D8D4),
    navBar: Color(0xFF242424),
    navActive: Color(0xFF2E2E2E),
    navActiveInk: Color(0xFFD8D8D4),
    navIcon: Color(0xFFA3A39E),
    fab: Color(0xFFD8D8D4),
    onFab: Color(0xFF121212),
    peach: Color(0xFFD8D8D4),
    onPeach: Color(0xFF1A1A1A),
    hero: Color(0xFFD8D8D4),
    onHero: Color(0xFF121212),
  ),
);

/// Soft green-grey background, deep forest green accent.
const hutanSwatches = FtPaletteSwatches(
  light: FtSwatch(
    bg: Color(0xFFF2F5F1),
    bgAlt: Color(0xFFE8EDE6),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF5F8F3),
    ink: Color(0xFF1B2A1F),
    ink2: Color(0xFF44574A),
    ink3: Color(0xFF67796C),
    ink4: Color(0xFF9FAC9F),
    line: Color(0x141B2A1F),
    lineStrong: Color(0x291B2A1F),
    clay: Color(0xFF1F5C3C),
    navBar: Color(0xFFE2E9DE),
    navActive: Color(0xFFFFFFFF),
    navActiveInk: Color(0xFF1F5C3C),
    navIcon: Color(0xFF67796C),
    fab: Color(0xFF1F5C3C),
    onFab: Color(0xFFFFFFFF),
    peach: Color(0xFF7FD9A8),
    onPeach: Color(0xFF0F2E1C),
    hero: Color(0xFF7FD9A8),
    onHero: Color(0xFF0F2E1C),
  ),
  dark: FtSwatch(
    bg: Color(0xFF10140F),
    bgAlt: Color(0xFF171C14),
    surface: Color(0xFF1C221A),
    surfaceAlt: Color(0xFF222922),
    ink: Color(0xFFE8F0E6),
    ink2: Color(0xFFC3D2C0),
    ink3: Color(0xFF96A693),
    ink4: Color(0xFF5E6B5C),
    line: Color(0x14E8F0E6),
    lineStrong: Color(0x29E8F0E6),
    clay: Color(0xFF7FD9A8),
    navBar: Color(0xFF1C221A),
    navActive: Color(0xFF272F24),
    navActiveInk: Color(0xFF7FD9A8),
    navIcon: Color(0xFF96A693),
    fab: Color(0xFF7FD9A8),
    onFab: Color(0xFF0F2E1C),
    peach: Color(0xFF7FD9A8),
    onPeach: Color(0xFF0F2E1C),
    hero: Color(0xFF7FD9A8),
    onHero: Color(0xFF0F2E1C),
  ),
);

/// Soft blue-grey background, deep blue accent.
const lautSwatches = FtPaletteSwatches(
  light: FtSwatch(
    bg: Color(0xFFF1F4F7),
    bgAlt: Color(0xFFE6ECF1),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF4F7FA),
    ink: Color(0xFF141E2A),
    ink2: Color(0xFF3F4F5F),
    ink3: Color(0xFF647482),
    ink4: Color(0xFF9CAAB4),
    line: Color(0x14141E2A),
    lineStrong: Color(0x29141E2A),
    clay: Color(0xFF1F4E8C),
    navBar: Color(0xFFE1E8EF),
    navActive: Color(0xFFFFFFFF),
    navActiveInk: Color(0xFF1F4E8C),
    navIcon: Color(0xFF647482),
    fab: Color(0xFF1F4E8C),
    onFab: Color(0xFFFFFFFF),
    peach: Color(0xFF9EC2FF),
    onPeach: Color(0xFF0E1420),
    hero: Color(0xFF9EC2FF),
    onHero: Color(0xFF0E1420),
  ),
  dark: FtSwatch(
    bg: Color(0xFF0E1420),
    bgAlt: Color(0xFF141B29),
    surface: Color(0xFF182030),
    surfaceAlt: Color(0xFF1E2838),
    ink: Color(0xFFE7EEF5),
    ink2: Color(0xFFC2CEDA),
    ink3: Color(0xFF94A3B2),
    ink4: Color(0xFF5C6B7A),
    line: Color(0x14E7EEF5),
    lineStrong: Color(0x29E7EEF5),
    clay: Color(0xFF9EC2FF),
    navBar: Color(0xFF182030),
    navActive: Color(0xFF212C3F),
    navActiveInk: Color(0xFF9EC2FF),
    navIcon: Color(0xFF94A3B2),
    fab: Color(0xFF9EC2FF),
    onFab: Color(0xFF0E1420),
    peach: Color(0xFF9EC2FF),
    onPeach: Color(0xFF0E1420),
    hero: Color(0xFF9EC2FF),
    onHero: Color(0xFF0E1420),
  ),
);

const Map<FtPalette, FtPaletteSwatches> paletteSwatches = {
  FtPalette.hangat: hangatSwatches,
  FtPalette.netral: netralSwatches,
  FtPalette.hutan: hutanSwatches,
  FtPalette.laut: lautSwatches,
};
