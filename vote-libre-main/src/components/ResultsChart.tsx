import { PollOption } from '@/lib/demo-data';
import { motion } from 'framer-motion';

const colors = [
  'hsl(215, 90%, 50%)',
  'hsl(168, 70%, 42%)',
  'hsl(38, 92%, 50%)',
  'hsl(280, 65%, 55%)',
  'hsl(0, 72%, 51%)',
];

const ResultsChart = ({ options }: { options: PollOption[] }) => {
  const totalVotes = options.reduce((sum, o) => sum + o.votes, 0);
  const maxVotes = Math.max(...options.map(o => o.votes));

  return (
    <div className="space-y-4">
      {options.map((option, i) => {
        const pct = totalVotes > 0 ? Math.round((option.votes / totalVotes) * 100) : 0;
        const isMax = option.votes === maxVotes && maxVotes > 0;

        return (
          <div key={option.id} className="space-y-1.5">
            <div className="flex items-center justify-between text-sm">
              <span className={`font-medium ${isMax ? 'text-foreground' : 'text-muted-foreground'}`}>
                {option.label}
              </span>
              <span className="tabular-nums font-semibold text-foreground">{pct}%</span>
            </div>
            <div className="h-3 overflow-hidden rounded-full bg-muted">
              <motion.div
                className="h-full rounded-full"
                style={{ backgroundColor: colors[i % colors.length] }}
                initial={{ width: 0 }}
                animate={{ width: `${pct}%` }}
                transition={{ duration: 0.8, delay: i * 0.1, ease: 'easeOut' }}
              />
            </div>
            <p className="text-xs text-muted-foreground">{option.votes} vote{option.votes !== 1 ? 's' : ''}</p>
          </div>
        );
      })}
    </div>
  );
};

export default ResultsChart;
