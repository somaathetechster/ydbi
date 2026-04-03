// @ydbi/butler-core
// Butler persona state machine, intent classifier, emotional register detector,
// and memory injection coordinator.
// This package runs server-side only — never imported into browser bundles.

export { ButlerStateMachine } from './state-machine.js'
export { classifyIntent } from './intent-classifier.js'
export { detectEmotionalRegister } from './emotional-register.js'
export type { Intent, EmotionalRegister, ButlerContext } from './types.js'