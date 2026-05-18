import { config } from '../config'

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  if (!config.apiUrl) {
    throw new Error('VITE_API_URL is not set. Deploy backend or set env for local build.')
  }
  const res = await fetch(`${config.apiUrl}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      ...init?.headers,
    },
  })
  const data = await res.json()
  if (!res.ok) {
    throw new Error(data.error || data.detail || `HTTP ${res.status}`)
  }
  return data as T
}

export type HealthResponse = {
  status: string
  service: string
  stage: string
  timestamp: string
}

export type ChatResponse = {
  reply: string
  source: string
  stage: string
}

export function fetchHealth() {
  return request<HealthResponse>('/health')
}

export function sendChat(message: string) {
  return request<ChatResponse>('/ai/chat', {
    method: 'POST',
    body: JSON.stringify({ message }),
  })
}
