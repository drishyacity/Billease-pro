import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { 
  FileText, 
  Download, 
  Printer,
  Calendar,
  TrendingUp,
  Package,
  Users,
  DollarSign,
  BarChart3,
  PieChart
} from 'lucide-react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './ui/tabs';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from './ui/table';
import {
  BarChart,
  Bar,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer
} from 'recharts';

const salesReportData = [
  { date: '2024-10-13', sales: 23400, purchases: 15000, profit: 8400 },
  { date: '2024-10-14', sales: 34500, purchases: 22000, profit: 12500 },
  { date: '2024-10-15', sales: 45600, purchases: 28000, profit: 17600 },
  { date: '2024-10-16', sales: 28900, purchases: 18000, profit: 10900 },
  { date: '2024-10-17', sales: 56700, purchases: 35000, profit: 21700 },
  { date: '2024-10-18', sales: 67800, purchases: 42000, profit: 25800 },
  { date: '2024-10-19', sales: 45600, purchases: 28000, profit: 17600 },
];

const gstReportData = [
  { invoice: 'INV-1024', party: 'Raj Electronics', taxable: 38644, cgst: 3481, sgst: 3481, igst: 0, total: 45606 },
  { invoice: 'INV-1023', party: 'Modern Traders', taxable: 19830, cgst: 1786, sgst: 1786, igst: 0, total: 23402 },
  { invoice: 'INV-1022', party: 'City Mart', taxable: 57458, cgst: 5171, sgst: 5171, igst: 0, total: 67800 },
];

const stockReportData = [
  { category: 'Electronics', items: 45, value: 678900, percentage: 45 },
  { category: 'Clothing', items: 234, value: 345600, percentage: 23 },
  { category: 'Groceries', items: 456, value: 234500, percentage: 15 },
  { category: 'Stationery', items: 512, value: 256700, percentage: 17 },
];

const reportTypes = [
  { id: 'sales', name: 'Sales Report', icon: TrendingUp, description: 'Daily/Monthly sales summary' },
  { id: 'purchase', name: 'Purchase Report', icon: Package, description: 'Purchase analysis' },
  { id: 'gst', name: 'GST Report', icon: FileText, description: 'GSTR-1, GSTR-3B reports' },
  { id: 'profit', name: 'Profit & Loss', icon: DollarSign, description: 'P&L statement' },
  { id: 'stock', name: 'Stock Report', icon: Package, description: 'Current stock status' },
  { id: 'party', name: 'Party Statement', icon: Users, description: 'Customer/Supplier ledger' },
];

export function Reports() {
  const [selectedReport, setSelectedReport] = useState('sales');
  const [dateFrom, setDateFrom] = useState('2024-10-13');
  const [dateTo, setDateTo] = useState('2024-10-19');

  return (
    <div className="p-6 space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl text-gray-900">Reports & Analytics</h1>
          <p className="text-gray-500">Generate detailed business reports</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" className="gap-2">
            <Printer className="h-4 w-4" />
            Print
          </Button>
          <Button className="gap-2 bg-blue-600 hover:bg-blue-700">
            <Download className="h-4 w-4" />
            Export to Excel
          </Button>
        </div>
      </div>

      {/* Report Type Selection */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        {reportTypes.map((report) => {
          const Icon = report.icon;
          return (
            <Card
              key={report.id}
              className={`cursor-pointer transition-all hover:shadow-lg ${
                selectedReport === report.id ? 'ring-2 ring-blue-500 bg-blue-50' : ''
              }`}
              onClick={() => setSelectedReport(report.id)}
            >
              <CardContent className="pt-6 text-center">
                <Icon className={`h-8 w-8 mx-auto mb-2 ${
                  selectedReport === report.id ? 'text-blue-600' : 'text-gray-600'
                }`} />
                <h3 className="text-sm text-gray-900">{report.name}</h3>
                <p className="text-xs text-gray-500 mt-1">{report.description}</p>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Date Range Filter */}
      <Card>
        <CardHeader>
          <CardTitle className="text-gray-900">Filter Parameters</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div className="space-y-2">
              <Label>From Date</Label>
              <Input 
                type="date" 
                value={dateFrom} 
                onChange={(e) => setDateFrom(e.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label>To Date</Label>
              <Input 
                type="date" 
                value={dateTo} 
                onChange={(e) => setDateTo(e.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label>Party Type</Label>
              <Select defaultValue="all">
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All</SelectItem>
                  <SelectItem value="customer">Customer</SelectItem>
                  <SelectItem value="supplier">Supplier</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>&nbsp;</Label>
              <Button className="w-full bg-blue-600 hover:bg-blue-700">
                Generate Report
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Sales Report */}
      {selectedReport === 'sales' && (
        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-gray-900">Sales Trend (Last 7 Days)</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={400}>
                <LineChart data={salesReportData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Line type="monotone" dataKey="sales" stroke="#3b82f6" strokeWidth={2} name="Sales" />
                  <Line type="monotone" dataKey="purchases" stroke="#10b981" strokeWidth={2} name="Purchases" />
                  <Line type="monotone" dataKey="profit" stroke="#f59e0b" strokeWidth={2} name="Profit" />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-gray-900">Daily Sales Summary</CardTitle>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Date</TableHead>
                    <TableHead>Total Sales</TableHead>
                    <TableHead>Total Purchases</TableHead>
                    <TableHead>Gross Profit</TableHead>
                    <TableHead>Margin %</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {salesReportData.map((row, index) => (
                    <TableRow key={index}>
                      <TableCell>{row.date}</TableCell>
                      <TableCell>₹ {row.sales.toLocaleString()}</TableCell>
                      <TableCell>₹ {row.purchases.toLocaleString()}</TableCell>
                      <TableCell className="text-green-600">₹ {row.profit.toLocaleString()}</TableCell>
                      <TableCell>{((row.profit / row.sales) * 100).toFixed(2)}%</TableCell>
                    </TableRow>
                  ))}
                  <TableRow className="bg-gray-50">
                    <TableCell>Total</TableCell>
                    <TableCell>₹ {salesReportData.reduce((sum, r) => sum + r.sales, 0).toLocaleString()}</TableCell>
                    <TableCell>₹ {salesReportData.reduce((sum, r) => sum + r.purchases, 0).toLocaleString()}</TableCell>
                    <TableCell className="text-green-600">₹ {salesReportData.reduce((sum, r) => sum + r.profit, 0).toLocaleString()}</TableCell>
                    <TableCell>
                      {((salesReportData.reduce((sum, r) => sum + r.profit, 0) / salesReportData.reduce((sum, r) => sum + r.sales, 0)) * 100).toFixed(2)}%
                    </TableCell>
                  </TableRow>
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </div>
      )}

      {/* GST Report */}
      {selectedReport === 'gst' && (
        <Card>
          <CardHeader>
            <CardTitle className="text-gray-900">GST Summary Report (GSTR-1)</CardTitle>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Invoice No.</TableHead>
                  <TableHead>Party Name</TableHead>
                  <TableHead>Taxable Amount</TableHead>
                  <TableHead>CGST</TableHead>
                  <TableHead>SGST</TableHead>
                  <TableHead>IGST</TableHead>
                  <TableHead>Total Amount</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {gstReportData.map((row, index) => (
                  <TableRow key={index}>
                    <TableCell>{row.invoice}</TableCell>
                    <TableCell>{row.party}</TableCell>
                    <TableCell>₹ {row.taxable.toLocaleString()}</TableCell>
                    <TableCell>₹ {row.cgst.toLocaleString()}</TableCell>
                    <TableCell>₹ {row.sgst.toLocaleString()}</TableCell>
                    <TableCell>₹ {row.igst.toLocaleString()}</TableCell>
                    <TableCell>₹ {row.total.toLocaleString()}</TableCell>
                  </TableRow>
                ))}
                <TableRow className="bg-gray-50">
                  <TableCell colSpan={2}>Total</TableCell>
                  <TableCell>₹ {gstReportData.reduce((sum, r) => sum + r.taxable, 0).toLocaleString()}</TableCell>
                  <TableCell>₹ {gstReportData.reduce((sum, r) => sum + r.cgst, 0).toLocaleString()}</TableCell>
                  <TableCell>₹ {gstReportData.reduce((sum, r) => sum + r.sgst, 0).toLocaleString()}</TableCell>
                  <TableCell>₹ {gstReportData.reduce((sum, r) => sum + r.igst, 0).toLocaleString()}</TableCell>
                  <TableCell>₹ {gstReportData.reduce((sum, r) => sum + r.total, 0).toLocaleString()}</TableCell>
                </TableRow>
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      )}

      {/* Stock Report */}
      {selectedReport === 'stock' && (
        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-gray-900">Stock Value by Category</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={400}>
                <BarChart data={stockReportData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="category" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="value" fill="#3b82f6" name="Stock Value (₹)" />
                  <Bar dataKey="items" fill="#10b981" name="Number of Items" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-gray-900">Category-wise Stock Details</CardTitle>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Category</TableHead>
                    <TableHead>Total Items</TableHead>
                    <TableHead>Stock Value</TableHead>
                    <TableHead>Percentage</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {stockReportData.map((row, index) => (
                    <TableRow key={index}>
                      <TableCell className="text-gray-900">{row.category}</TableCell>
                      <TableCell>{row.items}</TableCell>
                      <TableCell>₹ {row.value.toLocaleString()}</TableCell>
                      <TableCell>{row.percentage}%</TableCell>
                    </TableRow>
                  ))}
                  <TableRow className="bg-gray-50">
                    <TableCell>Total</TableCell>
                    <TableCell>{stockReportData.reduce((sum, r) => sum + r.items, 0)}</TableCell>
                    <TableCell>₹ {stockReportData.reduce((sum, r) => sum + r.value, 0).toLocaleString()}</TableCell>
                    <TableCell>100%</TableCell>
                  </TableRow>
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Placeholder for other reports */}
      {!['sales', 'gst', 'stock'].includes(selectedReport) && (
        <Card>
          <CardContent className="py-12 text-center">
            <FileText className="h-16 w-16 mx-auto text-gray-400 mb-4" />
            <h3 className="text-xl text-gray-900 mb-2">Report Coming Soon</h3>
            <p className="text-gray-500">
              This report type is currently being developed. Please check back later.
            </p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
