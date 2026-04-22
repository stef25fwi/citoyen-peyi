const votes = [];

export function saveVote(option) {
  votes.push({ option, createdAt: Date.now() });
}

export function getResults() {
  const counts = votes.reduce((acc, vote) => {
    acc[vote.option] = (acc[vote.option] || 0) + 1;
    return acc;
  }, {});

  return Object.entries(counts).map(([option, count]) => ({ option, count }));
}
