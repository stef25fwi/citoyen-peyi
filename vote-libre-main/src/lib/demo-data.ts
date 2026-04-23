export interface PollOption {
  id: string;
  label: string;
  votes: number;
}

export interface Poll {
  id: string;
  projectTitle: string;
  question: string;
  options: PollOption[];
  openDate: string;
  closeDate: string;
  status: 'draft' | 'active' | 'closed';
  totalVoters: number;
  totalVoted: number;
}

export const demoPoll: Poll = {
  id: 'poll-1',
  projectTitle: 'Réaménagement de la Place Centrale',
  question: 'Quelle option préférez-vous pour le réaménagement de la Place Centrale ?',
  options: [
    { id: 'opt-1', label: 'Espace vert avec aires de jeux', votes: 47 },
    { id: 'opt-2', label: 'Marché couvert et terrasses', votes: 32 },
    { id: 'opt-3', label: 'Parking souterrain et esplanade piétonne', votes: 28 },
    { id: 'opt-4', label: 'Zone mixte commerces et espaces verts', votes: 53 },
  ],
  openDate: '2026-03-15',
  closeDate: '2026-04-15',
  status: 'active',
  totalVoters: 200,
  totalVoted: 160,
};

export const demoPoll2: Poll = {
  id: 'poll-2',
  projectTitle: 'Nouvelle médiathèque municipale',
  question: 'Quel nom souhaitez-vous donner à la nouvelle médiathèque ?',
  options: [
    { id: 'opt-5', label: 'Médiathèque Simone Veil', votes: 64 },
    { id: 'opt-6', label: 'Médiathèque des Lumières', votes: 41 },
    { id: 'opt-7', label: 'Médiathèque du Lac', votes: 35 },
  ],
  openDate: '2026-02-01',
  closeDate: '2026-03-01',
  status: 'closed',
  totalVoters: 180,
  totalVoted: 140,
};

export const demoPoll3: Poll = {
  id: 'poll-3',
  projectTitle: 'Festival d\'été 2026',
  question: 'Quel thème pour le festival d\'été 2026 ?',
  options: [
    { id: 'opt-8', label: 'Musiques du monde' },
    { id: 'opt-9', label: 'Cinéma en plein air' },
    { id: 'opt-10', label: 'Arts de rue et cirque' },
    { id: 'opt-11', label: 'Gastronomie locale' },
  ].map(o => ({ ...o, votes: 0 })),
  openDate: '2026-04-01',
  closeDate: '2026-05-01',
  status: 'draft',
  totalVoters: 0,
  totalVoted: 0,
};

export const demoPolls: Poll[] = [demoPoll, demoPoll2, demoPoll3];
