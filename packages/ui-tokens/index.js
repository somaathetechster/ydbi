// @ydbi/ui-tokens
// Single source of truth for all design tokens.
// Used by web (CSS variables), iOS (Swift constants), Android (Compose theme).

export const colors = {
  // Butler core
  butlerCyan:       '#B8F0FF',
  butlerCyanDim:    '#6DCDE8',
  butlerWhite:      '#FFFFFF',

  // Backgrounds
  fieldBase:        '#0D0D0F',   // deepest layer — never flat black
  surfacePrimary:   '#131316',
  surfaceSecondary: '#1A1A1F',
  surfaceTertiary:  '#222228',

  // Text
  textPrimary:      '#F2F2F0',
  textSecondary:    '#9A9A94',
  textTertiary:     '#5A5A56',

  // Semantic
  success:          '#2ECC8A',
  warning:          '#F5A623',
  error:            '#E8503C',
  info:             '#4A9EFF',

  // Borders
  borderSubtle:     'rgba(255,255,255,0.06)',
  borderDefault:    'rgba(255,255,255,0.12)',
  borderStrong:     'rgba(255,255,255,0.22)',
}

export const typography = {
  // Display — Butler UI headings
  fontDisplay:    '"Barlow Condensed", sans-serif',
  weightDisplay:  900,

  // UI — interface elements
  fontUI:         '"Inter", system-ui, sans-serif',
  weightUI:       400,
  weightUIMedium: 500,

  // Mono — data, code, IDs
  fontMono:       '"JetBrains Mono", monospace',

  // Scale (px)
  size2xs: 10,
  sizeXs:  12,
  sizeSm:  13,
  sizeMd:  15,
  sizeLg:  17,
  sizeXl:  20,
  size2xl: 24,
  size3xl: 32,
  size4xl: 48,
}

export const motion = {
  // Durations (ms)
  instant:   80,
  fast:     180,
  normal:   280,
  slow:     440,
  crawl:    800,

  // Easings
  easeOut:      'cubic-bezier(0.16, 1, 0.3, 1)',
  easeIn:       'cubic-bezier(0.4, 0, 1, 1)',
  easeInOut:    'cubic-bezier(0.65, 0, 0.35, 1)',
  spring:       'cubic-bezier(0.34, 1.56, 0.64, 1)',  // slight overshoot
}

export const spacing = {
  px1:  4,
  px2:  8,
  px3:  12,
  px4:  16,
  px5:  20,
  px6:  24,
  px8:  32,
  px10: 40,
  px12: 48,
  px16: 64,
}

export const radii = {
  sm:   4,
  md:   8,
  lg:   12,
  xl:   16,
  full: 9999,
}