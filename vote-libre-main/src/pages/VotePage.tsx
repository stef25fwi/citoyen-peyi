import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { type Poll } from '@/lib/demo-data';
import AnonymityBadge from '@/components/AnonymityBadge';
import StepIndicator from '@/components/StepIndicator';
import SuccessAnimation from '@/components/SuccessAnimation';
import { ArrowLeft, Send, CheckCircle2 } from 'lucide-react';
import { motion } from 'framer-motion';
import { toast } from 'sonner';
import { findVoteAccessRecord, markVoteAccessVoted } from '@/lib/vote-access';
import { loadPollByIdData, recordVoteForPollData } from '@/lib/data/poll-store';

const STEPS = ['Accès', 'Vote', 'Confirmation'];

const VotePage = () => {
  const { token } = useParams();
  const navigate = useNavigate();
  const [selected, setSelected] = useState<string | null>(null);
  const [submitted, setSubmitted] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [accessToken, setAccessToken] = useState<Awaited<ReturnType<typeof findVoteAccessRecord>>>(null);
  const [isLoadingAccess, setIsLoadingAccess] = useState(true);
  const [poll, setPoll] = useState<Poll | null>(null);

  useEffect(() => {
    let isMounted = true;

    const loadAccessToken = async () => {
      if (!token) {
        setAccessToken(null);
        setIsLoadingAccess(false);
        return;
      }

      const record = await findVoteAccessRecord(token);
      if (!isMounted) {
        return;
      }

      setAccessToken(record);
      if (record) {
        const nextPoll = await loadPollByIdData(record.pollId);
        if (!isMounted) {
          return;
        }

        setPoll(nextPoll);
      } else {
        setPoll(null);
      }
      setIsLoadingAccess(false);
    };

    void loadAccessToken();

    return () => {
      isMounted = false;
    };
  }, [token]);

  if (isLoadingAccess) {
    return (
      <div className="flex min-h-screen items-center justify-center px-4 bg-background">
        <Card className="max-w-sm border border-border bg-card p-6 text-center shadow-card">
          <p className="text-foreground font-semibold">Chargement de votre accès</p>
          <p className="mt-2 text-sm text-muted-foreground">Vérification sécurisée du code en cours.</p>
        </Card>
      </div>
    );
  }

  if (!accessToken || !poll) {
    return (
      <div className="flex min-h-screen items-center justify-center px-4 bg-background">
        <Card className="max-w-sm border border-border bg-card p-6 text-center shadow-card">
          <p className="text-foreground font-semibold">Accès au sondage indisponible</p>
          <p className="mt-2 text-sm text-muted-foreground">Ce code n'existe pas, a expiré, ou le sondage associé est introuvable.</p>
          <Button variant="outline" className="mt-4" onClick={() => navigate('/access')}>Retour</Button>
        </Card>
      </div>
    );
  }

  if (accessToken.hasVoted || submitted) {
    return (
      <div className="flex min-h-screen flex-col bg-background">
        <div className="gradient-poll">
          <StepIndicator steps={STEPS} current={3} />
        </div>
        <div className="flex flex-1 items-center justify-center px-4">
          <motion.div initial={{ scale: 0.9, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} className="w-full max-w-sm">
            <Card className="border border-border bg-card p-8 text-center shadow-elevated">
              <SuccessAnimation />
              <h2 className="mt-6 text-xl font-bold text-card-foreground">Merci pour votre vote !</h2>
              <p className="mt-3 text-sm text-muted-foreground">
                Votre vote a été enregistré de manière anonyme. Aucune trace ne relie votre identité à votre choix.
              </p>
              <div className="mt-4">
                <AnonymityBadge compact />
              </div>
              <Button variant="outline" className="mt-6 w-full" onClick={() => navigate('/')}>Retour à l'accueil</Button>
            </Card>
          </motion.div>
        </div>
      </div>
    );
  }

  const handleSubmit = async () => {
    if (!selected || isSubmitting) {
      if (!selected) toast.error('Veuillez sélectionner une option.');
      return;
    }
    setIsSubmitting(true);
    if (token) {
      await markVoteAccessVoted(token);
    }
    await recordVoteForPollData(accessToken.pollId, selected);
    setSubmitted(true);
    toast.success('Vote enregistré avec succès !');
  };

  return (
    <div className="flex min-h-screen flex-col bg-background">
      {/* Gradient header with step indicator */}
      <div className="gradient-poll text-primary-foreground">
        <StepIndicator steps={STEPS} current={1} />
        <div className="px-3 pb-4 pt-1 sm:px-4 sm:pb-6 sm:pt-2 md:pb-6">
          <Button variant="ghost" size="icon" onClick={() => navigate('/')} className="mb-1.5 h-12 w-12 text-primary-foreground/70 hover:text-primary-foreground hover:bg-primary-foreground/10 sm:mb-2">
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <p className="line-clamp-1 text-xs font-medium uppercase tracking-wider text-primary-foreground/60 sm:line-clamp-2">{poll.projectTitle}</p>
          <h1 className="mt-1 break-words text-base font-bold sm:text-lg md:text-xl">{poll.question}</h1>
        </div>
      </div>

      {/* Main content - bottom sheet style on mobile */}
      <main className="-mt-3 flex-1 rounded-t-2xl bg-background px-3 pb-28 pt-4 sm:px-4 sm:pt-6 md:pb-8">
        <div className="mx-auto max-w-lg space-y-5">
          <AnonymityBadge />

          <div className="space-y-2 sm:space-y-3">
            {poll.options.map((opt, i) => (
              <motion.button
                key={opt.id}
                type="button"
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: i * 0.06 }}
                onClick={() => setSelected(opt.id)}
                className={`flex w-full items-center gap-2 rounded-xl border p-3 text-left transition-all duration-200 sm:gap-3 sm:p-4 ${
                  selected === opt.id
                    ? 'border-poll-primary bg-poll-primary\/5 shadow-md ring-1 ring-poll-primary'
                    : 'border-border bg-card hover:border-muted-foreground/30 hover:shadow-card'
                }`}
              >
                <div className={`relative flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-full border-2 transition-all duration-200 ${
                  selected === opt.id
                    ? 'border-transparent bg-poll-primary'
                    : 'border-muted-foreground/30'
                }`}>
                  {selected === opt.id && <CheckCircle2 className="h-4 w-4 text-primary-foreground" />}
                </div>
                <div className={`flex-1 min-w-0 ${
                  selected === opt.id
                    ? 'border-l-2 border-poll-primary pl-3'
                    : 'border-l-2 border-transparent pl-3'
                }`}>
                  <span className={`break-words text-sm font-medium ${selected === opt.id ? 'text-foreground' : 'text-muted-foreground'}`}>
                    {opt.label}
                  </span>
                </div>
              </motion.button>
            ))}
          </div>

          {/* Fixed bottom button on mobile */}
          <div className="fixed bottom-0 left-0 right-0 border-t border-border bg-card/95 p-4 pb-[calc(env(safe-area-inset-bottom)+1rem)] backdrop-blur-lg md:relative md:border-0 md:bg-transparent md:p-0 md:backdrop-blur-none">
            <Button
              onClick={handleSubmit}
              disabled={!selected || isSubmitting}
              className="gradient-poll h-12 w-full border-0 text-primary-foreground disabled:opacity-50"
              size="lg"
            >
              <Send className="mr-2 h-4 w-4" />
              Confirmer mon vote
            </Button>
            <p className="mt-2 text-center text-xs text-muted-foreground">
              En soumettant, votre vote sera définitif et anonymisé.
            </p>
          </div>
        </div>
      </main>
    </div>
  );
};

export default VotePage;
