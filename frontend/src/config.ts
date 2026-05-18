export const config = {
  stage: import.meta.env.VITE_STAGE || 'local',
  apiUrl: import.meta.env.VITE_API_URL || '',
  appUrl: import.meta.env.VITE_APP_URL || window.location.origin,
} as const

export const hasApi = Boolean(config.apiUrl)
