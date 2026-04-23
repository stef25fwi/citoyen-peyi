import { collection, doc, getDoc, getDocs, setDoc, serverTimestamp } from 'firebase/firestore';
import { FIRESTORE_COLLECTIONS } from '@/lib/data/firestore-collections';
import { getFirestoreDb } from '@/lib/firebase';
import { demoPolls, type Poll, type PollOption } from '@/lib/demo-data';

const POLLS_STORAGE_KEY = 'polls_v1';

const normalizePollOption = (item: Partial<PollOption>, index: number): PollOption => ({
  id: item.id || `opt-${index + 1}`,
  label: item.label?.trim() || `Option ${index + 1}`,
  votes: typeof item.votes === 'number' ? item.votes : 0,
});

const normalizePoll = (item: Partial<Poll>): Poll => ({
  id: item.id || `poll-${Math.random().toString(36).slice(2, 8)}`,
  projectTitle: item.projectTitle?.trim() || 'Sondage sans titre',
  question: item.question?.trim() || '',
  options: Array.isArray(item.options)
    ? item.options.map((option, index) => normalizePollOption(option, index))
    : [],
  openDate: item.openDate || new Date().toISOString().split('T')[0],
  closeDate: item.closeDate || new Date().toISOString().split('T')[0],
  status: item.status || 'draft',
  totalVoters: typeof item.totalVoters === 'number' ? item.totalVoters : 0,
  totalVoted: typeof item.totalVoted === 'number' ? item.totalVoted : 0,
});

const loadLocalPolls = (): Poll[] => {
  try {
    const raw = localStorage.getItem(POLLS_STORAGE_KEY);
    if (!raw) {
      return demoPolls;
    }

    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) {
      return demoPolls;
    }

    const polls = parsed.map((item: Partial<Poll>) => normalizePoll(item));
    return polls.length > 0 ? polls : demoPolls;
  } catch {
    return demoPolls;
  }
};

const saveLocalPolls = (polls: Poll[]) => {
  localStorage.setItem(POLLS_STORAGE_KEY, JSON.stringify(polls));
};

const derivePollStatus = (openDate: string, closeDate: string): Poll['status'] => {
  const today = new Date().toISOString().split('T')[0];

  if (closeDate && closeDate < today) {
    return 'closed';
  }

  if (!openDate || openDate > today) {
    return 'draft';
  }

  return 'active';
};

export const loadPollsData = async (): Promise<Poll[]> => {
  const db = getFirestoreDb();
  if (!db) {
    return loadLocalPolls();
  }

  try {
    const snapshot = await getDocs(collection(db, FIRESTORE_COLLECTIONS.polls));
    if (snapshot.empty) {
      return loadLocalPolls();
    }

    const polls = snapshot.docs
      .map((item) => normalizePoll(item.data() as Partial<Poll>))
      .sort((a, b) => new Date(b.openDate).getTime() - new Date(a.openDate).getTime());

    saveLocalPolls(polls);
    return polls;
  } catch {
    return loadLocalPolls();
  }
};

export const loadPollByIdData = async (pollId: string): Promise<Poll | null> => {
  const db = getFirestoreDb();
  if (!db) {
    return loadLocalPolls().find((item) => item.id === pollId) || null;
  }

  try {
    const snapshot = await getDoc(doc(db, FIRESTORE_COLLECTIONS.polls, pollId));
    if (!snapshot.exists()) {
      return loadLocalPolls().find((item) => item.id === pollId) || null;
    }

    return normalizePoll(snapshot.data() as Partial<Poll>);
  } catch {
    return loadLocalPolls().find((item) => item.id === pollId) || null;
  }
};

export const savePollsData = async (polls: Poll[]) => {
  saveLocalPolls(polls);

  const db = getFirestoreDb();
  if (!db) {
    return polls;
  }

  await Promise.all(
    polls.map((poll) => setDoc(doc(db, FIRESTORE_COLLECTIONS.polls, poll.id), {
      ...poll,
      updatedAt: serverTimestamp(),
    }, { merge: true }))
  );
  return polls;
};

export const savePollData = async (poll: Poll) => {
  const existing = loadLocalPolls();
  const nextPolls = existing.some((item) => item.id === poll.id)
    ? existing.map((item) => (item.id === poll.id ? poll : item))
    : [poll, ...existing];

  saveLocalPolls(nextPolls);

  const db = getFirestoreDb();
  if (!db) {
    return poll;
  }

  await setDoc(doc(db, FIRESTORE_COLLECTIONS.polls, poll.id), {
    ...poll,
    updatedAt: serverTimestamp(),
  }, { merge: true });

  return poll;
};

export const createPollData = async (input: {
  projectTitle: string;
  question: string;
  options: string[];
  openDate: string;
  closeDate: string;
  totalVoters: number;
}) => {
  const poll: Poll = {
    id: `poll-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
    projectTitle: input.projectTitle.trim(),
    question: input.question.trim(),
    options: input.options.map((option, index) => ({
      id: `opt-${Date.now()}-${index + 1}`,
      label: option.trim(),
      votes: 0,
    })),
    openDate: input.openDate,
    closeDate: input.closeDate,
    status: derivePollStatus(input.openDate, input.closeDate),
    totalVoters: input.totalVoters,
    totalVoted: 0,
  };

  const polls = await loadPollsData();
  const nextPolls = [poll, ...polls];
  saveLocalPolls(nextPolls);

  const db = getFirestoreDb();
  if (db) {
    await savePollData(poll);
  }

  return poll;
};

export const recordVoteForPollData = async (pollId: string, optionId: string) => {
  const poll = await loadPollByIdData(pollId);
  if (!poll) {
    return null;
  }

  const nextPoll: Poll = {
    ...poll,
    options: poll.options.map((option) => (
      option.id === optionId
        ? { ...option, votes: option.votes + 1 }
        : option
    )),
    totalVoted: poll.totalVoted + 1,
  };

  await savePollData(nextPoll);
  return nextPoll;
};