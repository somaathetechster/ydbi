export type UserStatus = 'active' | 'suspended' | 'deleted'

export type SubscriptionTier = 'free' | 'pro' | 'team' | 'enterprise'

export interface User {
  id: string
  email: string
  displayName: string | null
  avatarUrl: string | null
  timezone: string
  locale: string
  status: UserStatus
  butlerName: string
  createdAt: string
}

export interface UserSubscription {
  tier: SubscriptionTier
  status: string
  currentPeriodStart: string | null
  currentPeriodEnd: string | null
  aiMessagesLimit: number | null
  voiceSecondsLimit: number | null
}

export interface UsageSummary {
  tier: SubscriptionTier
  aiMessagesUsed: number
  aiMessagesLimit: number | null
  aiMessagesUnlimited: boolean
  voiceSecondsUsed: number
  voiceSecondsLimit: number | null
  voiceSecondsUnlimited: boolean
}