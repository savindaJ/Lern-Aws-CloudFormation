import { useState } from 'react'
import reactLogo from './assets/react.svg'
import viteLogo from './assets/vite.svg'
import heroImg from './assets/hero.png'
import { config, hasApi } from './config'
import { fetchHealth, sendChat } from './lib/api'
import './App.css'

function App() {
  const [count, setCount] = useState(0)
  const [health, setHealth] = useState<string | null>(null)
  const [chatReply, setChatReply] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function onHealthCheck() {
    setLoading(true)
    setError(null)
    try {
      const data = await fetchHealth()
      setHealth(JSON.stringify(data, null, 2))
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Health check failed')
    } finally {
      setLoading(false)
    }
  }

  async function onChatTest() {
    setLoading(true)
    setError(null)
    try {
      const data = await sendChat('Hello from the frontend')
      setChatReply(data.reply)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Chat request failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <>
      <section id="center">
        <div className="deploy-panel">
          <h2>Deployment</h2>
          <dl>
            <dt>Stage</dt>
            <dd>{config.stage}</dd>
            <dt>App URL (CloudFront)</dt>
            <dd>
              {config.appUrl ? (
                <a href={config.appUrl} target="_blank" rel="noreferrer">
                  {config.appUrl}
                </a>
              ) : (
                '—'
              )}
            </dd>
            <dt>API URL</dt>
            <dd>{config.apiUrl || '— deploy backend first —'}</dd>
          </dl>
          {hasApi && (
            <div className="api-actions">
              <button type="button" onClick={onHealthCheck} disabled={loading}>
                Test /health
              </button>
              <button type="button" onClick={onChatTest} disabled={loading}>
                Test /ai/chat
              </button>
            </div>
          )}
          {health && <pre className="api-result">{health}</pre>}
          {chatReply && <p className="api-result">AI: {chatReply}</p>}
          {error && <p className="api-error">{error}</p>}
        </div>

        <div className="hero">
          <img src={heroImg} className="base" width="170" height="179" alt="" />
          <img src={reactLogo} className="framework" alt="React logo" />
          <img src={viteLogo} className="vite" alt="Vite logo" />
        </div>
        <div>
          <h1>Get started</h1>
          <p>
            Edit <code>src/App.tsx</code> and save to test <code>HMR</code>
          </p>
        </div>
        <button
          type="button"
          className="counter"
          onClick={() => setCount((count) => count + 1)}
        >
          Count is {count}
        </button>
      </section>

      <div className="ticks" />

      <section id="next-steps">
        <div id="docs">
          <svg className="icon" role="presentation" aria-hidden="true">
            <use href="/icons.svg#documentation-icon"></use>
          </svg>
          <h2>Documentation</h2>
          <p>Your questions, answered</p>
          <ul>
            <li>
              <a href="https://vite.dev/" target="_blank" rel="noreferrer">
                <img className="logo" src={viteLogo} alt="" />
                Explore Vite
              </a>
            </li>
            <li>
              <a href="https://react.dev/" target="_blank" rel="noreferrer">
                <img className="button-icon" src={reactLogo} alt="" />
                Learn more
              </a>
            </li>
          </ul>
        </div>
        <div id="social">
          <svg className="icon" role="presentation" aria-hidden="true">
            <use href="/icons.svg#social-icon"></use>
          </svg>
          <h2>Connect with us</h2>
          <p>Join the Vite community</p>
          <ul>
            <li>
              <a href="https://github.com/vitejs/vite" target="_blank" rel="noreferrer">
                <svg className="button-icon" role="presentation" aria-hidden="true">
                  <use href="/icons.svg#github-icon"></use>
                </svg>
                GitHub
              </a>
            </li>
            <li>
              <a href="https://chat.vite.dev/" target="_blank" rel="noreferrer">
                <svg className="button-icon" role="presentation" aria-hidden="true">
                  <use href="/icons.svg#discord-icon"></use>
                </svg>
                Discord
              </a>
            </li>
          </ul>
        </div>
      </section>

      <div className="ticks" />
      <section id="spacer" />
    </>
  )
}

export default App
