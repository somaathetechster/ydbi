import type { ButlerState } from '@ydbi/sdk'

// Valid state transitions — enforces the Butler state machine at the type level.
const TRANSITIONS: Record<ButlerState, ButlerState[]> = {
  dormant:    ['ambient'],
  ambient:    ['listening', 'dormant'],
  listening:  ['processing', 'ambient'],
  processing: ['speaking', 'confirming', 'ambient'],
  speaking:   ['ambient', 'listening'],
  confirming: ['ambient', 'listening'],
}

export class ButlerStateMachine {
  private state: ButlerState

  constructor(initialState: ButlerState = 'ambient') {
    this.state = initialState
  }

  get current(): ButlerState {
    return this.state
  }

  canTransition(to: ButlerState): boolean {
    return TRANSITIONS[this.state]?.includes(to) ?? false
  }

  transition(to: ButlerState): void {
    if (!this.canTransition(to)) {
      throw new Error(
        `Invalid Butler state transition: ${this.state} → ${to}. ` +
        `Allowed: ${TRANSITIONS[this.state]?.join(', ') ?? 'none'}`
      )
    }
    this.state = to
  }

  // Attempt transition — returns false instead of throwing if invalid.
  tryTransition(to: ButlerState): boolean {
    if (!this.canTransition(to)) return false
    this.state = to
    return true
  }
}