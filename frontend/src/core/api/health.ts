import { apiClient } from './client'
import { unwrap, type ApiSuccess } from './envelope'

export interface Health {
  app: string
  status: 'ok' | 'degraded'
  checks: { database: boolean; redis: boolean }
}

export async function fetchHealth(): Promise<Health> {
  const response = await apiClient.get<ApiSuccess<Health>>('/health')

  return unwrap(response.data)
}
