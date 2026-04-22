import { useEffect, useState } from 'react';
import VoteForm from './components/VoteForm';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:4000';

export default function App() {
  const [results, setResults] = useState([]);
  const [status, setStatus] = useState('idle');

  async function loadResults() {
    setStatus('loading');
    const response = await fetch(`${API_URL}/api/votes/results`);
    const data = await response.json();
    setResults(data.results || []);
    setStatus('ready');
  }

  useEffect(() => {
    loadResults().catch(() => setStatus('error'));
  }, []);

  return (
    <main className="page">
      <section className="card">
        <h1>Citoyen Peyi</h1>
        <p>Plateforme de vote anonyme.</p>
        <VoteForm apiUrl={API_URL} onVoted={loadResults} />
      </section>

      <section className="card">
        <h2>Resultats en direct</h2>
        {status === 'loading' && <p>Chargement...</p>}
        {status === 'error' && <p>Impossible de charger les resultats.</p>}
        {status === 'ready' && results.length === 0 && <p>Aucun vote pour le moment.</p>}
        {results.map((item) => (
          <div key={item.option} className="result-line">
            <span>{item.option}</span>
            <strong>{item.count}</strong>
          </div>
        ))}
      </section>
    </main>
  );
}
