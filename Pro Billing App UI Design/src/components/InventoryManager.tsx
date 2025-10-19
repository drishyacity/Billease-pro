import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { 
  Plus, 
  Search, 
  Package,
  Edit,
  Trash2,
  Upload,
  Download,
  Barcode,
  AlertTriangle,
  TrendingUp,
  TrendingDown
} from 'lucide-react';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from './ui/table';
import { Badge } from './ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './ui/tabs';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from './ui/dialog';

const products = [
  { 
    id: 'P001', 
    name: 'Samsung LED TV 43"', 
    category: 'Electronics', 
    hsn: '8528', 
    stock: 3, 
    unit: 'PCS',
    purchasePrice: 25000, 
    salePrice: 32000, 
    reorderLevel: 10,
    gst: 18,
    status: 'Low Stock'
  },
  { 
    id: 'P002', 
    name: 'Cotton Shirt (Blue)', 
    category: 'Clothing', 
    hsn: '6205', 
    stock: 5, 
    unit: 'PCS',
    purchasePrice: 300, 
    salePrice: 450, 
    reorderLevel: 20,
    gst: 12,
    status: 'Low Stock'
  },
  { 
    id: 'P003', 
    name: 'Rice (25kg)', 
    category: 'Groceries', 
    hsn: '1006', 
    stock: 8, 
    unit: 'BAG',
    purchasePrice: 1200, 
    salePrice: 1500, 
    reorderLevel: 50,
    gst: 5,
    status: 'Low Stock'
  },
  { 
    id: 'P004', 
    name: 'Sony Headphones', 
    category: 'Electronics', 
    hsn: '8518', 
    stock: 45, 
    unit: 'PCS',
    purchasePrice: 2500, 
    salePrice: 3200, 
    reorderLevel: 15,
    gst: 18,
    status: 'In Stock'
  },
  { 
    id: 'P005', 
    name: 'Notebook A4', 
    category: 'Stationery', 
    hsn: '4820', 
    stock: 120, 
    unit: 'PCS',
    purchasePrice: 40, 
    salePrice: 60, 
    reorderLevel: 50,
    gst: 12,
    status: 'In Stock'
  },
];

const categories = ['All', 'Electronics', 'Clothing', 'Groceries', 'Stationery'];

export function InventoryManager() {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);

  const filteredProducts = products.filter(product => {
    const matchesSearch = product.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         product.id.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCategory = selectedCategory === 'All' || product.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  const totalStockValue = products.reduce((sum, p) => sum + (p.stock * p.purchasePrice), 0);
  const lowStockCount = products.filter(p => p.stock <= p.reorderLevel).length;

  return (
    <div className="p-6 space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl text-gray-900">Inventory Management</h1>
          <p className="text-gray-500">Manage products, stock levels, and pricing</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" className="gap-2">
            <Download className="h-4 w-4" />
            Export
          </Button>
          <Button variant="outline" className="gap-2">
            <Upload className="h-4 w-4" />
            Import
          </Button>
          <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
            <DialogTrigger asChild>
              <Button className="gap-2 bg-blue-600 hover:bg-blue-700">
                <Plus className="h-4 w-4" />
                Add Product
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-2xl">
              <DialogHeader>
                <DialogTitle>Add New Product</DialogTitle>
              </DialogHeader>
              <div className="grid grid-cols-2 gap-4 py-4">
                <div className="space-y-2">
                  <Label>Product Name *</Label>
                  <Input placeholder="Enter product name" />
                </div>
                <div className="space-y-2">
                  <Label>Product Code/SKU</Label>
                  <Input placeholder="Auto-generated" />
                </div>
                <div className="space-y-2">
                  <Label>Category *</Label>
                  <Select>
                    <SelectTrigger>
                      <SelectValue placeholder="Select category" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="electronics">Electronics</SelectItem>
                      <SelectItem value="clothing">Clothing</SelectItem>
                      <SelectItem value="groceries">Groceries</SelectItem>
                      <SelectItem value="stationery">Stationery</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>HSN/SAC Code</Label>
                  <Input placeholder="Enter HSN code" />
                </div>
                <div className="space-y-2">
                  <Label>Unit *</Label>
                  <Select defaultValue="pcs">
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="pcs">PCS</SelectItem>
                      <SelectItem value="kg">KG</SelectItem>
                      <SelectItem value="ltr">LTR</SelectItem>
                      <SelectItem value="box">BOX</SelectItem>
                      <SelectItem value="bag">BAG</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>Opening Stock</Label>
                  <Input type="number" defaultValue={0} />
                </div>
                <div className="space-y-2">
                  <Label>Purchase Price *</Label>
                  <Input type="number" placeholder="0.00" />
                </div>
                <div className="space-y-2">
                  <Label>Sale Price *</Label>
                  <Input type="number" placeholder="0.00" />
                </div>
                <div className="space-y-2">
                  <Label>GST Rate *</Label>
                  <Select defaultValue="18">
                    <SelectTrigger>
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
                </div>
                <div className="space-y-2">
                  <Label>Reorder Level</Label>
                  <Input type="number" defaultValue={10} />
                </div>
                <div className="space-y-2 col-span-2">
                  <Label>Barcode</Label>
                  <div className="flex gap-2">
                    <Input placeholder="Enter or scan barcode" />
                    <Button variant="outline" size="icon">
                      <Barcode className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              </div>
              <div className="flex justify-end gap-2">
                <Button variant="outline" onClick={() => setIsAddDialogOpen(false)}>
                  Cancel
                </Button>
                <Button className="bg-blue-600 hover:bg-blue-700">
                  Save Product
                </Button>
              </div>
            </DialogContent>
          </Dialog>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card className="border-l-4 border-l-blue-500">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-gray-600">Total Products</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl text-gray-900">{products.length}</div>
            <p className="text-xs text-gray-500 mt-1">{categories.length - 1} categories</p>
          </CardContent>
        </Card>

        <Card className="border-l-4 border-l-green-500">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-gray-600">Stock Value</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl text-gray-900">₹ {totalStockValue.toLocaleString()}</div>
            <p className="text-xs text-green-600 mt-1 flex items-center gap-1">
              <TrendingUp className="h-3 w-3" />
              At purchase price
            </p>
          </CardContent>
        </Card>

        <Card className="border-l-4 border-l-orange-500">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-gray-600">Low Stock Items</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl text-gray-900">{lowStockCount}</div>
            <p className="text-xs text-orange-600 mt-1 flex items-center gap-1">
              <AlertTriangle className="h-3 w-3" />
              Needs reorder
            </p>
          </CardContent>
        </Card>

        <Card className="border-l-4 border-l-purple-500">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-gray-600">Potential Profit</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl text-gray-900">
              ₹ {products.reduce((sum, p) => sum + (p.stock * (p.salePrice - p.purchasePrice)), 0).toLocaleString()}
            </div>
            <p className="text-xs text-purple-600 mt-1">On current stock</p>
          </CardContent>
        </Card>
      </div>

      {/* Main Table */}
      <Card>
        <CardHeader>
          <div className="flex flex-col md:flex-row justify-between gap-4">
            <div className="flex gap-2">
              <div className="relative flex-1 md:w-80">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                <Input 
                  placeholder="Search products..." 
                  className="pl-10"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
              </div>
              <Select value={selectedCategory} onValueChange={setSelectedCategory}>
                <SelectTrigger className="w-40">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {categories.map(cat => (
                    <SelectItem key={cat} value={cat}>{cat}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="flex gap-2">
              <Button variant="outline" size="sm">
                Stock In
              </Button>
              <Button variant="outline" size="sm">
                Stock Out
              </Button>
              <Button variant="outline" size="sm">
                Stock Adjustment
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Code</TableHead>
                <TableHead>Product Name</TableHead>
                <TableHead>Category</TableHead>
                <TableHead>HSN</TableHead>
                <TableHead>Stock</TableHead>
                <TableHead>Unit</TableHead>
                <TableHead>Purchase Price</TableHead>
                <TableHead>Sale Price</TableHead>
                <TableHead>GST%</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredProducts.map((product) => (
                <TableRow key={product.id}>
                  <TableCell>{product.id}</TableCell>
                  <TableCell className="text-gray-900">{product.name}</TableCell>
                  <TableCell>{product.category}</TableCell>
                  <TableCell>{product.hsn}</TableCell>
                  <TableCell>
                    <Badge variant={product.stock <= product.reorderLevel ? 'destructive' : 'secondary'}>
                      {product.stock}
                    </Badge>
                  </TableCell>
                  <TableCell>{product.unit}</TableCell>
                  <TableCell>₹ {product.purchasePrice.toLocaleString()}</TableCell>
                  <TableCell>₹ {product.salePrice.toLocaleString()}</TableCell>
                  <TableCell>{product.gst}%</TableCell>
                  <TableCell>
                    <Badge variant={product.status === 'In Stock' ? 'default' : 'destructive'}>
                      {product.status}
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
