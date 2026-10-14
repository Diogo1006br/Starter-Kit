import { afterEach, beforeEach, describe, expect, it } from 'vitest'

import { apiClient, clearToken, setToken } from '@/core/api/client'

describe('apiClient', () => {
  beforeEach(() => clearToken())
  afterEach(() => clearToken())

  async function authorizationHeader() {
    let header: unknown
    await apiClient.get('/ping', {
      adapter: async (config) => {
        header = config.headers.get('Authorization')
        return { data: {}, status: 200, statusText: 'OK', headers: {}, config }
      },
    })
    return header
  }

  it('sends no Authorization header without a token', async () => {
    expect(await authorizationHeader()).toBeUndefined()
  })

  it('sends the stored token as a Bearer header', async () => {
    setToken('abc')
    expect(await authorizationHeader()).toBe('Bearer abc')
  })
})
