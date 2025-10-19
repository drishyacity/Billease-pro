import { NavSection } from '../App';
import { 
  LayoutDashboard, 
  FileText, 
  Package, 
  Users, 
  BarChart3, 
  Settings,
  Store,
  Calculator,
  TrendingUp
} from 'lucide-react';
import { Button } from './ui/button';
import { Separator } from './ui/separator';

interface SidebarProps {
  activeSection: NavSection;
  onNavigate: (section: NavSection) => void;
}

export function Sidebar({ activeSection, onNavigate }: SidebarProps) {
  const navItems = [
    { id: 'dashboard' as NavSection, label: 'Dashboard', icon: LayoutDashboard },
    { id: 'invoice' as NavSection, label: 'Billing', icon: FileText },
    { id: 'inventory' as NavSection, label: 'Inventory', icon: Package },
    { id: 'customers' as NavSection, label: 'Parties', icon: Users },
    { id: 'reports' as NavSection, label: 'Reports', icon: BarChart3 },
    { id: 'settings' as NavSection, label: 'Settings', icon: Settings },
  ];

  return (
    <div className="w-64 bg-gradient-to-b from-blue-900 to-blue-800 text-white flex flex-col shadow-xl">
      <div className="p-6">
        <div className="flex items-center gap-3 mb-2">
          <div className="bg-white rounded-lg p-2">
            <Calculator className="h-6 w-6 text-blue-900" />
          </div>
          <div>
            <h1 className="text-xl tracking-tight">ProBill ERP</h1>
            <p className="text-xs text-blue-200">Enterprise Edition</p>
          </div>
        </div>
      </div>
      
      <Separator className="bg-blue-700" />
      
      <div className="flex-1 p-4 space-y-2">
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeSection === item.id;
          
          return (
            <button
              key={item.id}
              onClick={() => onNavigate(item.id)}
              className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-all ${
                isActive 
                  ? 'bg-white text-blue-900 shadow-lg' 
                  : 'text-blue-100 hover:bg-blue-700'
              }`}
            >
              <Icon className="h-5 w-5" />
              <span>{item.label}</span>
            </button>
          );
        })}
      </div>

      <div className="p-4 border-t border-blue-700">
        <div className="bg-blue-700 rounded-lg p-3 text-xs">
          <div className="flex justify-between mb-1">
            <span className="text-blue-200">Financial Year</span>
            <span>2024-25</span>
          </div>
          <div className="flex justify-between">
            <span className="text-blue-200">Company</span>
            <span>ABC Enterprises</span>
          </div>
        </div>
      </div>
    </div>
  );
}
