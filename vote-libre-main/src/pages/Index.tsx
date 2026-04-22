import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { ShieldCheck, Vote, BarChart3, QrCode, ArrowRight, ClipboardCheck, Settings } from 'lucide-react';
import { motion, useScroll, useTransform, useReducedMotion } from 'framer-motion';
import AnonymityBadge from '@/components/AnonymityBadge';
import HibiscusPattern from '@/components/HibiscusPattern';
import homeBackground from '../../image fond ecran/IMG_1009.webp';

const features = [
  { icon: Vote, title: 'Vote simple', desc: 'Interface intuitive pour voter en quelques secondes.', color: 'from-primary to-primary/60' },
  { icon: ShieldCheck, title: 'Anonymat garanti', desc: 'Architecture séparant identité et bulletin de vote.', color: 'from-success to-success/60' },
  { icon: QrCode, title: 'Accès par QR code', desc: 'Chaque participant reçoit un QR code unique et personnel.', color: 'from-accent to-accent/60' },
  { icon: BarChart3, title: 'Résultats en temps réel', desc: 'Tableau de bord avec résultats agrégés et taux de participation.', color: 'from-warning to-warning/60' },
];

const Index = () => {
  const navigate = useNavigate();
  const { scrollY } = useScroll();
  const shouldReduceMotion = useReducedMotion();
  const heroBgY = useTransform(scrollY, [0, 800], [0, shouldReduceMotion ? 0 : 80]);

  return (
    <div className="min-h-screen">
      {/* Hero with custom background image */}
      <section className="relative overflow-hidden" aria-label="Accueil – Plateforme de sondage anonyme">
        {/* Background image — z-0, pas de z négatif pour éviter le conflit avec le transform framer-motion */}
        <motion.div
          aria-hidden="true"
          className="absolute inset-0 z-0 bg-cover bg-center md:bg-[center_28%] bg-no-repeat bg-[hsl(200,70%,14%)]"
          style={{ backgroundImage: `url(${homeBackground})`, y: heroBgY }}
        />
        {/* Hibiscus filigrane */}
        <div className="absolute inset-0 z-[1] pointer-events-none select-none" aria-hidden="true">
          <HibiscusPattern className="absolute -left-10 -top-10 h-72 w-72 opacity-30 rotate-12" />
          <HibiscusPattern className="absolute right-4 top-8 h-48 w-48 opacity-40 -rotate-12" />
          <HibiscusPattern className="absolute left-1/3 bottom-4 h-56 w-56 opacity-30 rotate-45" />
          <HibiscusPattern className="absolute -right-8 bottom-0 h-64 w-64 opacity-50 rotate-[200deg]" />
          <HibiscusPattern className="absolute left-[60%] top-1/4 h-36 w-36 opacity-25 -rotate-45" />
        </div>
        {/* Zero voile: aucun overlay sur le fond */}
        <div aria-hidden="true" className="hidden" />
        <div className="container relative z-[3] mx-auto px-3 pt-28 pb-8 sm:pt-36 md:pt-60 md:pb-24">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="mx-auto max-w-2xl text-center"
          >
            <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-4 py-1.5 text-sm font-medium text-white/90 backdrop-blur-sm">
              <Vote className="h-4 w-4" aria-hidden="true" />
              Plateforme de sondage anonyme
            </div>
            <h1 className="text-3xl font-extrabold tracking-tight text-white sm:text-4xl md:text-5xl lg:text-6xl drop-shadow-lg">
              Votez en toute
              <span className="block bg-gradient-to-r from-white to-white/60 bg-clip-text text-transparent">
                confidentialité
              </span>
            </h1>
            <p className="mx-auto mt-5 max-w-lg text-sm leading-relaxed text-white/75 sm:text-base md:mt-6 md:text-lg">
              <span className="font-semibold text-white/85">Votre collectivité place votre parole au coeur de l'action publique</span> : une solution moderne pour recueillir l'avis de vos parties prenantes, dans un cadre garantissant l'anonymat total et la transparence des résultats.
            </p>
            <div className="mt-6 flex flex-col items-center gap-2.5 sm:mt-8 sm:gap-3 sm:flex-row sm:justify-center sm:flex-wrap">
              <Button size="lg" onClick={() => navigate('/admin')} className="h-12 w-full border-0 bg-white text-[hsl(200,75%,35%)] font-semibold shadow-lg hover:bg-white/90 sm:h-11 sm:w-auto">
                <Settings className="mr-2 h-4 w-4" />
                <span className="hidden xs:inline">Espace</span> Admin
              </Button>
              <Button size="lg" variant="outline" onClick={() => navigate('/controleur/login')} className="h-12 w-full border-white/25 bg-white/10 text-white backdrop-blur-sm hover:bg-white/20 sm:h-11 sm:w-auto">
                <ClipboardCheck className="mr-2 h-4 w-4" />
                <span className="hidden xs:inline">Espace</span> Contrôleur
              </Button>
              <Button size="lg" variant="outline" onClick={() => navigate('/access')} className="h-12 w-full border-white/25 bg-white/10 text-white backdrop-blur-sm hover:bg-white/20 sm:h-11 sm:w-auto">
                <QrCode className="mr-2 h-3 w-3" />
                <span className="hidden xs:inline">Accéder avec un</span> QR Code
              </Button>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Features */}
      <section className="container mx-auto px-3 py-8 md:px-4 md:py-24">
        <div className="mx-auto max-w-3xl text-center">
          <h2 className="text-2xl font-bold text-foreground md:text-3xl">Comment ça fonctionne ?</h2>
          <p className="mt-3 text-muted-foreground">Un processus simple, sécurisé et entièrement anonyme.</p>
        </div>
        <div className="mx-auto mt-8 grid max-w-4xl gap-3 sm:grid-cols-2 sm:gap-4">
          {features.map((f, i) => (
            <motion.div
              key={f.title}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.1 * i }}
              className="group rounded-xl border border-border bg-card p-6 shadow-card transition-all hover:shadow-elevated hover:-translate-y-0.5"
            >
              <div className="flex items-center gap-3">
                <div className={`inline-flex shrink-0 rounded-lg bg-gradient-to-br ${f.color} p-2.5`}>
                  <f.icon className="h-5 w-5 text-primary-foreground" />
                </div>
                <h3 className="text-base font-semibold text-card-foreground">{f.title}</h3>
              </div>
              <p className="mt-3 text-sm leading-relaxed text-muted-foreground">{f.desc}</p>
            </motion.div>
          ))}
        </div>
      </section>

      {/* Anonymity section */}
      <section className="border-t border-border bg-muted/50">
        <div className="container mx-auto px-3 py-8 md:px-4 md:py-16">
          <div className="mx-auto max-w-xl">
            <AnonymityBadge />
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-border bg-card py-6 md:py-8">
        <div className="container mx-auto px-3 text-center text-xs md:px-4 md:text-sm text-muted-foreground">
          <p>© 2026 VoteAnonyme — Plateforme de sondage confidentielle</p>
          <p className="mt-1 text-xs">Mode démonstration • Aucune donnée réelle n'est collectée</p>
        </div>
      </footer>
    </div>
  );
};

export default Index;
