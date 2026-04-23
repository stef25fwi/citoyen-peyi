import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { type Poll } from '@/lib/demo-data';
import PollCard from '@/components/PollCard';
import MobileNav from '@/components/MobileNav';
import ControleurCodesPanel from '@/components/ControleurCodesPanel';
import CommuneAutocomplete, { CommuneSuggestion } from '@/components/CommuneAutocomplete';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { type CommuneConfig } from '@/lib/registration-data';
import { loadAdminProfileCommune, saveAdminProfileCommune } from '@/lib/data/admin-profile-store';
import { loadPollsData } from '@/lib/data/poll-store';
import { Plus, ArrowLeft, LayoutDashboard, BarChart3, Vote, FileEdit, TrendingUp, Building2, MapPin } from 'lucide-react';
import { toast } from 'sonner';

const statIcons = [Vote, BarChart3, LayoutDashboard, FileEdit];
const statColors = [
  'bg-primary/10 text-primary',
  'bg-success/10 text-success',
  'bg-accent/10 text-accent',
  'bg-warning/10 text-warning',
];

const AdminDashboard = () => {
  const navigate = useNavigate();
  const [commune, setCommune] = useState<CommuneConfig | null>(null);
  const [polls, setPolls] = useState<Poll[]>([]);
  const [isCommuneDialogOpen, setIsCommuneDialogOpen] = useState(false);
  const [selectedCommune, setSelectedCommune] = useState<{ commune: CommuneSuggestion; codePostal: string } | null>(null);

  useEffect(() => {
    let isMounted = true;

    const syncAdminCommune = async () => {
      const storedCommune = await loadAdminProfileCommune();
      if (!isMounted) {
        return;
      }

      setCommune(storedCommune);
      setIsCommuneDialogOpen(!storedCommune);
    };

    void syncAdminCommune();

    return () => {
      isMounted = false;
    };
  }, []);

  useEffect(() => {
    let isMounted = true;

    const syncPolls = async () => {
      const storedPolls = await loadPollsData();
      if (!isMounted) {
        return;
      }

      setPolls(storedPolls);
    };

    void syncPolls();

    return () => {
      isMounted = false;
    };
  }, []);

  const active = polls.filter(p => p.status === 'active');
  const closed = polls.filter(p => p.status === 'closed');
  const drafts = polls.filter(p => p.status === 'draft');

  const stats = [
    { label: 'Total sondages', value: polls.length },
    { label: 'En cours', value: active.length },
    { label: 'Terminés', value: closed.length },
    { label: 'Brouillons', value: drafts.length },
  ];

  const handleSaveCommune = async () => {
    if (!selectedCommune) {
      toast.error('Sélectionnez une commune dans la liste.');
      return;
    }

    const nextCommune: CommuneConfig = {
      name: `${selectedCommune.commune.nom} (${selectedCommune.codePostal})`,
      code: selectedCommune.commune.code,
      codePostal: selectedCommune.codePostal,
      population: selectedCommune.commune.population,
      maxCodes: selectedCommune.commune.population,
    };

    await saveAdminProfileCommune(nextCommune);
    setCommune(nextCommune);
    setIsCommuneDialogOpen(false);
    toast.success(`Compte administrateur rattaché à ${nextCommune.name}.`);
  };

  return (
    <div className="min-h-screen bg-background pb-20 md:pb-0">
      <Dialog open={isCommuneDialogOpen} onOpenChange={open => commune && setIsCommuneDialogOpen(open)}>
        <DialogContent className="sm:max-w-md" onPointerDownOutside={event => !commune && event.preventDefault()} onEscapeKeyDown={event => !commune && event.preventDefault()}>
          <DialogHeader>
            <DialogTitle>Rattacher ce compte administrateur à une collectivité</DialogTitle>
            <DialogDescription>
              Lors de la première connexion, choisissez la commune du compte. Les contrôleurs générés depuis ce compte y seront rattachés automatiquement.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4">
            <div>
              <label className="mb-1.5 block text-sm font-medium text-foreground">
                Commune (nom ou code postal)
              </label>
              <CommuneAutocomplete onSelect={(selected, codePostal) => setSelectedCommune({ commune: selected, codePostal })} />
            </div>

            {selectedCommune && (
              <div className="rounded-lg border border-primary/30 bg-primary/5 p-3 text-sm">
                <p className="font-semibold text-foreground">{selectedCommune.commune.nom}</p>
                <p className="text-xs text-muted-foreground">Code postal : {selectedCommune.codePostal}</p>
                <p className="text-xs text-muted-foreground">
                  Population : {selectedCommune.commune.population.toLocaleString('fr-FR')} habitants
                </p>
              </div>
            )}

            <Button onClick={handleSaveCommune} disabled={!selectedCommune} className="gradient-primary w-full border-0 text-primary-foreground">
              Enregistrer la commune
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Header */}
      <header className="border-b border-border bg-card">
        <div className="container mx-auto flex items-start justify-between gap-3 px-4 py-4 sm:items-center">
          <div className="flex min-w-0 items-center gap-3">
            <Button variant="ghost" size="icon" onClick={() => navigate('/')} className="h-12 w-12">
              <ArrowLeft className="h-5 w-5" />
            </Button>
            <div className="flex min-w-0 items-center gap-2">
              <LayoutDashboard className="h-5 w-5 text-primary" />
              <h1 className="truncate text-base font-bold text-foreground sm:text-lg">Tableau de bord</h1>
            </div>
          </div>
          <div className="hidden items-center gap-2 md:flex">
            <Button variant="outline" onClick={() => navigate('/admin/analytics')} className="gap-2">
              <TrendingUp className="h-4 w-4" />
              Analytiques
            </Button>
            <Button onClick={() => navigate('/admin/create')} className="gradient-primary border-0 text-primary-foreground">
              <Plus className="mr-2 h-4 w-4" />
              Nouveau sondage
            </Button>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-3 py-4 sm:px-4 sm:py-6 md:py-8">
        <section className="mb-6">
          <Card className="border border-border bg-card shadow-card">
            <CardContent className="flex flex-col gap-4 p-4 sm:flex-row sm:items-center sm:justify-between">
              <div className="flex items-start gap-3">
                <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-primary/10 text-primary">
                  <Building2 className="h-5 w-5" />
                </div>
                <div>
                  <p className="text-sm font-semibold text-foreground">Profil administrateur</p>
                  <p className="text-sm text-muted-foreground">
                    {commune ? 'Collectivité de rattachement enregistrée pour ce compte.' : 'Aucune commune rattachée à ce compte.'}
                  </p>
                  {commune && (
                    <div className="mt-2 flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
                      <span className="inline-flex items-center gap-1 rounded-full border border-primary/30 bg-primary/10 px-2 py-0.5 text-primary">
                        <MapPin className="h-3 w-3" />
                        {commune.name}
                      </span>
                      <span>{commune.population.toLocaleString('fr-FR')} habitants</span>
                    </div>
                  )}
                </div>
              </div>
              <Button variant="outline" onClick={() => setIsCommuneDialogOpen(true)}>
                {commune ? 'Changer de commune' : 'Choisir une commune'}
              </Button>
            </CardContent>
          </Card>
        </section>

        {/* Stats with icons */}
        <div className="mb-8 grid grid-cols-2 gap-2 sm:grid-cols-4 sm:gap-3">
          {stats.map((s, i) => {
            const Icon = statIcons[i];
            return (
              <div key={s.label} className="rounded-xl border border-border bg-card p-2 shadow-card sm:p-3 md:p-4">
                <div className="flex items-center gap-2 sm:gap-3">
                  <div className={`flex h-8 w-8 items-center justify-center rounded-lg sm:h-10 sm:w-10 ${statColors[i]}`}>
                    <Icon className="h-4 w-4 sm:h-5 sm:w-5" />
                  </div>
                  <div className="min-w-0">
                    <p className="text-base font-bold text-foreground sm:text-xl md:text-2xl">{s.value}</p>
                    <p className="text-xs text-muted-foreground">{s.label}</p>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {/* Active */}
        {active.length > 0 && (
          <section className="mb-8">
            <h2 className="mb-4 text-base font-semibold text-foreground">Sondages en cours</h2>
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {active.map(p => <PollCard key={p.id} poll={p} />)}
            </div>
          </section>
        )}

        {/* Closed */}
        {closed.length > 0 && (
          <section className="mb-8">
            <h2 className="mb-4 text-base font-semibold text-foreground">Terminés</h2>
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {closed.map(p => <PollCard key={p.id} poll={p} />)}
            </div>
          </section>
        )}

        {/* Drafts */}
        {drafts.length > 0 && (
          <section className="mb-8">
            <h2 className="mb-4 text-base font-semibold text-foreground">Brouillons</h2>
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {drafts.map(p => <PollCard key={p.id} poll={p} />)}
            </div>
          </section>
        )}

        {/* Contrôleur access codes */}
        <section>
          <h2 className="mb-4 text-base font-semibold text-foreground">Accès contrôleurs</h2>
          <ControleurCodesPanel commune={commune} onRequestCommuneSetup={() => setIsCommuneDialogOpen(true)} />
        </section>
      </main>

      {/* FAB for mobile */}
      <button
        onClick={() => navigate('/admin/create')}
        className="fixed bottom-20 right-4 z-50 flex h-16 w-16 items-center justify-center rounded-full gradient-primary text-primary-foreground shadow-elevated md:hidden"
      >
        <Plus className="h-6 w-6" />
      </button>

      <MobileNav />
    </div>
  );
};

export default AdminDashboard;
