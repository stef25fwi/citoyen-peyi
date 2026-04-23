import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card } from '@/components/ui/card';
import { ArrowLeft, Plus, Trash2, Save } from 'lucide-react';
import { createPollData } from '@/lib/data/poll-store';
import { toast } from 'sonner';

const CreatePoll = () => {
  const navigate = useNavigate();
  const [title, setTitle] = useState('');
  const [question, setQuestion] = useState('');
  const [options, setOptions] = useState(['', '']);
  const [openDate, setOpenDate] = useState('');
  const [closeDate, setCloseDate] = useState('');
  const [qrCount, setQrCount] = useState(50);

  const addOption = () => setOptions([...options, '']);
  const removeOption = (i: number) => setOptions(options.filter((_, idx) => idx !== i));
  const updateOption = (i: number, val: string) => {
    const copy = [...options];
    copy[i] = val;
    setOptions(copy);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) {
      toast.error('Le titre du projet est obligatoire.');
      return;
    }
    if (title.trim().length > 255) {
      toast.error('Le titre ne doit pas dépasser 255 caractères.');
      return;
    }
    if (!question.trim()) {
      toast.error('La question du sondage est obligatoire.');
      return;
    }
    if (options.some(o => !o.trim())) {
      toast.error('Toutes les options de vote doivent être remplies.');
      return;
    }
    if (openDate && closeDate && closeDate <= openDate) {
      toast.error('La date de fermeture doit être postérieure à la date d’ouverture.');
      return;
    }

    await createPollData({
      projectTitle: title,
      question,
      options,
      openDate: openDate || new Date().toISOString().split('T')[0],
      closeDate: closeDate || new Date().toISOString().split('T')[0],
      totalVoters: qrCount,
    });

    toast.success('Sondage créé avec succès.');
    navigate('/admin');
  };

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b border-border bg-card">
        <div className="container mx-auto flex items-center gap-3 px-4 py-4">
          <Button variant="ghost" size="icon" onClick={() => navigate('/admin')} className="h-12 w-12">
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <h1 className="text-lg font-bold text-foreground">Créer un sondage</h1>
        </div>
      </header>

      <main className="container mx-auto max-w-2xl px-3 py-6 sm:px-4 sm:py-8">
        <form onSubmit={handleSubmit} className="space-y-6">
          <Card className="border border-border bg-card p-3 shadow-card sm:p-4 md:p-6">
            <h2 className="mb-3 text-sm font-semibold text-card-foreground sm:mb-4 sm:text-base">Informations du projet</h2>
            <div className="space-y-4">
              <div>
                <Label htmlFor="title">Titre du projet</Label>
                <Input id="title" value={title} onChange={e => setTitle(e.target.value)} placeholder="Ex : Réaménagement du centre-ville" className="mt-1.5 h-11" />
              </div>
              <div>
                <Label htmlFor="question">Question du sondage</Label>
                <Input id="question" value={question} onChange={e => setQuestion(e.target.value)} placeholder="Ex : Quelle option préférez-vous ?" className="mt-1.5 h-11" />
              </div>
            </div>
          </Card>

          <Card className="border border-border bg-card p-3 shadow-card sm:p-4 md:p-6">
            <div className="mb-3 flex items-center justify-between sm:mb-4">
              <h2 className="text-sm font-semibold text-card-foreground sm:text-base">Options de vote</h2>
              <Button type="button" variant="outline" size="sm" onClick={addOption}>
                <Plus className="mr-1 h-3 w-3" />
                Ajouter
              </Button>
            </div>
            <div className="space-y-3">
              {options.map((opt, i) => (
                <div key={i} className="flex items-start gap-2 sm:items-center">
                  <div className="flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-full bg-primary/10 text-xs font-semibold text-primary">
                    {i + 1}
                  </div>
                  <Input value={opt} onChange={e => updateOption(i, e.target.value)} placeholder={`Option ${i + 1}`} />
                  {options.length > 2 && (
                    <Button type="button" variant="ghost" size="icon" onClick={() => removeOption(i)} className="flex-shrink-0 self-start text-destructive hover:text-destructive sm:self-center">
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  )}
                </div>
              ))}
            </div>
          </Card>

          <Card className="border border-border bg-card p-3 shadow-card sm:p-4 md:p-6">
            <h2 className="mb-3 text-sm font-semibold text-card-foreground sm:mb-4 sm:text-base">Planification</h2>
            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <Label htmlFor="open">Date d'ouverture</Label>
                <Input id="open" type="date" value={openDate} onChange={e => setOpenDate(e.target.value)} className="mt-1.5 h-11" />
              </div>
              <div>
                <Label htmlFor="close">Date de fermeture</Label>
                <Input id="close" type="date" value={closeDate} onChange={e => setCloseDate(e.target.value)} className="mt-1.5 h-11" />
              </div>
            </div>
          </Card>

          <Card className="border border-border bg-card p-3 shadow-card sm:p-4 md:p-6">
            <h2 className="mb-3 text-sm font-semibold text-card-foreground sm:mb-4 sm:text-base">QR Codes</h2>
            <div>
              <Label htmlFor="qr">Nombre de QR codes à générer</Label>
              <Input id="qr" type="number" min={1} max={1000} value={qrCount} onChange={e => setQrCount(Number(e.target.value))} className="mt-1.5 h-11 w-full sm:max-w-[200px]" />
              <p className="mt-2 text-xs text-muted-foreground">
                Chaque QR code est unique et permet à un seul participant d'accéder au vote.
              </p>
            </div>
          </Card>

          <div className="flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
            <Button type="button" variant="outline" onClick={() => navigate('/admin')} className="w-full sm:w-auto">Annuler</Button>
            <Button type="submit" className="gradient-primary w-full border-0 text-primary-foreground sm:w-auto">
              <Save className="mr-2 h-4 w-4" />
              Créer le sondage
            </Button>
          </div>
        </form>
      </main>
    </div>
  );
};

export default CreatePoll;
