import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Textarea } from './ui/textarea';
import { 
  Building2,
  User,
  Lock,
  Bell,
  Printer,
  Database,
  CreditCard,
  Settings as SettingsIcon,
  Save
} from 'lucide-react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './ui/tabs';
import { Switch } from './ui/switch';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Separator } from './ui/separator';

export function Settings() {
  return (
    <div className="p-6 space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl text-gray-900">Settings</h1>
          <p className="text-gray-500">Configure your billing system</p>
        </div>
      </div>

      <Tabs defaultValue="company" className="space-y-4">
        <TabsList className="grid w-full max-w-3xl grid-cols-5">
          <TabsTrigger value="company">Company</TabsTrigger>
          <TabsTrigger value="billing">Billing</TabsTrigger>
          <TabsTrigger value="taxation">Taxation</TabsTrigger>
          <TabsTrigger value="users">Users</TabsTrigger>
          <TabsTrigger value="system">System</TabsTrigger>
        </TabsList>

        {/* Company Settings */}
        <TabsContent value="company">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-gray-900">
                <Building2 className="h-5 w-5" />
                Company Information
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2 col-span-2">
                  <Label>Company Name *</Label>
                  <Input defaultValue="ABC Enterprises" />
                </div>
                <div className="space-y-2 col-span-2">
                  <Label>Address</Label>
                  <Textarea rows={3} defaultValue="123, Main Street, Business District" />
                </div>
                <div className="space-y-2">
                  <Label>City</Label>
                  <Input defaultValue="Mumbai" />
                </div>
                <div className="space-y-2">
                  <Label>State</Label>
                  <Input defaultValue="Maharashtra" />
                </div>
                <div className="space-y-2">
                  <Label>PIN Code</Label>
                  <Input defaultValue="400001" />
                </div>
                <div className="space-y-2">
                  <Label>Country</Label>
                  <Input defaultValue="India" />
                </div>
                <div className="space-y-2">
                  <Label>Phone</Label>
                  <Input defaultValue="+91 22 1234 5678" />
                </div>
                <div className="space-y-2">
                  <Label>Email</Label>
                  <Input type="email" defaultValue="contact@abcenterprises.com" />
                </div>
                <div className="space-y-2">
                  <Label>GSTIN</Label>
                  <Input defaultValue="27AABCU9603R1ZV" />
                </div>
                <div className="space-y-2">
                  <Label>PAN</Label>
                  <Input defaultValue="AABCU9603R" />
                </div>
                <div className="space-y-2">
                  <Label>Financial Year Start</Label>
                  <Select defaultValue="april">
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="april">April</SelectItem>
                      <SelectItem value="january">January</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>Currency</Label>
                  <Select defaultValue="inr">
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="inr">INR - Indian Rupee (₹)</SelectItem>
                      <SelectItem value="usd">USD - US Dollar ($)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
              <Separator />
              <div className="flex justify-end">
                <Button className="gap-2 bg-blue-600 hover:bg-blue-700">
                  <Save className="h-4 w-4" />
                  Save Changes
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Billing Settings */}
        <TabsContent value="billing">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-gray-900">
                <CreditCard className="h-5 w-5" />
                Billing Preferences
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-4">
                <h3 className="text-gray-900">Invoice Settings</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>Invoice Prefix</Label>
                    <Input defaultValue="INV-" />
                  </div>
                  <div className="space-y-2">
                    <Label>Next Invoice Number</Label>
                    <Input type="number" defaultValue="1025" />
                  </div>
                  <div className="space-y-2">
                    <Label>Invoice Terms (Days)</Label>
                    <Input type="number" defaultValue="30" />
                  </div>
                  <div className="space-y-2">
                    <Label>Invoice Footer</Label>
                    <Input placeholder="Thank you for your business" />
                  </div>
                </div>
              </div>

              <Separator />

              <div className="space-y-4">
                <h3 className="text-gray-900">Display Options</h3>
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <Label>Show Company Logo on Invoice</Label>
                      <p className="text-sm text-gray-500">Display logo at top of invoice</p>
                    </div>
                    <Switch defaultChecked />
                  </div>
                  <div className="flex items-center justify-between">
                    <div>
                      <Label>Show HSN/SAC Code</Label>
                      <p className="text-sm text-gray-500">Display HSN code in invoice items</p>
                    </div>
                    <Switch defaultChecked />
                  </div>
                  <div className="flex items-center justify-between">
                    <div>
                      <Label>Show Discount Column</Label>
                      <p className="text-sm text-gray-500">Display discount in separate column</p>
                    </div>
                    <Switch defaultChecked />
                  </div>
                  <div className="flex items-center justify-between">
                    <div>
                      <Label>Auto Print After Save</Label>
                      <p className="text-sm text-gray-500">Automatically print invoice after saving</p>
                    </div>
                    <Switch />
                  </div>
                </div>
              </div>

              <Separator />

              <div className="flex justify-end">
                <Button className="gap-2 bg-blue-600 hover:bg-blue-700">
                  <Save className="h-4 w-4" />
                  Save Changes
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Taxation Settings */}
        <TabsContent value="taxation">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-gray-900">
                <SettingsIcon className="h-5 w-5" />
                Tax Configuration
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-4">
                <h3 className="text-gray-900">GST Settings</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>Tax Type</Label>
                    <Select defaultValue="gst">
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="gst">GST (India)</SelectItem>
                        <SelectItem value="vat">VAT</SelectItem>
                        <SelectItem value="none">No Tax</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label>Default Tax Rate</Label>
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
                </div>

                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <Label>Enable Reverse Charge</Label>
                      <p className="text-sm text-gray-500">For specific transactions</p>
                    </div>
                    <Switch />
                  </div>
                  <div className="flex items-center justify-between">
                    <div>
                      <Label>Composition Scheme</Label>
                      <p className="text-sm text-gray-500">Simplified tax scheme</p>
                    </div>
                    <Switch />
                  </div>
                  <div className="flex items-center justify-between">
                    <div>
                      <Label>Include Tax in Product Price</Label>
                      <p className="text-sm text-gray-500">Tax inclusive pricing</p>
                    </div>
                    <Switch />
                  </div>
                </div>
              </div>

              <Separator />

              <div className="space-y-4">
                <h3 className="text-gray-900">TDS/TCS Settings</h3>
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <Label>Enable TDS</Label>
                      <p className="text-sm text-gray-500">Tax Deducted at Source</p>
                    </div>
                    <Switch />
                  </div>
                  <div className="flex items-center justify-between">
                    <div>
                      <Label>Enable TCS</Label>
                      <p className="text-sm text-gray-500">Tax Collected at Source</p>
                    </div>
                    <Switch />
                  </div>
                </div>
              </div>

              <Separator />

              <div className="flex justify-end">
                <Button className="gap-2 bg-blue-600 hover:bg-blue-700">
                  <Save className="h-4 w-4" />
                  Save Changes
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* User Management */}
        <TabsContent value="users">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-gray-900">
                <User className="h-5 w-5" />
                User Management
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex justify-end">
                <Button className="gap-2">
                  <User className="h-4 w-4" />
                  Add New User
                </Button>
              </div>
              <div className="border rounded-lg p-4 space-y-4">
                <div className="flex items-center justify-between">
                  <div>
                    <h4 className="text-gray-900">Admin User</h4>
                    <p className="text-sm text-gray-500">admin@abcenterprises.com</p>
                  </div>
                  <div className="flex gap-2">
                    <Button variant="outline" size="sm">Edit</Button>
                    <Button variant="outline" size="sm">
                      <Lock className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
                <Separator />
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div>
                    <Label className="text-xs">Create Invoice</Label>
                    <p className="text-sm">✓ Allowed</p>
                  </div>
                  <div>
                    <Label className="text-xs">Edit Invoice</Label>
                    <p className="text-sm">✓ Allowed</p>
                  </div>
                  <div>
                    <Label className="text-xs">Delete Invoice</Label>
                    <p className="text-sm">✓ Allowed</p>
                  </div>
                  <div>
                    <Label className="text-xs">View Reports</Label>
                    <p className="text-sm">✓ Allowed</p>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* System Settings */}
        <TabsContent value="system">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-gray-900">
                <Database className="h-5 w-5" />
                System Configuration
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-4">
                <h3 className="text-gray-900">Backup & Restore</h3>
                <div className="flex gap-4">
                  <Button variant="outline" className="gap-2">
                    <Database className="h-4 w-4" />
                    Backup Now
                  </Button>
                  <Button variant="outline" className="gap-2">
                    <Database className="h-4 w-4" />
                    Restore Backup
                  </Button>
                </div>
                <div className="flex items-center justify-between">
                  <div>
                    <Label>Auto Backup</Label>
                    <p className="text-sm text-gray-500">Daily automatic backup at 2:00 AM</p>
                  </div>
                  <Switch defaultChecked />
                </div>
              </div>

              <Separator />

              <div className="space-y-4">
                <h3 className="text-gray-900">Printer Settings</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>Default Printer</Label>
                    <Select defaultValue="thermal">
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="thermal">Thermal Printer</SelectItem>
                        <SelectItem value="laser">Laser Printer</SelectItem>
                        <SelectItem value="inkjet">Inkjet Printer</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label>Paper Size</Label>
                    <Select defaultValue="a4">
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="a4">A4</SelectItem>
                        <SelectItem value="a5">A5</SelectItem>
                        <SelectItem value="thermal">Thermal (3 inch)</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>
              </div>

              <Separator />

              <div className="space-y-4">
                <h3 className="text-gray-900">Notifications</h3>
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <Label>Low Stock Alerts</Label>
                      <p className="text-sm text-gray-500">Get notified when stock is low</p>
                    </div>
                    <Switch defaultChecked />
                  </div>
                  <div className="flex items-center justify-between">
                    <div>
                      <Label>Payment Reminders</Label>
                      <p className="text-sm text-gray-500">Send payment reminders to customers</p>
                    </div>
                    <Switch defaultChecked />
                  </div>
                  <div className="flex items-center justify-between">
                    <div>
                      <Label>Email Notifications</Label>
                      <p className="text-sm text-gray-500">Receive notifications via email</p>
                    </div>
                    <Switch />
                  </div>
                </div>
              </div>

              <Separator />

              <div className="flex justify-end">
                <Button className="gap-2 bg-blue-600 hover:bg-blue-700">
                  <Save className="h-4 w-4" />
                  Save Changes
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
