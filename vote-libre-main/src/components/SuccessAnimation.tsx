import { motion } from 'framer-motion';
import { Check } from 'lucide-react';

const SuccessAnimation = () => (
  <div className="relative mx-auto h-24 w-24">
    {/* Pulsing rings */}
    {[0, 1, 2].map(i => (
      <motion.div
        key={i}
        className="absolute inset-0 rounded-full border-2 border-[hsl(var(--poll-primary,var(--success)))]"
        initial={{ scale: 0.8, opacity: 0.6 }}
        animate={{ scale: 1.5 + i * 0.3, opacity: 0 }}
        transition={{ duration: 1.5, delay: i * 0.3, repeat: Infinity, repeatDelay: 1 }}
      />
    ))}
    {/* Main circle */}
    <motion.div
      className="absolute inset-0 flex items-center justify-center rounded-full bg-[hsl(var(--poll-primary,var(--success)))]"
      initial={{ scale: 0 }}
      animate={{ scale: 1 }}
      transition={{ type: 'spring', stiffness: 200, damping: 15 }}
    >
      <motion.div
        initial={{ pathLength: 0, opacity: 0 }}
        animate={{ pathLength: 1, opacity: 1 }}
        transition={{ delay: 0.3, duration: 0.4 }}
      >
        <Check className="h-10 w-10 text-primary-foreground" strokeWidth={3} />
      </motion.div>
    </motion.div>
  </div>
);

export default SuccessAnimation;
