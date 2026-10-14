import { useEffect, useState } from 'react'
import { Route, Routes } from 'react-router-dom'

import { fetchHealth, type Health } from '@/core/api/health'

type State = { kind: 'loading' } | { kind: 'ready'; health: Health } | { kind: 'error' }

function Status({ label, ok }: { label: string; ok: boolean }) {
  return (
    <li className="flex items-center justify-between gap-6">
      <span>{label}</span>
      <span className={ok ? 'text-emerald-600' : 'text-red-600'}>{ok ? 'connected' : 'down'}</span>
    </li>
  )
}

function Home() {
  const [state, setState] = useState<State>({ kind: 'loading' })

  useEffect(() => {
    fetchHealth()
      .then((health) => setState({ kind: 'ready', health }))
      .catch(() => setState({ kind: 'error' }))
  }, [])

  return (
    <main className="mx-auto max-w-md p-8">
      <h1 className="mb-4 text-2xl font-semibold">Starter</h1>
      {state.kind === 'loading' && <p>Checking API…</p>}
      {state.kind === 'error' && <p role="alert">Could not reach the API.</p>}
      {state.kind === 'ready' && (
        <ul className="space-y-2" aria-label="Service status">
          <Status label="API" ok />
          <Status label="PostgreSQL" ok={state.health.checks.database} />
          <Status label="Redis" ok={state.health.checks.redis} />
        </ul>
      )}
    </main>
  )
}

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Home />} />
      <Route path="*" element={<p className="p-8">Page not found.</p>} />
    </Routes>
  )
}
