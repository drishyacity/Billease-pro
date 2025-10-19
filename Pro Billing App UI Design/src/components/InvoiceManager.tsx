import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { 
  Plus, 
  Search, 
  Printer, 
  FileText, 
  Mail,
  Trash2,
  Calculator,
  Save,
  X,
  Barcode,
  User
} from 'lucide-react';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from './ui/table';
import { Badge } from './ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './ui/tabs';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Separator } from './ui/separator';
import { toast } from 'sonner@2.0.3';

interface InvoiceItem {
  id: string;
  itemName: string;
  hsn: string;
  qty: number;
  unit: string;
  rate: number;
  discount: number;
  gst: number;
  amount: number;
}

const invoiceList = [
  { id: 'INV-1024', customer: 'Raj Electronics', amount: 45600, status: 'Paid', date: '2024-10-19', type: 'Sales' },
  { id: 'INV-1023', customer: 'Modern Traders', amount: 23400, status: 'Pending', date: '2024-10-18', type: 'Sales' },
  { id: 'INV-1022', customer: 'City Mart', amount: 67800, status: 'Paid', date: '2024-10-18', type: 'Sales' },
  { id: 'INV-1021', customer: 'Sharma & Sons', amount: 12300, status: 'Overdue', date: '2024-10-15', type: 'Sales' },
  { id: 'PUR-2024', customer: 'Wholesale Suppliers', amount: 125000, status: 'Paid', date: '2024-10-17', type: 'Purchase' },
];

export function InvoiceManager() {
  const [activeTab, setActiveTab] = useState('create');
  const [items, setItems] = useState<InvoiceItem[]>([]);
  const [searchQuery, setSearchQuery] = useState('');

  const addItem = () => {
    const newItem: InvoiceItem = {
      id: Date.now().toString(),
      itemName: '',
      hsn: '',
      qty: 1,
      unit: 'PCS',
      rate: 0,
      discount: 0,
      gst: 18,
      amount: 0,
    };
    setItems([...items, newItem]);
  };

  const removeItem = (id: string) => {
    setItems(items.filter(item => item.id !== id));
  };

  const calculateTotal = () => {
    const subtotal = items.reduce((sum, item) => sum + item.amount, 0);
    const taxTotal = items.reduce((sum, item) => {
      const taxableAmount = item.qty * item.rate * (1 - item.discount / 100);
      return sum + (taxableAmount * item.gst / 100);
    }, 0);
    return { subtotal, taxTotal, total: subtotal + taxTotal };
  };

  const totals = calculateTotal();

  const filteredInvoices = invoiceList.filter(invoice => 
    invoice.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
    invoice.customer.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="p-6 space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl text-gray-900">Billing & Invoicing</h1>
          <p className="text-gray-500">Create and manage sales & purchase invoices</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" className="gap-2">
            <Barcode className="h-4 w-4" />
            Scan Barcode (F9)
          </Button>
          <Button className="gap-2 bg-blue-600 hover:bg-blue-700">
            <Plus className="h-4 w-4" />
            New Invoice (F2)
          </Button>
        </div>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full max-w-md grid-cols-2">
          <TabsTrigger value="create">Create Invoice</TabsTrigger>
          <TabsTrigger value="list">Invoice List</TabsTrigger>
        </TabsList>

        <TabsContent value="create" className="space-y-4 mt-4">
          <Card>
            <CardHeader className="bg-gradient-to-r from-blue-50 to-blue-100">
              <div className="flex justify-between items-center">
                <CardTitle className="text-gray-900">New Sales Invoice</CardTitle>
                <div className="flex gap-2">
                  <Badge variant="outline" className="text-lg px-4 py-1">INV-1025</Badge>
                </div>
              </div>
            </CardHeader>
            <CardContent className="pt-6">
              {/* Invoice Header */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                <div className="space-y-2">
                  <Label>Invoice Type</Label>
                  <Select defaultValue="sales">
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="sales">Sales Invoice</SelectItem>
                      <SelectItem value="purchase">Purchase Invoice</SelectItem>
                      <SelectItem value="estimate">Estimate</SelectItem>
                      <SelectItem value="return">Sales Return</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label>Party Name</Label>
                  <div className="flex gap-2">
                    <Select>
                      <SelectTrigger>
                        <SelectValue placeholder="Select customer" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="raj">Raj Electronics</SelectItem>
                        <SelectItem value="modern">Modern Traders</SelectItem>
                        <SelectItem value="city">City Mart</SelectItem>
                        <SelectItem value="sharma">Sharma & Sons</SelectItem>
                      </SelectContent>
                    </Select>
                    <Button size="icon" variant="outline">
                      <Plus className="h-4 w-4" />
                    </Button>
                  </div>
                </div>

                <div className="space-y-2">
                  <Label>Invoice Date</Label>
                  <Input type="date" defaultValue="2024-10-19" />
                </div>

                <div className="space-y-2">
                  <Label>Payment Mode</Label>
                  <Select defaultValue="cash">
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="cash">Cash</SelectItem>
                      <SelectItem value="card">Card</SelectItem>
                      <SelectItem value="upi">UPI</SelectItem>
                      <SelectItem value="cheque">Cheque</SelectItem>
                      <SelectItem value="credit">Credit</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label>Due Date</Label>
                  <Input type="date" />
                </div>

                <div className="space-y-2">
                  <Label>Reference No.</Label>
                  <Input placeholder="PO/Ref number" />
                </div>
              </div>

              <Separator className="my-6" />

              {/* Items Table */}
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <h3 className="text-gray-900">Invoice Items</h3>
                  <Button onClick={addItem} size="sm" className="gap-2">
                    <Plus className="h-4 w-4" />
                    Add Item (F3)
                  </Button>
                </div>

                <div className="border rounded-lg overflow-x-auto">
                  <Table>
                    <TableHeader>
                      <TableRow className="bg-gray-50">
                        <TableHead className="w-8">#</TableHead>
                        <TableHead className="min-w-[200px]">Item Name</TableHead>
                        <TableHead>HSN/SAC</TableHead>
                        <TableHead>Qty</TableHead>
                        <TableHead>Unit</TableHead>
                        <TableHead>Rate</TableHead>
                        <TableHead>Disc%</TableHead>
                        <TableHead>GST%</TableHead>
                        <TableHead>Amount</TableHead>
                        <TableHead className="w-8"></TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {items.length === 0 ? (
                        <TableRow>
                          <TableCell colSpan={10} className="text-center py-8 text-gray-500">
                            No items added. Click "Add Item" to start.
                          </TableCell>
                        </TableRow>
                      ) : (
                        items.map((item, index) => (
                          <TableRow key={item.id}>
                            <TableCell>{index + 1}</TableCell>
                            <TableCell>
                              <Input 
                                placeholder="Search or enter item name" 
                                className="min-w-[200px]"
                              />
                            </TableCell>
                            <TableCell>
                              <Input placeholder="HSN" className="w-24" />
                            </TableCell>
                            <TableCell>
                              <Input type="number" defaultValue={1} className="w-20" />
                            </TableCell>
                            <TableCell>
                              <Select defaultValue="pcs">
                                <SelectTrigger className="w-20">
                                  <SelectValue />
                                </SelectTrigger>
                                <SelectContent>
                                  <SelectItem value="pcs">PCS</SelectItem>
                                  <SelectItem value="kg">KG</SelectItem>
                                  <SelectItem value="ltr">LTR</SelectItem>
                                  <SelectItem value="box">BOX</SelectItem>
                                </SelectContent>
                              </Select>
                            </TableCell>
                            <TableCell>
                              <Input type="number" placeholder="0.00" className="w-24" />
                            </TableCell>
                            <TableCell>
                              <Input type="number" defaultValue={0} className="w-16" />
                            </TableCell>
                            <TableCell>
                              <Select defaultValue="18">
                                <SelectTrigger className="w-20">
                                  <SelectValue />
                                </SelectTrigger>
                                <SelectContent>
                                  <SelectItem value="0">0%</SelectItem>
                                  <SelectItem value="5">5%</SelectItem>
                                  <SelectItem value="12">12%</SelectItem>
                                  <SelectItem value="18">18%</SelectItem>
                                  <SelectItem value="28">28%</SelectItem>
                                </SelectContent>
                              </Select>
                            </TableCell>
                            <TableCell>
                              <Input value="0.00" disabled className="w-28" />
                            </TableCell>
                            <TableCell>
                              <Button 
                                size="icon" 
                                variant="ghost" 
                                onClick={() => removeItem(item.id)}
                              >
                                <Trash2 className="h-4 w-4 text-red-500" />
                              </Button>
                            </TableCell>
                          </TableRow>
                        ))
                      )}
                    </TableBody>
                  </Table>
                </div>

                {/* Totals Section */}
                <div className="flex justify-end">
                  <div className="w-full max-w-md space-y-3 bg-gray-50 p-4 rounded-lg">
                    <div className="flex justify-between">
                      <span className="text-gray-600">Subtotal:</span>
                      <span className="text-gray-900">₹ {totals.subtotal.toFixed(2)}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600">CGST:</span>
                      <span className="text-gray-900">₹ {(totals.taxTotal / 2).toFixed(2)}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600">SGST:</span>
                      <span className="text-gray-900">₹ {(totals.taxTotal / 2).toFixed(2)}</span>
                    </div>
                    <Separator />
                    <div className="flex justify-between text-lg">
                      <span className="text-gray-900">Grand Total:</span>
                      <span className="text-gray-900">₹ {totals.total.toFixed(2)}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600">Received:</span>
                      <Input type="number" placeholder="0.00" className="w-32 text-right" />
                    </div>
                    <div className="flex justify-between text-lg">
                      <span className="text-gray-900">Balance:</span>
                      <span className="text-red-600">₹ {totals.total.toFixed(2)}</span>
                    </div>
                  </div>
                </div>

                {/* Action Buttons */}
                <div className="flex justify-end gap-2 pt-4">
                  <Button variant="outline" className="gap-2">
                    <X className="h-4 w-4" />
                    Cancel
                  </Button>
                  <Button variant="outline" className="gap-2">
                    <Save className="h-4 w-4" />
                    Save Draft
                  </Button>
                  <Button className="gap-2 bg-green-600 hover:bg-green-700">
                    <Printer className="h-4 w-4" />
                    Save & Print (F5)
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="list" className="space-y-4 mt-4">
          <Card>
            <CardHeader>
              <div className="flex flex-col md:flex-row justify-between gap-4">
                <CardTitle className="text-gray-900">All Invoices</CardTitle>
                <div className="flex gap-2">
                  <div className="relative flex-1 md:w-80">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                    <Input 
                      placeholder="Search invoices..." 
                      className="pl-10"
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                    />
                  </div>
                  <Select defaultValue="all">
                    <SelectTrigger className="w-32">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All</SelectItem>
                      <SelectItem value="sales">Sales</SelectItem>
                      <SelectItem value="purchase">Purchase</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Invoice #</TableHead>
                    <TableHead>Type</TableHead>
                    <TableHead>Party Name</TableHead>
                    <TableHead>Date</TableHead>
                    <TableHead>Amount</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredInvoices.map((invoice) => (
                    <TableRow key={invoice.id}>
                      <TableCell>{invoice.id}</TableCell>
                      <TableCell>
                        <Badge variant={invoice.type === 'Sales' ? 'default' : 'secondary'}>
                          {invoice.type}
                        </Badge>
                      </TableCell>
                      <TableCell>{invoice.customer}</TableCell>
                      <TableCell>{invoice.date}</TableCell>
                      <TableCell>₹ {invoice.amount.toLocaleString()}</TableCell>
                      <TableCell>
                        <Badge 
                          variant={
                            invoice.status === 'Paid' ? 'default' : 
                            invoice.status === 'Pending' ? 'secondary' : 
                            'destructive'
                          }
                        >
                          {invoice.status}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <div className="flex gap-1">
                          <Button size="icon" variant="ghost" title="Print">
                            <Printer className="h-4 w-4" />
                          </Button>
                          <Button size="icon" variant="ghost" title="View">
                            <FileText className="h-4 w-4" />
                          </Button>
                          <Button size="icon" variant="ghost" title="Email">
                            <Mail className="h-4 w-4" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
