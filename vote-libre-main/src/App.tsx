import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Route, Routes } from "react-router-dom";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import Index from "./pages/Index";
import NotFound from "./pages/NotFound";
import AdminDashboard from "./pages/AdminDashboard";
import AdminRegistration from "./pages/AdminRegistration";
import CreatePoll from "./pages/CreatePoll";
import PollDetail from "./pages/PollDetail";
import QRAccess from "./pages/QRAccess";
import VotePage from "./pages/VotePage";
import ControleurLogin from "./pages/ControleurLogin";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Index />} />
          <Route path="/admin" element={<AdminDashboard />} />
          <Route path="/controleur/login" element={<ControleurLogin />} />
          <Route path="/admin/inscriptions" element={<AdminRegistration />} />
          <Route path="/admin/create" element={<CreatePoll />} />
          <Route path="/admin/poll/:id" element={<PollDetail />} />
          <Route path="/access" element={<QRAccess />} />
          <Route path="/vote/:token" element={<VotePage />} />
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
