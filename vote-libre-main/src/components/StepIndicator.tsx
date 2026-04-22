import { Check } from 'lucide-react';

interface StepIndicatorProps {
  steps: string[];
  current: number;
}

const StepIndicator = ({ steps, current }: StepIndicatorProps) => (
  <div className="w-full overflow-x-auto">
    <div className="mx-auto flex min-w-max items-center justify-center gap-2 px-4 py-3">
      {steps.map((step, i) => (
        <div key={step} className="flex items-center gap-2">
        <div className={`flex h-7 w-7 items-center justify-center rounded-full text-xs font-bold transition-all duration-300 ${
          i < current
            ? 'bg-[hsl(var(--poll-primary,var(--primary)))] text-primary-foreground'
            : i === current
            ? 'border-2 border-[hsl(var(--poll-primary,var(--primary)))] text-[hsl(var(--poll-primary,var(--primary)))]'
            : 'border-2 border-muted-foreground/30 text-muted-foreground/50'
        }`}>
          {i < current ? <Check className="h-3.5 w-3.5" /> : i + 1}
        </div>
        <span className={`hidden text-xs font-medium sm:inline ${
          i <= current ? 'text-foreground' : 'text-muted-foreground/50'
        }`}>{step}</span>
        {i < steps.length - 1 && (
          <div className={`h-0.5 w-6 rounded transition-colors duration-300 ${
            i < current ? 'bg-[hsl(var(--poll-primary,var(--primary)))]' : 'bg-muted-foreground/20'
          }`} />
        )}
        </div>
      ))}
    </div>
  </div>
);

export default StepIndicator;
