import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { demoPolls } from '@/lib/demo-data';
import PollCard from '@/components/PollCard';
import MobileNav from '@/components/MobileNav';
import ControleurCodesPanel from '@/components/ControleurCodesPanel';
import { Plus, ArrowLeft, LayoutDashboard, BarChart3, Vote, FileEdit, TrendingUp } from 'lucide-react';

const statIcons = [Vote, BarChart3, LayoutDashboard, FileEdit];
const statColors = [
  'bg-primary/10 text-primary',
  'bg-success/10 text-success',
  'bg-accent/10 text-accent',
  'bg-warning/10 text-warning',
];

const AdminDashboard = () => {
  const navigate = useNavigate();

  const active = demoPolls.filter(p => p.status === 'active');
  const closed = demoPolls.filter(p => p.status === 'closed');
  const drafts = demoPolls.filter(p => p.status === 'draft');

  const stats = [
    { label: 'Total sondages', value: demoPolls.length },
    { label: 'En cours', value: active.length },
    { label: 'Terminés', value: closed.length },
    { label: 'Brouillons', value: drafts.length },
  ];

  return (
    <div className="min-h-screen bg-background pb-20 md:pb-0">
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
          <ControleurCodesPanel />
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
