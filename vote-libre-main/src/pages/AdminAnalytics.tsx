import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { type Poll } from '@/lib/demo-data';
import MobileNav from '@/components/MobileNav';
import { useIsMobile } from '@/hooks/use-mobile';
import { loadControleurCodesData } from '@/lib/data/controleur-store';
import { loadPollsData } from '@/lib/data/poll-store';
import { loadPollVoteAccessRecords, type VoteAccessRecord } from '@/lib/vote-access';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  AreaChart,
  Area,
} from 'recharts';
import {
  ArrowLeft,
  TrendingUp,
  Users,
  CheckCircle2,
  UserCheck,
  BarChart3,
  PieChart as PieIcon,
  Activity,
} from 'lucide-react';

const CHART_COLORS = [
  'hsl(215, 90%, 50%)',
  'hsl(152, 60%, 42%)',
  'hsl(38, 92%, 50%)',
  'hsl(280, 65%, 55%)',
  'hsl(0, 72%, 51%)',
];

interface TooltipProps {
  active?: boolean;
  payload?: Array<{ name: string; value: number; color: string; payload: Record<string, unknown> }>;
  label?: string;
}

const ChartTooltip = ({ active, payload, label }: TooltipProps) => {
  if (!active || !payload?.length) return null;
  return (
    <div className="rounded-lg border border-border bg-card p-3 shadow-elevated">
      {label && <p className="mb-1.5 text-xs font-semibold text-card-foreground">{label}</p>}
      {payload.map((p, i) => (
        <p key={i} className="text-xs" style={{ color: p.color }}>
          {p.name}: <span className="font-semibold">{p.value}</span>
        </p>
      ))}
    </div>
  );
};

const AdminAnalytics = () => {
  const navigate = useNavigate();
  const isMobile = useIsMobile();
  const [polls, setPolls] = useState<Poll[]>([]);
  const [controleurCodesCount, setControleurCodesCount] = useState(0);
  const [controleurUsedCount, setControleurUsedCount] = useState(0);
  const [tokenStats, setTokenStats] = useState<Array<{ id: string; name: string; total: number; activated: number; voted: number }>>([]);
  const [activityData, setActivityData] = useState<Array<{ jour: string; votes: number }>>([]);

  useEffect(() => {
    let isMounted = true;

    const syncAnalytics = async () => {
      const [storedPolls, controleurCodes] = await Promise.all([
        loadPollsData(),
        loadControleurCodesData(),
      ]);

      const pollAccessRecords = await Promise.all(
        storedPolls.map(async (poll) => ({
          poll,
          records: await loadPollVoteAccessRecords(poll.id),
        })),
      );

      if (!isMounted) {
        return;
      }

      setPolls(storedPolls);
      setControleurCodesCount(controleurCodes.length);
      setControleurUsedCount(controleurCodes.filter((item) => item.usedAt).length);
      setTokenStats(
        pollAccessRecords
          .map(({ poll, records }) => {
            if (records.length === 0) {
              return null;
            }

            return {
              id: poll.id,
              name: poll.projectTitle.length > 22 ? `${poll.projectTitle.slice(0, 22)}…` : poll.projectTitle,
              total: records.length,
              activated: records.filter((record) => record.activated).length,
              voted: records.filter((record) => record.hasVoted).length,
            };
          })
          .filter(Boolean) as Array<{ id: string; name: string; total: number; activated: number; voted: number }>,
      );

      const dailyVotes = new Map<string, number>();
      const formatter = new Intl.DateTimeFormat('fr-FR', { weekday: 'short', day: '2-digit' });
      const now = new Date();
      const lastSevenDays = Array.from({ length: 7 }, (_, index) => {
        const date = new Date(now);
        date.setDate(now.getDate() - (6 - index));
        const key = date.toISOString().split('T')[0];
        dailyVotes.set(key, 0);
        return { key, label: formatter.format(date).replace('.', '') };
      });

      pollAccessRecords.forEach(({ records }) => {
        records.forEach((record: VoteAccessRecord) => {
          if (!record.votedAt) {
            return;
          }

          const key = record.votedAt.split('T')[0];
          if (dailyVotes.has(key)) {
            dailyVotes.set(key, (dailyVotes.get(key) || 0) + 1);
          }
        });
      });

      setActivityData(lastSevenDays.map(({ key, label }) => ({ jour: label, votes: dailyVotes.get(key) || 0 })));
    };

    void syncAnalytics();

    return () => {
      isMounted = false;
    };
  }, []);

  const active = useMemo(() => polls.filter(p => p.status === 'active'), [polls]);
  const closed = useMemo(() => polls.filter(p => p.status === 'closed'), [polls]);
  const drafts = useMemo(() => polls.filter(p => p.status === 'draft'), [polls]);

  const totalVotes = useMemo(() => polls.reduce((s, p) => s + p.totalVoted, 0), [polls]);
  const totalVoters = useMemo(() => polls.reduce((s, p) => s + p.totalVoters, 0), [polls]);

  const nonDraftPolls = useMemo(() => polls.filter(p => p.status !== 'draft' && p.totalVoters > 0), [polls]);
  const avgParticipation =
    nonDraftPolls.length > 0
      ? nonDraftPolls.reduce((s, p) => s + p.totalVoted / p.totalVoters, 0) / nonDraftPolls.length
      : 0;

  // Participation bar chart data
  const participationData = nonDraftPolls.map(p => ({
    name: p.projectTitle.length > 24 ? p.projectTitle.slice(0, 24) + '…' : p.projectTitle,
    taux: Math.round((p.totalVoted / p.totalVoters) * 100),
    votes: p.totalVoted,
    inscrits: p.totalVoters,
  }));

  // Status pie chart data
  const statusData = [
    { name: 'En cours', value: active.length, color: CHART_COLORS[0] },
    { name: 'Terminés', value: closed.length, color: CHART_COLORS[1] },
    { name: 'Brouillons', value: drafts.length, color: CHART_COLORS[2] },
  ].filter(d => d.value > 0);

  const participationChartHeight = isMobile
    ? Math.max(participationData.length * 56, 240)
    : participationData.length * 64 + 16;

  const activePollChartHeight = (optionCount: number) => (
    isMobile ? Math.max(optionCount * 48, 220) : optionCount * 52 + 8
  );

  const kpis = [
    {
      label: 'Votes émis',
      value: totalVotes,
      sub: `sur ${totalVoters} inscrits`,
      colorClass: 'bg-primary/10 text-primary',
      Icon: CheckCircle2,
    },
    {
      label: 'Participation moy.',
      value: `${Math.round(avgParticipation * 100)}%`,
      sub: 'sondages actifs & clos',
      colorClass: 'bg-success/10 text-success',
      Icon: TrendingUp,
    },
    {
      label: 'Électeurs inscrits',
      value: totalVoters,
      sub: 'codes QR distribués',
      colorClass: 'bg-accent/10 text-accent',
      Icon: Users,
    },
    {
      label: 'Contrôleurs actifs',
      value: `${controleurUsedCount}/${controleurCodesCount}`,
      sub: 'codes utilisés',
      colorClass: 'bg-warning/10 text-warning',
      Icon: UserCheck,
    },
  ];

  return (
    <div className="min-h-screen bg-background pb-20 md:pb-0">
      {/* Header */}
      <header className="border-b border-border bg-card">
        <div className="container mx-auto flex flex-col gap-3 px-3 py-4 sm:flex-row sm:items-center sm:justify-between sm:px-4">
          <div className="flex items-center gap-3">
            <Button variant="ghost" size="icon" onClick={() => navigate('/admin')} className="h-10 w-10 sm:h-11 sm:w-11">
              <ArrowLeft className="h-4 w-4" />
            </Button>
            <div className="flex items-center gap-2">
              <BarChart3 className="h-5 w-5 text-primary" />
              <h1 className="text-lg font-bold text-foreground">Analytiques</h1>
            </div>
          </div>
          <Badge variant="outline" className="w-full justify-center text-xs text-muted-foreground sm:w-auto">
            Données agrégées · RGPD
          </Badge>
        </div>
      </header>

      <main className="container mx-auto space-y-6 px-3 py-4 sm:space-y-8 sm:px-4 sm:py-6">
        {/* KPI Cards */}
        <section>
          <div className="grid grid-cols-1 gap-3 min-[480px]:grid-cols-2 xl:grid-cols-4">
            {kpis.map(({ label, value, sub, colorClass, Icon }) => (
              <Card key={label} className="border border-border bg-card p-4 shadow-card sm:p-5">
                <div className="flex items-center gap-3">
                  <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-lg ${colorClass}`}>
                    <Icon className="h-5 w-5" />
                  </div>
                  <div className="min-w-0">
                    <p className="text-2xl font-bold text-foreground">{value}</p>
                    <p className="truncate text-xs text-muted-foreground">{label}</p>
                  </div>
                </div>
                <p className="mt-2 text-[11px] text-muted-foreground">{sub}</p>
              </Card>
            ))}
          </div>
        </section>

        {/* Participation + Status side by side */}
        <section className="grid gap-6 lg:grid-cols-3">
          {/* Participation bar chart */}
          <Card className="border border-border bg-card p-4 shadow-card sm:p-6 lg:col-span-2">
            <div className="mb-4 flex items-center gap-2">
              <BarChart3 className="h-4 w-4 text-primary" />
              <h2 className="text-sm font-semibold text-card-foreground">Taux de participation par sondage</h2>
            </div>
            {participationData.length > 0 ? (
              <ResponsiveContainer width="100%" height={participationChartHeight}>
                <BarChart
                  data={participationData}
                  layout="vertical"
                  margin={{ left: 0, right: isMobile ? 12 : 40, top: 0, bottom: 0 }}
                >
                  <CartesianGrid strokeDasharray="3 3" stroke="hsl(220 13% 91%)" horizontal={false} />
                  <XAxis
                    type="number"
                    domain={[0, 100]}
                    tickFormatter={v => `${v}%`}
                    tick={{ fontSize: isMobile ? 10 : 11, fill: 'hsl(220 10% 46%)' }}
                    axisLine={false}
                    tickLine={false}
                  />
                  <YAxis
                    type="category"
                    dataKey="name"
                    width={isMobile ? 92 : 140}
                    tick={{ fontSize: isMobile ? 10 : 11, fill: 'hsl(222 47% 11%)' }}
                    axisLine={false}
                    tickLine={false}
                  />
                  <Tooltip
                    content={<ChartTooltip />}
                    formatter={(v: number) => [`${v}%`, 'Participation']}
                  />
                  <Bar
                    dataKey="taux"
                    name="Participation"
                    fill={CHART_COLORS[0]}
                    radius={[0, 6, 6, 0]}
                    label={isMobile ? false : { position: 'right', formatter: (v: number) => `${v}%`, fontSize: 11, fill: 'hsl(220 10% 46%)' }}
                  />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <p className="py-8 text-center text-sm text-muted-foreground">Aucun sondage avec données de participation.</p>
            )}
          </Card>

          {/* Status pie chart */}
          <Card className="border border-border bg-card p-4 shadow-card sm:p-6">
            <div className="mb-4 flex items-center gap-2">
              <PieIcon className="h-4 w-4 text-primary" />
              <h2 className="text-sm font-semibold text-card-foreground">Statuts des sondages</h2>
            </div>
            <ResponsiveContainer width="100%" height={isMobile ? 190 : 160}>
              <PieChart>
                <Pie
                  data={statusData}
                  cx="50%"
                  cy="50%"
                  innerRadius={48}
                  outerRadius={72}
                  paddingAngle={3}
                  dataKey="value"
                  strokeWidth={0}
                >
                  {statusData.map(entry => (
                    <Cell key={entry.name} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip content={<ChartTooltip />} />
              </PieChart>
            </ResponsiveContainer>
            <div className="mt-3 space-y-2">
              {statusData.map(s => (
                <div key={s.name} className="flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2">
                    <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ backgroundColor: s.color }} />
                    <span className="text-muted-foreground">{s.name}</span>
                  </div>
                  <span className="font-semibold text-card-foreground">{s.value}</span>
                </div>
              ))}
            </div>
          </Card>
        </section>

        {/* Activity Area Chart */}
        <section>
          <Card className="border border-border bg-card p-4 shadow-card sm:p-6">
            <div className="mb-4 flex items-center gap-2">
              <Activity className="h-4 w-4 text-primary" />
              <h2 className="text-sm font-semibold text-card-foreground">Activité de vote — 7 derniers jours</h2>
            </div>
            <ResponsiveContainer width="100%" height={isMobile ? 220 : 180}>
              <AreaChart data={activityData} margin={{ left: 0, right: isMobile ? 0 : 8, top: 4, bottom: 0 }}>
                <defs>
                  <linearGradient id="areaGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor={CHART_COLORS[0]} stopOpacity={0.18} />
                    <stop offset="95%" stopColor={CHART_COLORS[0]} stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="hsl(220 13% 91%)" vertical={false} />
                <XAxis
                  dataKey="jour"
                  tick={{ fontSize: 11, fill: 'hsl(220 10% 46%)' }}
                  axisLine={false}
                  tickLine={false}
                />
                <YAxis
                  tick={{ fontSize: isMobile ? 10 : 11, fill: 'hsl(220 10% 46%)' }}
                  axisLine={false}
                  tickLine={false}
                  width={isMobile ? 22 : 28}
                />
                <Tooltip content={<ChartTooltip />} />
                <Area
                  type="monotone"
                  dataKey="votes"
                  name="Votes"
                  stroke={CHART_COLORS[0]}
                  strokeWidth={2}
                  fill="url(#areaGrad)"
                  dot={{ fill: CHART_COLORS[0], r: 3, strokeWidth: 0 }}
                  activeDot={{ r: 5, strokeWidth: 0 }}
                />
              </AreaChart>
            </ResponsiveContainer>
          </Card>
        </section>

        {/* Active poll results */}
        {active.length > 0 && (
          <section>
            <h2 className="mb-4 text-base font-semibold text-foreground">Résultats en cours</h2>
            <div className="grid gap-6 lg:grid-cols-2">
              {active.map(poll => {
                const total = poll.options.reduce((s, o) => s + o.votes, 0);
                const chartData = poll.options.map((o, i) => ({
                  name: o.label.length > 20 ? o.label.slice(0, 20) + '…' : o.label,
                  votes: o.votes,
                  pct: total > 0 ? Math.round((o.votes / total) * 100) : 0,
                  fill: CHART_COLORS[i % CHART_COLORS.length],
                }));
                return (
                  <Card key={poll.id} className="border border-border bg-card p-4 shadow-card sm:p-6">
                    <p className="mb-0.5 text-sm font-semibold text-card-foreground">{poll.projectTitle}</p>
                    <p className="mb-4 text-xs text-muted-foreground">
                      {total} vote{total !== 1 ? 's' : ''} · {Math.round((poll.totalVoted / poll.totalVoters) * 100)}% de participation
                    </p>
                    <ResponsiveContainer width="100%" height={activePollChartHeight(chartData.length)}>
                      <BarChart
                        data={chartData}
                        layout="vertical"
                        margin={{ left: 0, right: isMobile ? 12 : 40, top: 0, bottom: 0 }}
                      >
                        <CartesianGrid strokeDasharray="3 3" stroke="hsl(220 13% 91%)" horizontal={false} />
                        <XAxis
                          type="number"
                          tick={{ fontSize: isMobile ? 9 : 10, fill: 'hsl(220 10% 46%)' }}
                          axisLine={false}
                          tickLine={false}
                        />
                        <YAxis
                          type="category"
                          dataKey="name"
                          width={isMobile ? 84 : 128}
                          tick={{ fontSize: isMobile ? 9 : 10, fill: 'hsl(222 47% 11%)' }}
                          axisLine={false}
                          tickLine={false}
                        />
                        <Tooltip content={<ChartTooltip />} />
                        <Bar
                          dataKey="votes"
                          name="Votes"
                          radius={[0, 6, 6, 0]}
                          label={isMobile ? false : { position: 'right', formatter: (v: number) => `${v}`, fontSize: 10, fill: 'hsl(220 10% 46%)' }}
                        >
                          {chartData.map((entry, i) => (
                            <Cell key={i} fill={entry.fill} />
                          ))}
                        </Bar>
                      </BarChart>
                    </ResponsiveContainer>
                  </Card>
                );
              })}
            </div>
          </section>
        )}

        {/* QR Code token utilization */}
        {tokenStats.length > 0 && (
          <section>
            <h2 className="mb-4 text-base font-semibold text-foreground">Utilisation des QR codes</h2>
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {tokenStats.map(stat => (
                <Card key={stat.id} className="border border-border bg-card p-4 shadow-card sm:p-5">
                  <p className="mb-4 truncate text-sm font-medium text-card-foreground">{stat.name}</p>
                  <div className="space-y-3">
                    {[
                      { label: 'Total générés', value: stat.total, pct: 100, color: CHART_COLORS[3] },
                      { label: 'Activés', value: stat.activated, pct: Math.round((stat.activated / stat.total) * 100), color: CHART_COLORS[0] },
                      { label: 'Ont voté', value: stat.voted, pct: Math.round((stat.voted / stat.total) * 100), color: CHART_COLORS[1] },
                    ].map(row => (
                      <div key={row.label}>
                        <div className="mb-1 flex justify-between text-xs">
                          <span className="text-muted-foreground">{row.label}</span>
                          <span className="font-semibold text-card-foreground">
                            {row.value}{' '}
                            <span className="font-normal text-muted-foreground">({row.pct}%)</span>
                          </span>
                        </div>
                        <div className="h-1.5 overflow-hidden rounded-full bg-muted">
                          <div
                            className="h-full rounded-full"
                            style={{ width: `${row.pct}%`, backgroundColor: row.color }}
                          />
                        </div>
                      </div>
                    ))}
                  </div>
                </Card>
              ))}
            </div>
          </section>
        )}
      </main>

      <MobileNav />
    </div>
  );
};

export default AdminAnalytics;
