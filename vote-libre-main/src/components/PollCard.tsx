import { Calendar, Users, CheckCircle2, Clock, FileEdit } from 'lucide-react';
import { Poll } from '@/lib/demo-data';
import { Badge } from '@/components/ui/badge';
import { Card } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { useNavigate } from 'react-router-dom';
import { getPalette } from '@/hooks/usePollTheme';

const statusConfig = {
  active: { label: 'En cours', className: 'bg-success/10 text-success border-success/20', icon: CheckCircle2 },
  closed: { label: 'Terminé', className: 'bg-muted text-muted-foreground border-border', icon: Clock },
  draft: { label: 'Brouillon', className: 'bg-warning/10 text-warning border-warning/20', icon: FileEdit },
};

const PollCard = ({ poll }: { poll: Poll }) => {
  const navigate = useNavigate();
  const config = statusConfig[poll.status];
  const StatusIcon = config.icon;
  const participation = poll.totalVoters > 0 ? Math.round((poll.totalVoted / poll.totalVoters) * 100) : 0;
  const palette = getPalette(poll.id);

  return (
    <Card
      className="group relative cursor-pointer overflow-hidden border border-border bg-card p-5 transition-all hover:shadow-elevated hover:-translate-y-0.5"
      onClick={() => navigate(`/admin/poll/${poll.id}`)}
    >
      {/* Dynamic color band */}
      <div
        className="absolute left-0 top-0 h-full w-1 transition-all group-hover:w-1.5"
        style={{ background: `linear-gradient(to bottom, ${palette.primary}, ${palette.accent})` }}
      />

      <div className="pl-3">
        <div className="flex items-start justify-between">
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-2">
              <Badge variant="outline" className={config.className}>
                <StatusIcon className="mr-1 h-3 w-3" />
                {config.label}
              </Badge>
            </div>
            <h3 className="mt-3 truncate text-base font-semibold text-card-foreground">{poll.projectTitle}</h3>
            <p className="mt-1 line-clamp-2 text-sm text-muted-foreground">{poll.question}</p>
          </div>
        </div>

        <div className="mt-4 space-y-3">
          <div className="flex items-center justify-between text-xs text-muted-foreground">
            <span className="flex items-center gap-1"><Users className="h-3.5 w-3.5" /> {poll.totalVoted}/{poll.totalVoters} votes</span>
            <span>{participation}%</span>
          </div>
          <Progress value={participation} className="h-1.5" />
          <div className="flex items-center gap-1 text-xs text-muted-foreground">
            <Calendar className="h-3.5 w-3.5" />
            {poll.openDate} → {poll.closeDate}
          </div>
        </div>
      </div>
    </Card>
  );
};

export default PollCard;
