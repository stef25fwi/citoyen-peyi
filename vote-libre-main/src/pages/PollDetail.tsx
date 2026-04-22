import { useParams, useNavigate } from 'react-router-dom';
import { demoPolls, demoTokens } from '@/lib/demo-data';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import ResultsChart from '@/components/ResultsChart';
import { ArrowLeft, QrCode, Users, Download } from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';

const PollDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const poll = demoPolls.find(p => p.id === id);

  if (!poll) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <p className="text-muted-foreground">Sondage introuvable.</p>
      </div>
    );
  }

  const tokens = demoTokens.filter(t => t.pollId === poll.id);
  const totalVotes = poll.options.reduce((s, o) => s + o.votes, 0);

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b border-border bg-card">
        <div className="container mx-auto flex items-center gap-3 px-4 py-4">
          <Button variant="ghost" size="icon" onClick={() => navigate('/admin')}>
            <ArrowLeft className="h-4 w-4" />
          </Button>
          <div>
            <h1 className="text-lg font-bold text-foreground">{poll.projectTitle}</h1>
            <p className="text-sm text-muted-foreground">{poll.question}</p>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8">
        <div className="grid gap-6 lg:grid-cols-3">
          {/* Results */}
          <div className="lg:col-span-2">
            <Card className="border border-border bg-card p-6 shadow-card">
              <h2 className="mb-1 text-base font-semibold text-card-foreground">Résultats agrégés</h2>
              <p className="mb-6 text-sm text-muted-foreground">{totalVotes} vote{totalVotes !== 1 ? 's' : ''} enregistré{totalVotes !== 1 ? 's' : ''}</p>
              <ResultsChart options={poll.options} />
            </Card>
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            {/* Info */}
            <Card className="border border-border bg-card p-5 shadow-card">
              <h3 className="mb-3 text-sm font-semibold text-card-foreground">Informations</h3>
              <dl className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <dt className="text-muted-foreground">Statut</dt>
                  <dd><Badge variant="outline">{poll.status === 'active' ? 'En cours' : poll.status === 'closed' ? 'Terminé' : 'Brouillon'}</Badge></dd>
                </div>
                <div className="flex justify-between">
                  <dt className="text-muted-foreground">Ouverture</dt>
                  <dd className="font-medium text-card-foreground">{poll.openDate}</dd>
                </div>
                <div className="flex justify-between">
                  <dt className="text-muted-foreground">Fermeture</dt>
                  <dd className="font-medium text-card-foreground">{poll.closeDate}</dd>
                </div>
                <div className="flex justify-between">
                  <dt className="text-muted-foreground">Participation</dt>
                  <dd className="font-medium text-card-foreground">{poll.totalVoted}/{poll.totalVoters}</dd>
                </div>
              </dl>
            </Card>

            {/* QR Codes */}
            <Card className="border border-border bg-card p-5 shadow-card">
              <div className="mb-3 flex items-center justify-between">
                <h3 className="text-sm font-semibold text-card-foreground">QR Codes ({tokens.length})</h3>
                <Button variant="ghost" size="sm" className="text-xs">
                  <Download className="mr-1 h-3 w-3" />
                  Exporter
                </Button>
              </div>
              <div className="grid grid-cols-2 gap-3">
                {tokens.slice(0, 4).map(token => (
                  <div key={token.id} className="flex flex-col items-center rounded-lg border border-border bg-muted/50 p-3">
                    <QRCodeSVG value={`${window.location.origin}/vote/${token.token}`} size={64} />
                    <p className="mt-2 text-[10px] font-mono text-muted-foreground">{token.token}</p>
                    <Badge variant="outline" className="mt-1 text-[10px]">
                      {token.hasVoted ? 'Voté' : token.activated ? 'Activé' : 'En attente'}
                    </Badge>
                  </div>
                ))}
              </div>
              {tokens.length > 4 && (
                <p className="mt-3 text-center text-xs text-muted-foreground">+{tokens.length - 4} autres codes</p>
              )}
            </Card>

            {/* Audit */}
            <Card className="border border-border bg-card p-5 shadow-card">
              <h3 className="mb-2 text-sm font-semibold text-card-foreground">Journal d'audit</h3>
              <p className="text-xs text-muted-foreground">
                L'audit enregistre les accès et participations sans lien avec le contenu des votes. 
                Conformité RGPD assurée.
              </p>
              <div className="mt-3 space-y-2">
                {[
                  { time: '14:32', event: 'Nouveau vote enregistré (anonyme)' },
                  { time: '14:15', event: 'Code VOTE-A1B2C3 activé' },
                  { time: '13:58', event: 'Nouveau vote enregistré (anonyme)' },
                ].map((e, i) => (
                  <div key={i} className="flex items-center gap-2 text-xs">
                    <span className="font-mono text-muted-foreground">{e.time}</span>
                    <span className="text-card-foreground">{e.event}</span>
                  </div>
                ))}
              </div>
            </Card>
          </div>
        </div>
      </main>
    </div>
  );
};

export default PollDetail;
