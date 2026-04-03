export type TaskStatus = 'pending' | 'in_progress' | 'completed' | 'cancelled'
export type TaskPriority = 'low' | 'medium' | 'high' | 'urgent'

export interface Task {
  id: string
  userId: string
  orgId: string | null
  title: string
  description: string | null
  status: TaskStatus
  priority: TaskPriority
  assignedTo: string | null
  dueAt: string | null
  completedAt: string | null
  tags: string[]
  createdAt: string
  updatedAt: string
}

export interface CreateTaskInput {
  title: string
  description?: string
  priority?: TaskPriority
  dueAt?: string
  tags?: string[]
}