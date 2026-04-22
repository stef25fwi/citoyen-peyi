import { useState } from 'react';

const DEFAULT_OPTIONS = ['Option A', 'Option B', 'Option C'];

export default function VoteForm({ apiUrl, onVoted }) {
  const [option, setOption] = useState(DEFAULT_OPTIONS[0]);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');

  async function submitVote(event) {
    event.preventDefault();
    setLoading(true);
    setMessage('');

    try {
      const response = await fetch(`${apiUrl}/api/votes`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ option })
      });

      if (!response.ok) {
        throw new Error('Echec vote');
      }

      setMessage('Vote enregistre.');
      await onVoted();
    } catch {
      setMessage('Erreur lors de lenvoi du vote.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={submitVote} className="vote-form">
      <label htmlFor="option">Choisir une option</label>
      <select id="option" value={option} onChange={(event) => setOption(event.target.value)}>
        {DEFAULT_OPTIONS.map((item) => (
          <option key={item} value={item}>
            {item}
          </option>
        ))}
      </select>
      <button type="submit" disabled={loading}>
        {loading ? 'Envoi...' : 'Voter anonymement'}
      </button>
      {message && <p>{message}</p>}
    </form>
  );
}
