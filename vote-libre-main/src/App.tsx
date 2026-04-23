import { useEffect, useState } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Route, Routes } from "react-router-dom";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import ProtectedRoute from "@/components/ProtectedRoute";
import { ensureFirebaseSession, initializeFirebaseServices } from "@/lib/firebase";
import Index from "./pages/Index";
import NotFound from "./pages/NotFound";
import AdminDashboard from "./pages/AdminDashboard";
import AdminAnalytics from "./pages/AdminAnalytics";
import AdminRegistration from "./pages/AdminRegistration";
import CreatePoll from "./pages/CreatePoll";
import PollDetail from "./pages/PollDetail";
import QRAccess from "./pages/QRAccess";
import VotePage from "./pages/VotePage";
import ControleurLogin from "./pages/ControleurLogin";
import AdminLogin from "./pages/AdminLogin";

initializeFirebaseServices();

const queryClient = new QueryClient();

const App = () => {
  const [isFirebaseReady, setIsFirebaseReady] = useState(!initializeFirebaseServices().configured);

  useEffect(() => {
    let isMounted = true;

    const bootstrapFirebaseSession = async () => {
      await ensureFirebaseSession();
      if (!isMounted) {
        return;
      }

      setIsFirebaseReady(true);
    };

    if (!isFirebaseReady) {
      void bootstrapFirebaseSession();
    }

    return () => {
      isMounted = false;
    };
  }, [isFirebaseReady]);

  if (!isFirebaseReady) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background px-4">
        <div className="max-w-sm text-center">
          <p className="text-sm font-semibold text-foreground">Initialisation sécurisée</p>
          <p className="mt-2 text-sm text-muted-foreground">
            Connexion Firebase en cours pour sécuriser l'accès aux données.
          </p>
        </div>
      </div>
    );
  }

  return (
    <QueryClientProvider client={queryClient}>
      <TooltipProvider>
        <Toaster />
        <Sonner />
        <BrowserRouter>
          <Routes>
            <Route path="/" element={<Index />} />
            <Route path="/admin/login" element={<AdminLogin />} />
            <Route path="/admin" element={<ProtectedRoute allowedRoles={["admin"]} fallbackPath="/admin/login"><AdminDashboard /></ProtectedRoute>} />
            <Route path="/admin/analytics" element={<ProtectedRoute allowedRoles={["admin"]} fallbackPath="/admin/login"><AdminAnalytics /></ProtectedRoute>} />
            <Route path="/controleur/login" element={<ControleurLogin />} />
            <Route path="/admin/inscriptions" element={<ProtectedRoute allowedRoles={["admin", "controller"]} fallbackPath="/"><AdminRegistration /></ProtectedRoute>} />
            <Route path="/admin/create" element={<ProtectedRoute allowedRoles={["admin"]} fallbackPath="/admin/login"><CreatePoll /></ProtectedRoute>} />
            <Route path="/admin/poll/:id" element={<ProtectedRoute allowedRoles={["admin"]} fallbackPath="/admin/login"><PollDetail /></ProtectedRoute>} />
            <Route path="/access" element={<QRAccess />} />
            <Route path="/vote/:token" element={<VotePage />} />
            <Route path="*" element={<NotFound />} />
          </Routes>
        </BrowserRouter>
      </TooltipProvider>
    </QueryClientProvider>
  );
};

export default App;
