import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { afterEach, describe, expect, it, vi } from 'vitest'

import App from '@/App'
import * as health from '@/core/api/health'

afterEach(() => vi.restoreAllMocks())

function renderApp() {
  return render(
    <MemoryRouter>
      <App />
    </MemoryRouter>,
  )
}

describe('App', () => {
  it('shows the status of each backing service', async () => {
    vi.spyOn(health, 'fetchHealth').mockResolvedValue({
      app: 'Starter',
      status: 'ok',
      checks: { database: true, redis: false },
    })

    renderApp()

    const list = await screen.findByRole('list', { name: 'Service status' })
    expect(list).toHaveTextContent('PostgreSQL')
    expect(list).toHaveTextContent('Redis')
    expect(list).toHaveTextContent('down')
  })

  it('shows an alert when the API is unreachable', async () => {
    vi.spyOn(health, 'fetchHealth').mockRejectedValue(new Error('network'))

    renderApp()

    expect(await screen.findByRole('alert')).toHaveTextContent('Could not reach the API.')
  })
})
