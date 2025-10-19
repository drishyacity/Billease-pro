import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { 
  Plus, 
  Search, 
  Users,
  Edit,
  Trash2,
  Phone,
  Mail,
  MapPin,
  DollarSign,
  TrendingUp
} from 'lucide-react';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from './ui/table';
import { Badge } from './ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './ui/tabs';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from './ui/dialog';
import { Textarea } from './ui/textarea';

const parties = [
  { 
    id: 'C001', 
    name: 'Raj Electronics', 
    type: 'Customer',
    phone: '+91 98765 43210', 
    email: 'raj@electronics.com',
    gstin: '27AABCU9603R1ZM',
    balance: 45600,
    status: 'Active',
    lastTransaction: '2024-10-19',
    totalSales: 345600
  },
  { 
    id: 'C002', 
    name: 'Modern Traders', 
    type: 'Customer',
    phone: '+91 98765 43211', 
    email: 'modern@traders.com',
    gstin: '27AABCU9603R1ZN',
    balance: -23400,
    status: 'Active',
    lastTransaction: '2024-10-18',
    totalSales: 567800
  },
  { 
    id: 'S001', 
    name: 'Wholesale Suppliers', 
    type: 'Supplier',
    phone: '+91 98765 43212', 
    email: 'wholesale@suppliers.com',
    gstin: '27AABCU9603R1ZO',
    balance: 125000,
    status: 'Active',
    lastTransaction: '2024-10-17',
    totalSales: 1245000
  },
  { 
    id: 'C003', 
    name: 'City Mart', 
    type: 'Customer',
    phone: '+91 98765 43213', 
    email: 'city@mart.com',
    gstin: '27AABCU9603R1ZP',
    balance: 0,
    status: 'Active',
    lastTransaction: '2024-10-18',
    totalSales: 789000
  },
  { 
    id: 'C004', 
    name: 'Sharma & Sons', 
    type: 'Customer',
    phone: '+91 98765 43214', 
    email: 'sharma@sons.com',
    gstin: '27AABCU9603R1ZQ',
    balance: 12300,
    status: 'Inactive',
    lastTransaction: '2024-10-15',
    totalSales: 123000
  },
];

export function CustomerManager() {
  const [searchQuery, setSearchQuery] = useState('');
  const [activeTab, setActiveTab] = useState('all');
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);

  const filteredParties = parties.filter(party => {
    const matchesSearch = party.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         party.phone.includes(searchQuery) ||
                         party.email.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesType = activeTab === 'all' || 
                       (activeTab === 'customers' && party.type === 'Customer') ||
                       (activeTab === 'suppliers' && party.type === 'Supplier');
    return matchesSearch && matchesType;
  });

  const totalCustomers = parties.filter(p => p.type === 'Customer').length;
  const totalSuppliers = parties.filter(p => p.type === 'Supplier').length;
  const totalReceivable = parties.filter(p => p.balance > 0).reduce((sum, p) => sum + p.balance, 0);
  const totalPayable = Math.abs(parties.filter(p => p.balance < 0).reduce((sum, p) => sum + p.balance, 0));

  return (
    <div className="p-6 space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl text-gray-900">Party Management</h1>
          <p className="text-gray-500">Manage customers and suppliers</p>
        </div>
        <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
          <DialogTrigger asChild>
            <Button className="gap-2 bg-blue-600 hover:bg-blue-700">
              <Plus className="h-4 w-4" />
              Add Party
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle>Add New Party</DialogTitle>
            </DialogHeader>
            <div className="grid grid-cols-2 gap-4 py-4">
              <div className="space-y-2 col-span-2">
                <Label>Party Type *</Label>
                <div className="flex gap-4">
                  <label className="flex items-center gap-2">
                    <input type="radio" name="partyType" value="customer" defaultChecked />
                    <span>Customer</span>
                  </label>
                  <label className="flex items-center gap-2">
                    <input type="radio" name="partyType" value="supplier" />
                    <span>Supplier</span>
                  </label>
                </div>
              </div>
              <div className="space-y-2 col-span-2">
                <Label>Party Name *</Label>
                <Input placeholder="Enter party name" />
              </div>
              <div className="space-y-2">
                <Label>Phone Number *</Label>
                <Input placeholder="+91 " />
              </div>
              <div className="space-y-2">
                <Label>Email</Label>
                <Input type="email" placeholder="email@example.com" />
              </div>
              <div className="space-y-2">
                <Label>GSTIN</Label>
                <Input placeholder="Enter GSTIN" />
              </div>
              <div className="space-y-2">
                <Label>Opening Balance</Label>
                <Input type="number" defaultValue={0} />
              </div>
              <div className="space-y-2 col-span-2">
                <Label>Billing Address</Label>
                <Textarea placeholder="Enter billing address" rows={3} />
              </div>
              <div className="space-y-2">
                <Label>City</Label>
                <Input placeholder="Enter city" />
              </div>
              <div className="space-y-2">
                <Label>State</Label>
                <Input placeholder="Enter state" />
              </div>
              <div className="space-y-2">
                <Label>PIN Code</Label>
                <Input placeholder="Enter PIN code" />
              </div>
              <div className="space-y-2">
                <Label>Credit Limit</Label>
                <Input type="number" placeholder="0" />
              </div>
            </div>
            <div className="flex justify-end gap-2">
              <Button variant="outline" onClick={() => setIsAddDialogOpen(false)}>
                Cancel
              </Button>
              <Button className="bg-blue-600 hover:bg-blue-700">
                Save Party
              </Button>
            </div>
          </DialogContent>
        </Dialog>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card className="border-l-4 border-l-blue-500">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-gray-600">Total Customers</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl text-gray-900">{totalCustomers}</div>
            <p className="text-xs text-gray-500 mt-1">Active parties</p>
          </CardContent>
        </Card>

        <Card className="border-l-4 border-l-green-500">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-gray-600">Total Suppliers</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl text-gray-900">{totalSuppliers}</div>
            <p className="text-xs text-gray-500 mt-1">Active suppliers</p>
          </CardContent>
        </Card>

        <Card className="border-l-4 border-l-orange-500">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-gray-600">Total Receivable</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl text-gray-900">₹ {totalReceivable.toLocaleString()}</div>
            <p className="text-xs text-orange-600 mt-1">To be collected</p>
          </CardContent>
        </Card>

        <Card className="border-l-4 border-l-red-500">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-gray-600">Total Payable</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl text-gray-900">₹ {totalPayable.toLocaleString()}</div>
            <p className="text-xs text-red-600 mt-1">To be paid</p>
          </CardContent>
        </Card>
      </div>

      {/* Main Table */}
      <Card>
        <CardHeader>
          <div className="flex flex-col md:flex-row justify-between gap-4">
            <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
              <div className="flex justify-between items-center">
                <TabsList>
                  <TabsTrigger value="all">All Parties</TabsTrigger>
                  <TabsTrigger value="customers">Customers</TabsTrigger>
                  <TabsTrigger value="suppliers">Suppliers</TabsTrigger>
                </TabsList>
                <div className="relative w-80">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                  <Input 
                    placeholder="Search parties..." 
                    className="pl-10"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                  />
                </div>
              </div>
            </Tabs>
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Code</TableHead>
                <TableHead>Party Name</TableHead>
                <TableHead>Type</TableHead>
                <TableHead>Contact</TableHead>
                <TableHead>GSTIN</TableHead>
                <TableHead>Balance</TableHead>
                <TableHead>Total Sales</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredParties.map((party) => (
                <TableRow key={party.id}>
                  <TableCell>{party.id}</TableCell>
                  <TableCell className="text-gray-900">{party.name}</TableCell>
                  <TableCell>
                    <Badge variant={party.type === 'Customer' ? 'default' : 'secondary'}>
                      {party.type}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <div className="space-y-1">
                      <div className="flex items-center gap-1 text-xs">
                        <Phone className="h-3 w-3" />
                        {party.phone}
                      </div>
                      <div className="flex items-center gap-1 text-xs text-gray-500">
                        <Mail className="h-3 w-3" />
                        {party.email}
                      </div>
                    </div>
                  </TableCell>
                  <TableCell className="text-xs">{party.gstin}</TableCell>
                  <TableCell>
                    <span className={party.balance > 0 ? 'text-orange-600' : party.balance < 0 ? 'text-green-600' : 'text-gray-600'}>
                      ₹ {Math.abs(party.balance).toLocaleString()}
                      {party.balance > 0 && ' (Dr)'}
                      {party.balance < 0 && ' (Cr)'}
                    </span>
                  </TableCell>
                  <TableCell>₹ {party.totalSales.toLocaleString()}</TableCell>
                  <TableCell>
                    <Badge variant={party.status === 'Active' ? 'default' : 'secondary'}>
                      {party.status}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <div className="flex gap-1">
                      <Button size="icon" variant="ghost" title="Edit">
                        <Edit className="h-4 w-4" />
                      </Button>
                      <Button size="icon" variant="ghost" title="Delete">
                        <Trash2 className="h-4 w-4 text-red-500" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
