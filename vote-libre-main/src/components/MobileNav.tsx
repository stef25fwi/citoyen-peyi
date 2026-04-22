import { useNavigate, useLocation } from 'react-router-dom';
import { LayoutDashboard, PlusCircle, UserCheck, BarChart3 } from 'lucide-react';

const tabs = [
  { icon: LayoutDashboard, label: 'Sondages', path: '/admin' },
  { icon: UserCheck, label: 'Inscriptions', path: '/admin/inscriptions' },
  { icon: PlusCircle, label: 'Créer', path: '/admin/create' },
  { icon: BarChart3, label: 'Analytiques', path: '/admin/analytics' },
];

const MobileNav = () => {
  const navigate = useNavigate();
  const { pathname } = useLocation();

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 border-t border-border bg-card/95 backdrop-blur-lg md:hidden">
      <div className="flex items-center justify-around py-2">
        {tabs.map(tab => {
          const active = pathname === tab.path;
          return (
            <button
              key={tab.label}
              onClick={() => navigate(tab.path)}
              className={`flex flex-col items-center gap-0.5 px-4 py-1.5 text-xs font-medium transition-colors ${
                active ? 'text-primary' : 'text-muted-foreground'
              }`}
            >
              <tab.icon className="h-5 w-5" />
              {tab.label}
            </button>
          );
        })}
      </div>
    </nav>
  );
};

export default MobileNav;
