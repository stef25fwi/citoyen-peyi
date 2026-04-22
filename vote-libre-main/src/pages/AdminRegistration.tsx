import { useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Checkbox } from '@/components/ui/checkbox';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import MobileNav from '@/components/MobileNav';
import CommuneAutocomplete, { CommuneSuggestion } from '@/components/CommuneAutocomplete';
import {
  ArrowLeft, UserCheck, Users, QrCode, Plus, Shield, CheckCircle2, Clock, Hash, MapPin, UserRound, History
} from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  CommuneConfig, RegistrationCode, ID_DOCUMENT_TYPES, PROOF_OF_ADDRESS_TYPES,
  generateCode, getExpiryDate,
} from '@/lib/registration-data';
import {
  getActiveControleurSession,
  loadControleurActivities,
  recordControleurVerification,
  loadCodes as loadControleurCodes,
} from '@/lib/controleur-codes';
import { toast } from 'sonner';

const AdminRegistration = () => {
  const navigate = useNavigate();

  // Commune config
  const [commune, setCommune] = useState<CommuneConfig | null>(null);
  const [selected, setSelected] = useState<{ commune: CommuneSuggestion; codePostal: string } | null>(null);

  // Codes & validation
  const [codes, setCodes] = useState<RegistrationCode[]>([]);
  const [selectedCode, setSelectedCode] = useState<RegistrationCode | null>(null);
  const [checkedIdDoc, setCheckedIdDoc] = useState<string | null>(null);
  const [checkedAddressDoc, setCheckedAddressDoc] = useState<string | null>(null);
  const [validatedQR, setValidatedQR] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState('verification');
  const [historyRefreshKey, setHistoryRefreshKey] = useState(0);

  const controleurSession = getActiveControleurSession();
  const controleurCodeMeta = controleurSession
    ? loadControleurCodes().find(item => item.code === controleurSession.code) || null
    : null;
  const verificationLogs = controleurSession
    ? loadControleurActivities(controleurSession.code)
    : [];

  const historyEntries = [
    ...(controleurCodeMeta
      ? [{
          id: `assigned-${controleurCodeMeta.id}`,
          type: 'assigned' as const,
          at: controleurCodeMeta.createdAt,
          label: `Code attribue: ${controleurCodeMeta.code}`,
          detail: `Attribue a ${controleurCodeMeta.label}`,
        }]
      : []),
    ...verificationLogs.map(item => ({
      id: item.id,
      type: 'verified' as const,
      at: item.verifiedAt,
      label: `Code verifie: ${item.registrationCode}`,
      detail: `Verification effectuee par ${item.controleurLabel}`,
    })),
  ].sort((a, b) => new Date(b.at).getTime() - new Date(a.at).getTime());

  const stats = useMemo(() => ({
    total: codes.length,
    available: codes.filter(c => c.status === 'available').length,
    assigned: codes.filter(c => c.status === 'assigned').length,
    validated: codes.filter(c => c.status === 'validated').length,
  }), [codes]);

  const canGenerate = commune && codes.length < commune.maxCodes;

  // Setup commune
  const handleSetup = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selected) {
      toast.error('Veuillez sélectionner une commune dans la liste.');
      return;
    }
    const { commune: c, codePostal } = selected;
    setCommune({ name: `${c.nom} (${codePostal})`, population: c.population, maxCodes: c.population });
    toast.success(`Commune "${c.nom}" configurée (${c.population.toLocaleString('fr-FR')} codes max).`);
  };

  // Generate codes
  const handleGenerate = (count: number) => {
    if (!commune) return;
    const remaining = commune.maxCodes - codes.length;
    const toCreate = Math.min(count, remaining);
    if (toCreate <= 0) {
      toast.error('Limite de codes atteinte.');
      return;
    }
    const newCodes: RegistrationCode[] = Array.from({ length: toCreate }, (_, i) => ({
      id: `reg-${Date.now()}-${i}`,
      code: generateCode(),
      createdAt: new Date().toISOString().split('T')[0],
      usedBy: null,
      status: 'available' as const,
      documentType: null,
      validatedAt: null,
      expiresAt: null,
    }));
    setCodes(prev => [...prev, ...newCodes]);
    toast.success(`${toCreate} code(s) généré(s).`);
  };

  // Validate a registration
  const handleValidate = () => {
    if (!selectedCode || !checkedIdDoc || !checkedAddressDoc) return;
    const selectedCodeRef = selectedCode.code;
    const now = new Date().toISOString().split('T')[0];
    const documentType = `${checkedIdDoc} + ${checkedAddressDoc}`;
    setCodes(prev =>
      prev.map(c =>
        c.id === selectedCode.id
          ? { ...c, status: 'validated' as const, documentType, validatedAt: now, expiresAt: getExpiryDate() }
          : c
      )
    );
    const qrData = JSON.stringify({
      code: selectedCode.code,
      validatedAt: now,
      expiresAt: getExpiryDate(),
      commune: commune?.name,
    });
    setValidatedQR(qrData);

    if (controleurSession) {
      recordControleurVerification(controleurSession, selectedCodeRef);
      setHistoryRefreshKey(prev => prev + 1);
    }

    toast.success('Inscription validée ! QR code généré.');
  };

  const resetValidation = () => {
    setSelectedCode(null);
    setCheckedIdDoc(null);
    setCheckedAddressDoc(null);
    setValidatedQR(null);
  };

  // ── Setup screen ──
  if (!commune) {
    return (
      <div className="min-h-screen bg-background pb-20 md:pb-0">
        <header className="border-b border-border bg-card">
          <div className="container mx-auto flex items-center gap-3 px-4 py-4">
            <Button variant="ghost" size="icon" onClick={() => navigate('/admin')} className="h-12 w-12">
              <ArrowLeft className="h-5 w-5" />
            </Button>
            <div className="flex items-center gap-2">
              <UserCheck className="h-5 w-5 text-primary" />
              <h1 className="text-lg font-bold text-foreground">Espace Inscription</h1>
            </div>
          </div>
        </header>

        <main className="container mx-auto flex flex-1 items-center justify-center px-4 py-12">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="w-full max-w-md"
          >
            <Card className="border border-border shadow-card">
              <CardHeader className="text-center">
                <div className="mx-auto mb-3 flex h-16 w-16 items-center justify-center rounded-2xl bg-primary/10">
                  <Users className="h-8 w-8 text-primary" />
                </div>
                <CardTitle className="text-xl">Configurer la commune</CardTitle>
                <CardDescription>
                  Le nombre d'habitants détermine le nombre maximal de codes d'inscription.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <form onSubmit={handleSetup} className="space-y-4">
                  <div>
                    <label className="mb-1.5 block text-sm font-medium text-foreground">
                      Commune (nom ou code postal)
                    </label>
                    <CommuneAutocomplete
                      onSelect={(c, cp) => setSelected({ commune: c, codePostal: cp })}
                    />
                    <p className="mt-1.5 text-xs text-muted-foreground">
                      Recherche en temps réel via l'API officielle geo.api.gouv.fr
                    </p>
                  </div>

                  {selected && (
                    <motion.div
                      initial={{ opacity: 0, y: -5 }}
                      animate={{ opacity: 1, y: 0 }}
                      className="rounded-lg border border-primary/30 bg-primary/5 p-3"
                    >
                      <div className="flex items-start gap-3">
                        <MapPin className="mt-0.5 h-4 w-4 shrink-0 text-primary" />
                        <div className="text-sm">
                          <p className="font-semibold text-foreground">{selected.commune.nom}</p>
                          <p className="text-xs text-muted-foreground">
                            Code postal : <span className="font-mono font-medium text-foreground">{selected.codePostal}</span>
                          </p>
                          <p className="text-xs text-muted-foreground">
                            Population : <span className="font-medium text-foreground">{selected.commune.population.toLocaleString('fr-FR')}</span> habitants
                          </p>
                        </div>
                      </div>
                    </motion.div>
                  )}

                  <Button
                    type="submit"
                    disabled={!selected}
                    className="gradient-primary w-full border-0 text-primary-foreground"
                    size="lg"
                  >
                    Configurer
                  </Button>
                </form>
              </CardContent>
            </Card>
          </motion.div>
        </main>
        <MobileNav />
      </div>
    );
  }

  // ── Main dashboard ──
  return (
    <div className="min-h-screen bg-background pb-20 md:pb-0">
      <header className="border-b border-border bg-card">
        <div className="container mx-auto flex items-center justify-between px-4 py-4">
          <div className="flex items-center gap-3">
            <Button variant="ghost" size="icon" onClick={() => navigate('/admin')} className="h-12 w-12">
              <ArrowLeft className="h-5 w-5" />
            </Button>
            <div>
              <div className="flex items-center gap-2">
                <UserCheck className="h-5 w-5 text-primary" />
                <h1 className="text-lg font-bold text-foreground">Inscriptions</h1>
              </div>
              <div className="flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
                <span>{commune.name} · {commune.population} hab.</span>
                {controleurSession && (
                  <span className="inline-flex items-center gap-1 rounded-full border border-primary/30 bg-primary/10 px-2 py-0.5 text-primary">
                    <UserRound className="h-3 w-3" />
                    Connecte: {controleurSession.label}
                  </span>
                )}
              </div>
            </div>
          </div>
          <Button
            onClick={() => handleGenerate(1)}
            disabled={!canGenerate}
            className="hidden gradient-primary border-0 text-primary-foreground md:inline-flex"
            size="sm"
          >
            <Plus className="mr-1 h-4 w-4" /> Générer un code
          </Button>
        </div>
      </header>

      <main className="container mx-auto space-y-4 px-3 py-4 sm:space-y-6 sm:px-4 sm:py-6">
        {/* Stats */}
        <div className="grid grid-cols-2 gap-2 sm:grid-cols-4 sm:gap-3">
          {[
            { label: 'Total', value: stats.total, icon: Hash, color: 'bg-primary/10 text-primary' },
            { label: 'Disponibles', value: stats.available, icon: Clock, color: 'bg-accent/10 text-accent' },
            { label: 'En attente', value: stats.assigned, icon: Shield, color: 'bg-warning/10 text-warning' },
            { label: 'Validés', value: stats.validated, icon: CheckCircle2, color: 'bg-success/10 text-success' },
          ].map(s => (
            <div key={s.label} className="rounded-xl border border-border bg-card p-4 shadow-card">
              <div className="flex items-center gap-3">
                <div className={`flex h-10 w-10 items-center justify-center rounded-lg ${s.color}`}>
                  <s.icon className="h-5 w-5" />
                </div>
                <div>
                  <p className="text-2xl font-bold text-foreground">{s.value}</p>
                  <p className="text-xs text-muted-foreground">{s.label}</p>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Capacity bar */}
        <div className="rounded-xl border border-border bg-card p-4 shadow-card">
          <div className="mb-2 flex items-center justify-between text-sm">
            <span className="text-muted-foreground">Codes générés</span>
            <span className="font-semibold text-foreground">{codes.length} / {commune.maxCodes}</span>
          </div>
          <div className="h-2 w-full overflow-hidden rounded-full bg-muted">
            <motion.div
              className="h-full rounded-full bg-primary"
              initial={{ width: 0 }}
              animate={{ width: `${(codes.length / commune.maxCodes) * 100}%` }}
              transition={{ duration: 0.5 }}
            />
          </div>
        </div>

        <Tabs value={activeTab} onValueChange={setActiveTab}>
          <TabsList className="grid w-full max-w-md grid-cols-2">
            <TabsTrigger value="verification">Verification</TabsTrigger>
            <TabsTrigger value="history">Historique</TabsTrigger>
          </TabsList>

          <TabsContent value="verification">
            {/* Validation panel */}
            <AnimatePresence mode="wait">
          {validatedQR ? (
            <motion.div
              key="qr"
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0 }}
            >
              <Card className="border border-border shadow-card">
                <CardHeader className="text-center">
                  <div className="mx-auto mb-2 flex h-14 w-14 items-center justify-center rounded-full bg-success/10">
                    <CheckCircle2 className="h-7 w-7 text-success" />
                  </div>
                  <CardTitle className="text-lg">Inscription validée !</CardTitle>
                  <CardDescription>
                    L'utilisateur peut scanner ce QR code. Validité : 2 ans.
                  </CardDescription>
                </CardHeader>
                <CardContent className="flex flex-col items-center gap-4">
                  <div className="rounded-2xl border-2 border-border bg-background p-4">
                    <QRCodeSVG value={validatedQR} size={200} />
                  </div>
                  <p className="text-center text-xs text-muted-foreground font-mono break-all max-w-xs">
                    {selectedCode?.code}
                  </p>
                  <Button onClick={resetValidation} variant="outline" className="w-full max-w-xs">
                    Nouvelle vérification
                  </Button>
                </CardContent>
              </Card>
            </motion.div>
          ) : selectedCode ? (
            <motion.div
              key="verify"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0 }}
            >
              <Card className="border border-border shadow-card">
                <CardHeader>
                  <CardTitle className="text-lg">Vérification du document</CardTitle>
                  <CardDescription>
                    Code : <span className="font-mono font-semibold text-foreground">{selectedCode.code}</span>
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-5">
                  <p className="text-sm text-muted-foreground">
                    L'habitant doit présenter <span className="font-semibold text-foreground">une pièce d'identité</span> et <span className="font-semibold text-foreground">un justificatif de domicile</span>.
                  </p>

                  {/* ID document */}
                  <div className="space-y-2">
                    <h3 className="text-sm font-semibold text-foreground flex items-center gap-2">
                      <Shield className="h-4 w-4 text-primary" />
                      1. Pièce d'identité
                    </h3>
                    <div className="space-y-2">
                      {ID_DOCUMENT_TYPES.map(doc => (
                        <label
                          key={doc}
                          className={`flex cursor-pointer items-center gap-3 rounded-xl border p-3 transition-all ${
                            checkedIdDoc === doc
                              ? 'border-primary bg-primary/5 shadow-sm'
                              : 'border-border bg-card hover:border-primary/30'
                          }`}
                        >
                          <Checkbox
                            checked={checkedIdDoc === doc}
                            onCheckedChange={() => setCheckedIdDoc(checkedIdDoc === doc ? null : doc)}
                          />
                          <span className="text-sm font-medium text-foreground">{doc}</span>
                        </label>
                      ))}
                    </div>
                  </div>

                  {/* Proof of address */}
                  <div className="space-y-2">
                    <h3 className="text-sm font-semibold text-foreground flex items-center gap-2">
                      <Hash className="h-4 w-4 text-accent" />
                      2. Justificatif de domicile
                    </h3>
                    <div className="space-y-2">
                      {PROOF_OF_ADDRESS_TYPES.map(doc => (
                        <label
                          key={doc}
                          className={`flex cursor-pointer items-center gap-3 rounded-xl border p-3 transition-all ${
                            checkedAddressDoc === doc
                              ? 'border-primary bg-primary/5 shadow-sm'
                              : 'border-border bg-card hover:border-primary/30'
                          }`}
                        >
                          <Checkbox
                            checked={checkedAddressDoc === doc}
                            onCheckedChange={() => setCheckedAddressDoc(checkedAddressDoc === doc ? null : doc)}
                          />
                          <span className="text-sm font-medium text-foreground">{doc}</span>
                        </label>
                      ))}
                    </div>
                  </div>

                  <div className="flex gap-3 pt-2">
                    <Button variant="outline" onClick={resetValidation} className="flex-1">
                      Annuler
                    </Button>
                    <Button
                      onClick={handleValidate}
                      disabled={!checkedIdDoc || !checkedAddressDoc}
                      className="flex-1 gradient-primary border-0 text-primary-foreground"
                    >
                      <QrCode className="mr-2 h-4 w-4" />
                      Valider & Générer QR
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </motion.div>
          ) : null}
            </AnimatePresence>

            {/* Code list */}
            {codes.length > 0 && !selectedCode && !validatedQR && (
          <section>
            <h2 className="mb-3 text-base font-semibold text-foreground">Codes d'inscription</h2>
            <div className="space-y-2">
              {codes.map(c => (
                <motion.div
                  key={c.id}
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  className="flex flex-col gap-3 rounded-xl border border-border bg-card p-4 shadow-card sm:flex-row sm:items-center sm:justify-between"
                >
                  <div className="flex w-full min-w-0 items-center gap-3 sm:w-auto">
                    <div className={`flex h-9 w-9 items-center justify-center rounded-lg ${
                      c.status === 'validated' ? 'bg-success/10 text-success'
                        : c.status === 'assigned' ? 'bg-warning/10 text-warning'
                        : 'bg-primary/10 text-primary'
                    }`}>
                      {c.status === 'validated' ? <CheckCircle2 className="h-4 w-4" /> : <Hash className="h-4 w-4" />}
                    </div>
                    <div className="min-w-0">
                      <p className="break-all font-mono text-sm font-semibold text-foreground">{c.code}</p>
                      <p className="text-xs text-muted-foreground break-words">
                        {c.status === 'validated'
                          ? `Validé le ${c.validatedAt} · Expire ${c.expiresAt}`
                          : `Créé le ${c.createdAt}`
                        }
                      </p>
                    </div>
                  </div>
                  <div className="flex w-full items-center justify-between gap-2 sm:w-auto sm:justify-end">
                    <Badge variant={c.status === 'validated' ? 'default' : 'secondary'} className="text-xs">
                      {c.status === 'validated' ? 'Validé' : c.status === 'assigned' ? 'Attribué' : 'Disponible'}
                    </Badge>
                    {c.status === 'available' && (
                      <Button
                        size="sm"
                        variant="outline"
                        className="sm:w-auto"
                        onClick={() => {
                          setCodes(prev => prev.map(x => x.id === c.id ? { ...x, status: 'assigned' as const } : x));
                          setSelectedCode({ ...c, status: 'assigned' });
                        }}
                      >
                        Vérifier
                      </Button>
                    )}
                  </div>
                </motion.div>
              ))}
            </div>
          </section>
            )}

            {/* Empty state */}
            {codes.length === 0 && (
          <div className="flex flex-col items-center justify-center py-16 text-center">
            <div className="mb-4 flex h-20 w-20 items-center justify-center rounded-2xl bg-muted">
              <QrCode className="h-10 w-10 text-muted-foreground" />
            </div>
            <h3 className="text-lg font-semibold text-foreground">Aucun code généré</h3>
            <p className="mt-1 max-w-xs text-sm text-muted-foreground">
              Générez des codes d'inscription pour permettre aux habitants de s'inscrire.
            </p>
            <Button onClick={() => handleGenerate(10)} className="mt-6 gradient-primary border-0 text-primary-foreground">
              <Plus className="mr-2 h-4 w-4" />
              Générer 10 codes
            </Button>
          </div>
            )}
          </TabsContent>

          <TabsContent value="history" key={historyRefreshKey}>
            <Card className="border border-border shadow-card">
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-lg">
                  <History className="h-5 w-5 text-primary" />
                  Historique des activites
                </CardTitle>
                <CardDescription>
                  {controleurSession
                    ? `Journal de ${controleurSession.label}: code attribue et verifications effectuees.`
                    : 'Connectez-vous en tant que controleur pour consulter votre historique personnel.'}
                </CardDescription>
              </CardHeader>
              <CardContent>
                {!controleurSession ? (
                  <div className="rounded-lg border border-dashed border-border p-5 text-sm text-muted-foreground">
                    Aucun controleur connecte.
                  </div>
                ) : historyEntries.length === 0 ? (
                  <div className="rounded-lg border border-dashed border-border p-5 text-sm text-muted-foreground">
                    Aucune activite enregistree pour le moment.
                  </div>
                ) : (
                  <ul className="space-y-2">
                    {historyEntries.map(entry => (
                      <li key={entry.id} className="rounded-xl border border-border bg-card p-4">
                        <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                          <div>
                            <p className="text-sm font-semibold text-foreground">{entry.label}</p>
                            <p className="mt-1 text-xs text-muted-foreground">{entry.detail}</p>
                          </div>
                          <Badge variant={entry.type === 'verified' ? 'default' : 'secondary'} className="w-fit">
                            {entry.type === 'verified' ? 'Verifie' : 'Attribue'}
                          </Badge>
                        </div>
                        <p className="mt-2 text-xs text-muted-foreground">
                          {new Date(entry.at).toLocaleString('fr-FR')}
                        </p>
                      </li>
                    ))}
                  </ul>
                )}
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </main>

      {/* FAB mobile */}
      {canGenerate && !selectedCode && !validatedQR && (
        <button
          onClick={() => handleGenerate(1)}
          className="fixed bottom-20 right-4 z-50 flex h-16 w-16 items-center justify-center rounded-full gradient-primary text-primary-foreground shadow-elevated md:hidden"
        >
          <Plus className="h-6 w-6" />
        </button>
      )}

      <MobileNav />
    </div>
  );
};

export default AdminRegistration;
