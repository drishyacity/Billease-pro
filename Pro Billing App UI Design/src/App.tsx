import { useState } from 'react';
import { Sidebar } from './components/Sidebar';
import { Dashboard } from './components/Dashboard';
import { InvoiceManager } from './components/InvoiceManager';
import { InventoryManager } from './components/InventoryManager';
import { CustomerManager } from './components/CustomerManager';
import { Reports } from './components/Reports';
import { Settings } from './components/Settings';
import { Toaster } from './components/ui/sonner';

export type NavSection = 'dashboard' | 'invoice' | 'inventory' | 'customers' | 'reports' | 'settings';

export default function App() {
  const [activeSection, setActiveSection] = useState<NavSection>('dashboard');

  const renderSection = () => {
    switch (activeSection) {
      case 'dashboard':
        return <Dashboard />;
      case 'invoice':
        return <InvoiceManager />;
      case 'inventory':
        return <InventoryManager />;
      case 'customers':
        return <CustomerManager />;
      case 'reports':
        return <Reports />;
      case 'settings':
        return <Settings />;
      default:
        return <Dashboard />;
    }
  };

  return (
    <div className="flex h-screen bg-gray-50">
      <Sidebar activeSection={activeSection} onNavigate={setActiveSection} />
      <main className="flex-1 overflow-auto">
        {renderSection()}
      </main>
      <Toaster />
    </div>
  );
}
