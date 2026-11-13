import React, { useEffect, useMemo, useState } from "react";
import {
  Activity, AlertTriangle, ArrowDownRight, ArrowUpRight, Bell, Boxes, CloudOff,
  Calculator, CalendarDays, Check, CheckCircle2, ChevronDown, CircleDollarSign,
  ClipboardList, Clock3, Download, FileText, Filter, Gauge, LayoutDashboard,
  MapPin, Menu, Package, Plus, Printer, ReceiptText, Search, Settings,
  Truck, Users, Wallet, X, Zap
} from "lucide-react";
import {
  Area, AreaChart, Bar, BarChart, CartesianGrid, ResponsiveContainer,
  Tooltip, XAxis, YAxis
} from "recharts";

const initialPrinters = [
  { id: "PB-FDM-001", name: "Bambu Lab P1S", technology: "FDM", location: "Main Workshop", watts: 350, hours: 428, status: "Running" },
  { id: "PB-FDM-002", name: "Creality K1 Max", technology: "FDM", location: "Main Workshop", watts: 600, hours: 286, status: "Idle" },
  { id: "PB-RES-001", name: "Elegoo Saturn 3", technology: "Resin", location: "Resin Lab", watts: 120, hours: 164, status: "Running" }
];
const initialMaterials = [
  { id: "MAT-001", name: "PLA Matte Black", type: "PLA", colour: "Black", stock: 3.2, rate: 850, min: 1 },
  { id: "MAT-002", name: "PLA Silk Gold", type: "PLA", colour: "Gold", stock: 1.5, rate: 1100, min: 2 },
  { id: "MAT-003", name: "PETG White", type: "PETG", colour: "White", stock: 4.0, rate: 950, min: 1 },
  { id: "MAT-004", name: "Standard Resin Grey", type: "Resin", colour: "Grey", stock: 2.4, rate: 1450, min: 1 }
];
const initialOrders = [
  { id: "PB-ORD-1048", customer: "Aarav Designs", product: "Custom Ganesha lamp", amount: 12400, status: "Printing", due: "06 Nov 2026", location: "Main Workshop" },
  { id: "PB-ORD-1047", customer: "Mehta Gifts", product: "Corporate award set", amount: 18600, status: "Post-processing", due: "07 Nov 2026", location: "Main Workshop" },
  { id: "PB-ORD-1046", customer: "Studio Form", product: "Architectural scale model", amount: 9200, status: "Quality check", due: "08 Nov 2026", location: "Resin Lab" },
  { id: "PB-ORD-1045", customer: "Nexa Retail", product: "Display prototypes", amount: 7400, status: "Delivered", due: "04 Nov 2026", location: "Main Workshop" }
];
const initialCustomers = [
  { id: "CUS-001", name: "Aarav Designs", type: "Business", phone: "+91 98765 43210", city: "Surat", orders: 8, outstanding: 4200 },
  { id: "CUS-002", name: "Mehta Gifts", type: "Reseller", phone: "+91 98250 12345", city: "Ahmedabad", orders: 14, outstanding: 0 },
  { id: "CUS-003", name: "Studio Form", type: "Business", phone: "+91 98980 56789", city: "Vadodara", orders: 5, outstanding: 1800 }
];
const revenueData = [
  { month: "Jun", revenue: 42, profit: 13 }, { month: "Jul", revenue: 51, profit: 18 },
  { month: "Aug", revenue: 47, profit: 16 }, { month: "Sep", revenue: 63, profit: 23 },
  { month: "Oct", revenue: 72, profit: 27 }, { month: "Nov", revenue: 84, profit: 32 }
];
const money = value => new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR", maximumFractionDigits: 0 }).format(Number(value || 0));
const orderStatuses = ["New enquiry", "Quotation", "Confirmed", "Printing", "Post-processing", "Quality check", "Packaging", "Shipped", "Delivered", "Cancelled"];
const formatDate = value => {
  if (!value) return "Not set";
  const date = /^\d{4}-\d{2}-\d{2}$/.test(String(value)) ? new Date(value + "T00:00:00") : new Date(value);
  return Number.isNaN(date.getTime()) ? value : new Intl.DateTimeFormat("en-IN", { day: "2-digit", month: "short", year: "numeric" }).format(date);
};
const downloadCsv = (filename, rows) => {
  if (!rows || !rows.length) return false;
  const headers = Object.keys(rows[0]);
  const cell = value => '"' + String(value == null ? "" : value).replace(/"/g, '""') + '"';
  const csv = [headers.map(cell).join(","), ...rows.map(row => headers.map(key => cell(row[key])).join(","))].join("\r\n");
  const blob = new Blob(["\uFEFF" + csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url; link.download = filename; link.click();
  URL.revokeObjectURL(url);
  return true;
};

const readLocal = (key, fallback) => {
  try { const value = localStorage.getItem(key); return value ? JSON.parse(value) : fallback; }
  catch { return fallback; }
};
const saveLocal = (key, value) => localStorage.setItem(key, JSON.stringify(value));

const nav = [
  { label: "WORKSPACE", items: [["Dashboard", LayoutDashboard], ["Orders", ClipboardList], ["Customers", Users]] },
  { label: "OPERATIONS", items: [["Printers", Printer], ["Materials", Boxes], ["Costing", Calculator]] },
  { label: "BUSINESS", items: [["Invoices", ReceiptText], ["Reports", Activity]] },
  { label: "SYSTEM", items: [["Settings", Settings]] }
];

function Status({ value }) {
  const kind = ["Running", "Delivered", "Paid"].includes(value) ? "green" :
    ["Idle", "Printing"].includes(value) ? "blue" :
    ["Low stock", "Maintenance"].includes(value) ? "amber" : "purple";
  return <span className={"status " + kind}><i />{value}</span>;
}
function Modal({ title, onClose, children }) {
  return <div className="overlay" onMouseDown={onClose}><section className="modal" onMouseDown={event => event.stopPropagation()}>
    <header className="modal-head"><h2>{title}</h2><button className="icon-btn" onClick={onClose} aria-label="Close"><X size={18} /></button></header>
    {children}
  </section></div>;
}
function Field({ label, children }) { return <label className="field"><span>{label}</span>{children}</label>; }

export default function App() {
  const [page, setPage] = useState("Dashboard");
  const [mobileNav, setMobileNav] = useState(false);
  const [search, setSearch] = useState("");
  const [location, setLocation] = useState("All locations");
  const [printers, setPrinters] = useState(() => readLocal("pb_printers", initialPrinters));
  const [materials, setMaterials] = useState(() => readLocal("pb_materials", initialMaterials));
  const [orders, setOrders] = useState(() => readLocal("pb_orders", initialOrders));
  const [orderFilter, setOrderFilter] = useState("All");
  const [estimates, setEstimates] = useState(() => readLocal("pb_estimates", []));
  const [stockForm, setStockForm] = useState({ materialId: "", quantity: 0, rate: 0 });
  const [customers, setCustomers] = useState(() => readLocal("pb_customers", initialCustomers));
  const [modal, setModal] = useState("");
  const [editing, setEditing] = useState(null);
  const [toast, setToast] = useState("");
  const [billingMode, setBillingMode] = useState("GST");
  const [settings, setSettings] = useState(() => readLocal("pb_settings", { company: "Print_Bud", electricity: 9.5, markup: 35, gst: 18 }));
  const [printerForm, setPrinterForm] = useState({});
  const [materialForm, setMaterialForm] = useState({});
  const [customerForm, setCustomerForm] = useState({});
  const [orderForm, setOrderForm] = useState({ customer: "", product: "", amount: "", status: "New enquiry", due: "", location: "Main Workshop" });
  const [cost, setCost] = useState(() => readLocal("pb_cost", { grams: 120, rate: 850, hours: 8, watts: 350, electricity: 9.5, machine: 12, painting: 120, labour: 100, packaging: 40, shipping: 80, other: 20, markup: 35 }));

  useEffect(() => saveLocal("pb_settings", settings), [settings]);
  useEffect(() => saveLocal("pb_cost", cost), [cost]);
  useEffect(() => saveLocal("pb_estimates", estimates), [estimates]);

  const notify = message => { setToast(message); window.setTimeout(() => setToast(""), 2400); };
  const setPrintersAndSave = value => { setPrinters(value); saveLocal("pb_printers", value); };
  const setMaterialsAndSave = value => { setMaterials(value); saveLocal("pb_materials", value); };
  const setOrdersAndSave = value => { setOrders(value); saveLocal("pb_orders", value); };
  const setCustomersAndSave = value => { setCustomers(value); saveLocal("pb_customers", value); };

  const filtered = list => list.filter(item => JSON.stringify(item).toLowerCase().includes(search.toLowerCase()));
  const orderValue = orders.reduce((sum, order) => sum + Number(order.amount || 0), 0);
  const activeOrders = orders.filter(order => !["Delivered", "Cancelled"].includes(order.status));
  const lowStockItems = materials.filter(material => Number(material.stock) <= Number(material.min));
  const orderStatusData = orderStatuses.filter(status => orders.some(order => order.status === status)).map(status => ({
    status: status.length > 12 ? status.slice(0, 12) + "…" : status,
    value: orders.filter(order => order.status === status).reduce((sum, order) => sum + Number(order.amount || 0), 0)
  }));
  const orderRows = filtered(orders).filter(order => orderFilter === "All" || order.status === orderFilter);
  const costParts = useMemo(() => ({
    material: Number(cost.grams) * Number(cost.rate) / 1000,
    electricity: Number(cost.hours) * Number(cost.watts) / 1000 * Number(cost.electricity),
    machine: Number(cost.hours) * Number(cost.machine),
    finishing: ["painting", "labour", "packaging", "shipping", "other"].reduce((sum, key) => sum + Number(cost[key] || 0), 0)
  }), [cost]);
  const totalCost = costParts.material + costParts.electricity + costParts.machine + costParts.finishing;
  const quotePrice = totalCost * (1 + Number(cost.markup) / 100);
  const profit = quotePrice - totalCost;
  const saveEstimate = () => {
    const record = { id: "EST-" + Date.now(), createdAt: new Date().toISOString(), totalCost: Number(totalCost.toFixed(2)), sellingPrice: Number(quotePrice.toFixed(2)), profit: Number(profit.toFixed(2)), inputs: { ...cost } };
    setEstimates([record, ...estimates].slice(0, 25));
    notify("Cost estimate saved");
  };
  const updateOrderStatus = (id, status) => {
    setOrdersAndSave(orders.map(order => order.id === id ? { ...order, status } : order));
    notify("Order status updated");
  };
  const exportOrders = () => notify(downloadCsv("printbud-orders.csv", orders.map(({ id, customer, product, amount, status, due, location }) => ({ id, customer, product, amount, status, due, location }))) ? "Orders CSV exported" : "No orders to export");
  const exportCustomers = () => notify(downloadCsv("printbud-customers.csv", customers.map(({ id, name, type, phone, city, orders: count, outstanding }) => ({ id, name, type, phone, city, orders: count, outstanding }))) ? "Customers CSV exported" : "No customers to export");
  const exportMaterials = () => notify(downloadCsv("printbud-inventory.csv", materials.map(({ id, name, type, colour, stock, rate, min }) => ({ id, name, type, colour, stock_kg: stock, rate_per_kg: rate, minimum_kg: min, stock_value: Number(stock) * Number(rate) }))) ? "Inventory CSV exported" : "No materials to export");
  const openStock = () => {
    const first = materials[0];
    setStockForm({ materialId: first?.id || "", quantity: 0, rate: Number(first?.rate || 0) });
    setModal("stock");
  };
  const saveStockReceipt = event => {
    event.preventDefault();
    const quantity = Number(stockForm.quantity);
    if (!stockForm.materialId || quantity <= 0) { notify("Enter a material and a quantity above zero"); return; }
    setMaterialsAndSave(materials.map(item => item.id === stockForm.materialId
      ? { ...item, stock: Number(item.stock || 0) + quantity, rate: Number(stockForm.rate || item.rate) }
      : item));
    setModal("");
    notify("Stock receipt recorded");
  };

  const openPrinter = printer => {
    setEditing(printer || null);
    setPrinterForm(printer ? { ...printer } : { name: "", technology: "FDM", location: "Main Workshop", watts: 350, hours: 0, status: "Idle" });
    setModal("printer");
  };
  const savePrinter = event => {
    event.preventDefault();
    const record = { ...printerForm, id: printerForm.id || "PB-" + (printerForm.technology === "FDM" ? "FDM" : "RES") + "-" + String(printers.length + 1).padStart(3, "0") };
    setPrintersAndSave(editing ? printers.map(item => item.id === editing.id ? record : item) : [...printers, record]);
    setModal(""); notify("Printer saved");
  };
  const openMaterial = material => {
    setEditing(material || null);
    setMaterialForm(material ? { ...material } : { name: "", type: "PLA", colour: "", stock: 0, rate: 0, min: 1 });
    setModal("material");
  };
  const saveMaterial = event => {
    event.preventDefault();
    const record = { ...materialForm, id: materialForm.id || "MAT-" + String(materials.length + 1).padStart(3, "0") };
    setMaterialsAndSave(editing ? materials.map(item => item.id === editing.id ? record : item) : [...materials, record]);
    setModal(""); notify("Material saved");
  };
  const saveCustomer = event => {
    event.preventDefault();
    const record = { ...customerForm, id: customerForm.id || "CUS-" + String(customers.length + 1).padStart(3, "0") };
    setCustomersAndSave(editing ? customers.map(item => item.id === editing.id ? record : item) : [...customers, record]);
    setModal(""); notify("Customer saved");
  };
  const saveOrder = event => {
    event.preventDefault();
    const record = { ...orderForm, id: "PB-ORD-" + String(1050 + orders.length), amount: Number(orderForm.amount || 0), due: orderForm.due || "Not set" };
    setOrdersAndSave([record, ...orders]); setModal("");
    setOrderForm({ customer: "", product: "", amount: "", status: "New enquiry", due: "", location: "Main Workshop" });
    notify("Order created");
  };
  const removeRecord = (type, id) => {
    if (!window.confirm("Delete this " + type + "?")) return;
    if (type === "printer") setPrintersAndSave(printers.filter(item => item.id !== id));
    if (type === "material") setMaterialsAndSave(materials.filter(item => item.id !== id));
    if (type === "customer") setCustomersAndSave(customers.filter(item => item.id !== id));
    if (type === "order") setOrdersAndSave(orders.filter(item => item.id !== id));
    notify(type[0].toUpperCase() + type.slice(1) + " deleted");
  };

  const Metric = ({ title, value, change, Icon, color = "blue" }) => <article className="metric">
    <div className={"metric-icon " + color}><Icon size={19} /></div><span className="muted">{title}</span>
    <strong>{value}</strong><small><b><ArrowUpRight size={13} />{change}</b> vs previous month</small>
  </article>;
  const PageHeading = ({ title, detail, action }) => <div className="page-heading"><div><h1>{title}</h1><p>{detail}</p></div>{action}</div>;
  const AddButton = ({ children, onClick }) => <button className="btn primary" onClick={onClick}><Plus size={16} />{children}</button>;

  const OrderTable = ({ rows }) => <div className="table-scroll"><table><thead><tr><th>ORDER ID</th><th>CUSTOMER</th><th>PRODUCT</th><th>AMOUNT</th><th>STATUS</th><th>DUE DATE</th></tr></thead>
    <tbody>{rows.map(order => <tr key={order.id}><td className="id">{order.id}</td><td><b>{order.customer}</b></td><td>{order.product}</td><td className="money">{money(order.amount)}</td><td><Status value={order.status} /></td><td>{order.due}</td></tr>)}</tbody>
    </table>{rows.length === 0 && <div className="empty">No records found.</div>}</div>;

  const dashboard = <>
    <PageHeading title="Good evening, Admin 👋" detail="Here’s what’s happening across your Print_Bud operations today." action={<AddButton onClick={() => setModal("order")}>Create order</AddButton>} />
    <div className="toolbar"><label><MapPin size={15} /><select value={location} onChange={event => setLocation(event.target.value)}><option>All locations</option><option>Main Workshop</option><option>Resin Lab</option><option>Branch 03</option></select><ChevronDown size={13} /></label><span><CalendarDays size={14} /> {new Intl.DateTimeFormat("en-IN", { month: "long", year: "numeric" }).format(new Date())}</span><em>Live overview</em></div>
    <div className="metrics">
      <Metric title="Order pipeline value" value={money(orderValue)} change={orders.length + " recorded orders"} Icon={CircleDollarSign} />
      <Metric title="Open orders" value={activeOrders.length} change="Not delivered or cancelled" Icon={ClipboardList} color="purple" />
      <Metric title="Low-stock materials" value={lowStockItems.length} change="At or below reorder level" Icon={Boxes} color="orange" />
      <Metric title="Running printers" value={printers.filter(p => p.status === "Running").length} change={printers.length + " machines registered"} Icon={Gauge} color="green" />
    </div>
    <div className="dash-grid">
      <section className="panel"><div className="panel-heading"><div><h3>Order pipeline</h3><p>Current order value by production stage · ₹</p></div><span className="soft-tag">From saved records</span></div>
        <div className="chart"><ResponsiveContainer width="100%" height="100%"><BarChart data={orderStatusData} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}><CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#edf0f5" /><XAxis dataKey="status" axisLine={false} tickLine={false} tick={{ fill: "#929bad", fontSize: 9 }} /><YAxis axisLine={false} tickLine={false} tick={{ fill: "#929bad", fontSize: 10 }} /><Tooltip formatter={value => money(value)} /><Bar dataKey="value" name="Order value" fill="#4c7de0" radius={[5, 5, 0, 0]} /></BarChart></ResponsiveContainer></div>
      </section>
      <section className="panel"><div className="panel-heading"><div><h3>Printer status</h3><p>Across all locations</p></div><button className="link-btn" onClick={() => setPage("Printers")}>View all <ArrowUpRight size={14} /></button></div>
        <div className="printer-stats"><div><b>{printers.length}</b><small>Total printers</small></div><div><b>{printers.filter(p => p.status === "Running").length}</b><small>Running</small></div><div><b>{printers.filter(p => p.status === "Maintenance").length}</b><small>Maintenance</small></div></div>
        {printers.slice(0, 4).map(printer => <div className="machine-row" key={printer.id}><div className="machine-icon"><Printer size={17} /></div><div className="grow"><b>{printer.name}</b><small>{printer.id} · {printer.location}</small></div><Status value={printer.status} /></div>)}
      </section>
    </div>
    <section className="panel"><div className="panel-heading"><div><h3>Recent orders</h3><p>Latest customer work</p></div><button className="link-btn" onClick={() => setPage("Orders")}>View all orders <ArrowUpRight size={14} /></button></div><OrderTable rows={orders.slice(0, 5)} /></section>
    <div className="lower-grid">
      <section className="panel"><div className="panel-heading"><div><h3>Inventory alerts</h3><p>Materials needing attention</p></div><button className="link-btn" onClick={() => setPage("Materials")}>Inventory</button></div>
        {lowStockItems.length === 0 ? <div className="success-line"><CheckCircle2 size={17} /> All material stocks are above minimum.</div> : lowStockItems.map(m => <div className="alert-line" key={m.id}><AlertTriangle size={17} /><span><b>{m.name}</b><small>{m.stock} kg remaining · Minimum {m.min} kg</small></span><Status value="Low stock" /></div>)}
      </section>
      <section className="panel"><div className="panel-heading"><div><h3>Quick actions</h3><p>Common tasks</p></div></div><div className="quick-grid">
        <button onClick={() => setModal("order")}><Plus /><span>New order</span></button><button onClick={() => openPrinter(null)}><Printer /><span>Add printer</span></button><button onClick={() => openMaterial(null)}><Boxes /><span>Add material</span></button><button onClick={() => setPage("Costing")}><Calculator /><span>Calculate cost</span></button>
      </div></section>
    </div>
  </>;

  const ordersPage = <><PageHeading title="Orders" detail="Manage customer enquiries, quotations and production progress." action={<AddButton onClick={() => setModal("order")}>Create order</AddButton>} />
    <section className="panel"><div className="panel-heading"><div><h3>All orders</h3><p>{orders.length} records · search using the top bar</p></div><span className="soft-tag"><Filter size={13} /> All statuses</span></div><OrderTable rows={filtered(orders)} /></section></>;
  const printersPage = <><PageHeading title="Printer management" detail="Manage FDM and Resin machines across workshop locations." action={<AddButton onClick={() => openPrinter(null)}>Add printer</AddButton>} />
    <div className="metrics compact"><Metric title="Total machines" value={printers.length} change="Registered" Icon={Printer} /><Metric title="Running now" value={printers.filter(p => p.status === "Running").length} change="Active" Icon={Zap} color="green" /><Metric title="Run hours" value={printers.reduce((s, p) => s + Number(p.hours), 0)} change="Recorded" Icon={Clock3} color="purple" /><Metric title="Locations" value={new Set(printers.map(p => p.location)).size} change="Active sites" Icon={MapPin} color="orange" /></div>
    <section className="panel"><div className="panel-heading"><div><h3>Registered printers</h3><p>Machine profiles and operating details</p></div></div><div className="table-scroll"><table><thead><tr><th>PRINTER</th><th>TECHNOLOGY</th><th>LOCATION</th><th>POWER</th><th>RUN HOURS</th><th>STATUS</th><th>ACTIONS</th></tr></thead><tbody>{filtered(printers).map(p => <tr key={p.id}><td><b>{p.name}</b><small className="subcell">{p.id}</small></td><td><span className="soft-tag">{p.technology}</span></td><td>{p.location}</td><td>{p.watts} W</td><td>{p.hours} h</td><td><Status value={p.status} /></td><td><button className="mini-action" onClick={() => openPrinter(p)}>Edit</button><button className="mini-action danger" onClick={() => removeRecord("printer", p.id)}>Delete</button></td></tr>)}</tbody></table>{filtered(printers).length === 0 && <div className="empty">No printers found.</div>}</div></section></>;
  const materialsPage = <><PageHeading title="Material inventory" detail="Track materials, colours, purchase rates and reorder levels." action={<AddButton onClick={() => openMaterial(null)}>Add material</AddButton>} />
    <div className="summary"><div><span>Material types</span><b>{new Set(materials.map(m => m.type)).size}</b></div><div><span>Stock quantity</span><b>{materials.reduce((s, m) => s + Number(m.stock), 0).toFixed(1)} kg</b></div><div><span>Inventory value</span><b>{money(materials.reduce((s, m) => s + Number(m.stock) * Number(m.rate), 0))}</b></div><div><span>Low stock items</span><b className="warning-text">{materials.filter(m => Number(m.stock) <= Number(m.min)).length}</b></div></div>
    <section className="panel"><div className="panel-heading"><div><h3>Material catalogue</h3><p>Available stock and purchase rates</p></div><span className="soft-tag">Stock on hand</span></div><div className="table-scroll"><table><thead><tr><th>MATERIAL</th><th>TYPE</th><th>COLOUR</th><th>AVAILABLE</th><th>RATE / KG</th><th>STOCK VALUE</th><th>ACTIONS</th></tr></thead><tbody>{filtered(materials).map(m => <tr key={m.id}><td><b>{m.name}</b><small className="subcell">{m.id}</small></td><td>{m.type}</td><td>{m.colour || "—"}</td><td><b>{m.stock} kg</b>{Number(m.stock) <= Number(m.min) && <small className="subcell warning-text">Below minimum</small>}</td><td>{money(m.rate)}</td><td className="money">{money(Number(m.stock) * Number(m.rate))}</td><td><button className="mini-action" onClick={() => openMaterial(m)}>Edit</button><button className="mini-action danger" onClick={() => removeRecord("material", m.id)}>Delete</button></td></tr>)}</tbody></table>{filtered(materials).length === 0 && <div className="empty">No materials found.</div>}</div></section></>;
  const customersPage = <><PageHeading title="Customers" detail="Customer directory, account history and outstanding balances." action={<AddButton onClick={() => { setEditing(null); setCustomerForm({ name: "", type: "Business", phone: "", city: "", orders: 0, outstanding: 0 }); setModal("customer"); }}>Add customer</AddButton>} />
    <section className="panel"><div className="panel-heading"><div><h3>Customer directory</h3><p>Customer information and account balances</p></div></div><div className="table-scroll"><table><thead><tr><th>CUSTOMER</th><th>TYPE</th><th>PHONE</th><th>CITY</th><th>ORDERS</th><th>OUTSTANDING</th><th>ACTIONS</th></tr></thead><tbody>{filtered(customers).map(c => <tr key={c.id}><td><b>{c.name}</b><small className="subcell">{c.id}</small></td><td>{c.type}</td><td>{c.phone}</td><td>{c.city}</td><td>{c.orders}</td><td className="money">{money(c.outstanding)}</td><td><button className="mini-action" onClick={() => { setEditing(c); setCustomerForm({ ...c }); setModal("customer"); }}>Edit</button></td></tr>)}</tbody></table></div></section></>;
  const costingPage = <><PageHeading title="Costing calculator" detail="Estimate product cost and suggested selling price before quotation." action={<button className="btn secondary" onClick={() => setCost({ grams: 120, rate: 850, hours: 8, watts: 350, electricity: settings.electricity, machine: 12, painting: 120, labour: 100, packaging: 40, shipping: 80, other: 20, markup: settings.markup })}>Reset inputs</button>} />
    <div className="cost-grid"><section className="panel"><div className="panel-heading"><div><h3>Cost inputs</h3><p>Change values to update the calculation</p></div></div><h4><Boxes size={16} /> Printing costs</h4><div className="field-grid">{[["grams","Material used (grams)"],["rate","Material rate (₹ / kg)"],["hours","Print duration (hours)"],["watts","Printer power (watts)"],["electricity","Electricity rate (₹ / unit)"],["machine","Machine rate (₹ / hour)"]].map(([key, label]) => <Field label={label} key={key}><input type="number" min="0" value={cost[key]} onChange={e => setCost({ ...cost, [key]: e.target.value })} /></Field>)}</div><hr /><h4><Package size={16} /> Finishing and fulfilment</h4><div className="field-grid">{[["painting","Painting (₹)"],["labour","Labour (₹)"],["packaging","Packaging (₹)"],["shipping","Shipping (₹)"],["other","Other (₹)"]].map(([key, label]) => <Field label={label} key={key}><input type="number" min="0" value={cost[key]} onChange={e => setCost({ ...cost, [key]: e.target.value })} /></Field>)}</div><hr /><Field label={"Markup on cost: " + cost.markup + "%"}><input type="range" min="0" max="150" value={cost.markup} onChange={e => setCost({ ...cost, markup: e.target.value })} /></Field></section>
      <section className="panel result-panel"><div className="result-head"><span>ESTIMATED SELLING PRICE</span><strong>{money(quotePrice)}</strong><small>Before applicable taxes</small></div><div className="result-lines"><div><span>Material</span><b>{money(costParts.material)}</b></div><div><span>Electricity</span><b>{money(costParts.electricity)}</b></div><div><span>Machine cost</span><b>{money(costParts.machine)}</b></div>{["painting", "labour", "packaging", "shipping", "other"].map(k => <div key={k}><span>{k[0].toUpperCase() + k.slice(1)}</span><b>{money(cost[k])}</b></div>)}<div className="total-line"><span>Total estimated cost</span><b>{money(totalCost)}</b></div><div><span>Profit on cost (markup)</span><b className="success-text">{money(profit)}</b></div></div><div className="margin-box"><span>Gross margin on selling price</span><b>{quotePrice ? (profit / quotePrice * 100).toFixed(1) : "0.0"}%</b><small>Markup and profit margin are different measures. GST is excluded.</small></div><button className="btn primary full" onClick={() => notify("Estimate saved in this browser")}>Save estimate</button></section></div></>;
  const invoicesPage = <><PageHeading title="Invoices & billing" detail="GST and Non-GST billing workspace." action={<button className="btn primary" onClick={() => notify("Invoice PDF workflow is planned for V0.2")}><Plus size={16} /> New invoice</button>} /><div className="tabs"><button className={billingMode === "GST" ? "selected" : ""} onClick={() => setBillingMode("GST")}>GST invoices</button><button className={billingMode === "Non-GST" ? "selected" : ""} onClick={() => setBillingMode("Non-GST")}>Non-GST invoices</button></div><section className="panel empty"><FileText size={28} /><b>{billingMode} billing register foundation</b><span>Invoice numbering, tax treatment, payment allocation and downloadable PDF generation are planned for V0.2.</span></section></>;
  const reportsPage = <><PageHeading title="Reports & analytics" detail="Monitor sales, production efficiency and business profitability." action={<button className="btn secondary" onClick={() => notify("Export will be enabled with live database integration")}><Download size={15} /> Export</button>} /><div className="metrics"><Metric title="Revenue this month" value="₹84,000" change="+16.2%" Icon={Wallet} /><Metric title="Estimated profit" value="₹32,000" change="+11.1%" Icon={CircleDollarSign} color="green" /><Metric title="Material consumed" value="18.6 kg" change="+2.4 kg" Icon={Boxes} color="purple" /><Metric title="Jobs completed" value="46" change="+9 jobs" Icon={Check} color="orange" /></div><div className="dash-grid"><section className="panel"><div className="panel-heading"><div><h3>Revenue by month</h3><p>₹ thousands · sample data</p></div></div><div className="chart tall"><ResponsiveContainer width="100%" height="100%"><BarChart data={revenueData}><CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#edf0f5" /><XAxis dataKey="month" /><YAxis /><Tooltip /><Bar dataKey="revenue" fill="#4c7de0" radius={[5, 5, 0, 0]} /></BarChart></ResponsiveContainer></div></section><section className="panel">{["Sales and revenue", "Profit and loss", "Printer utilization", "Material consumption", "Customer performance", "GST summary"].map(item => <div className="report-row" key={item}><FileText size={16} />{item}<ArrowUpRight size={14} /></div>)}</section></div></>;
  const settingsPage = <><PageHeading title="Settings" detail="Configure company identity and default costing rules." action={<button className="btn primary" onClick={() => notify("Settings saved in this browser session")}><Check size={15} /> Save settings</button>} /><section className="panel settings-panel"><h3>Company and business defaults</h3><p>These settings are local prototype values. Cloud persistence and user access will be added in the backend phase.</p><div className="field-grid"><Field label="Company name"><input value={settings.company} onChange={e => setSettings({ ...settings, company: e.target.value })} /></Field><Field label="Electricity rate (₹ / unit)"><input type="number" value={settings.electricity} onChange={e => setSettings({ ...settings, electricity: Number(e.target.value) })} /></Field><Field label="Default markup (%)"><input type="number" value={settings.markup} onChange={e => setSettings({ ...settings, markup: Number(e.target.value) })} /></Field><Field label="Default GST rate (%)"><select value={settings.gst} onChange={e => setSettings({ ...settings, gst: Number(e.target.value) })}><option value="0">0%</option><option value="5">5%</option><option value="12">12%</option><option value="18">18%</option><option value="28">28%</option></select></Field></div><div className="notice"><AlertTriangle size={17} /> GST applicability, HSN/SAC, place of supply and invoice treatment must be configured and reviewed by your accountant before live billing.</div></section></>;

  const content = { Dashboard: dashboard, Orders: ordersPage, Printers: printersPage, Materials: materialsPage, Customers: customersPage, Costing: costingPage, Invoices: invoicesPage, Reports: reportsPage, Settings: settingsPage }[page] || dashboard;

  return <div className="app">
    <aside className={"sidebar " + (mobileNav ? "open" : "")}>
      <div className="brand"><div className="brand-mark">PB</div><div><b>Print_Bud</b><small>MANUFACTURING CRM</small></div><button className="mobile-close icon-btn" onClick={() => setMobileNav(false)}><X /></button></div>
      <div className="workspace"><div className="workspace-mark">P</div><div><b>Print_Bud Studio</b><small>Workspace</small></div><ChevronDown size={14} /></div>
      {nav.map(section => <div className="nav-section" key={section.label}><label>{section.label}</label>{section.items.map(([name, Icon]) => <button key={name} onClick={() => { setPage(name); setMobileNav(false); setSearch(""); }} className={"nav-link " + (page === name ? "active" : "")}><Icon size={17} /><span>{name}</span>{name === "Orders" && <em>{orders.filter(o => o.status !== "Delivered").length}</em>}</button>)}</div>)}
      <div className="sidebar-bottom"><div className="plan-card"><b>Print_Bud CRM</b><p>Version 0.1 · Prototype</p><small>Cloud-ready foundation</small></div><div className="user"><div>AD</div><span><b>Admin User</b><small>Administrator</small></span></div></div>
    </aside>
    <main className="main"><header className="topbar"><button className="mobile-toggle icon-btn" onClick={() => setMobileNav(true)}><Menu /></button><div className="breadcrumb"><span>Print_Bud</span><b>/</b>{page}</div><div className="top-actions"><label className="search"><Search size={16} /><input placeholder="Search this view..." value={search} onChange={e => setSearch(e.target.value)} /></label><button className="icon-btn bell" onClick={() => notify("No new notifications")}><Bell size={18} /></button><div className="top-avatar">AD</div></div></header>
      <div className="content">{content}<footer>© 2026 Print_Bud <span>Sample data · Local prototype · Not for live billing</span></footer></div>
    </main>

    {modal === "printer" && <Modal title={editing ? "Edit printer" : "Add printer"} onClose={() => setModal("")}><form onSubmit={savePrinter}><div className="field-grid"><Field label="Printer name"><input required value={printerForm.name || ""} onChange={e => setPrinterForm({ ...printerForm, name: e.target.value })} /></Field><Field label="Technology"><select value={printerForm.technology || "FDM"} onChange={e => setPrinterForm({ ...printerForm, technology: e.target.value })}><option>FDM</option><option>Resin</option></select></Field><Field label="Location"><select value={printerForm.location || "Main Workshop"} onChange={e => setPrinterForm({ ...printerForm, location: e.target.value })}><option>Main Workshop</option><option>Resin Lab</option><option>Branch 03</option></select></Field><Field label="Power (watts)"><input type="number" min="0" value={printerForm.watts ?? 350} onChange={e => setPrinterForm({ ...printerForm, watts: Number(e.target.value) })} /></Field><Field label="Running hours"><input type="number" min="0" value={printerForm.hours ?? 0} onChange={e => setPrinterForm({ ...printerForm, hours: Number(e.target.value) })} /></Field><Field label="Status"><select value={printerForm.status || "Idle"} onChange={e => setPrinterForm({ ...printerForm, status: e.target.value })}><option>Idle</option><option>Running</option><option>Maintenance</option></select></Field></div><div className="modal-actions"><button type="button" className="btn secondary" onClick={() => setModal("")}>Cancel</button><button className="btn primary">Save printer</button></div></form></Modal>}
    {modal === "material" && <Modal title={editing ? "Edit material" : "Add material"} onClose={() => setModal("")}><form onSubmit={saveMaterial}><div className="field-grid"><Field label="Material name"><input required value={materialForm.name || ""} onChange={e => setMaterialForm({ ...materialForm, name: e.target.value })} /></Field><Field label="Material type"><select value={materialForm.type || "PLA"} onChange={e => setMaterialForm({ ...materialForm, type: e.target.value })}>{["PLA", "PLA+", "PETG", "ABS", "TPU", "Resin", "Other"].map(x => <option key={x}>{x}</option>)}</select></Field><Field label="Colour"><input value={materialForm.colour || ""} onChange={e => setMaterialForm({ ...materialForm, colour: e.target.value })} /></Field><Field label="Available stock (kg)"><input type="number" min="0" step="0.01" value={materialForm.stock ?? 0} onChange={e => setMaterialForm({ ...materialForm, stock: Number(e.target.value) })} /></Field><Field label="Purchase rate (₹ / kg)"><input type="number" min="0" value={materialForm.rate ?? 0} onChange={e => setMaterialForm({ ...materialForm, rate: Number(e.target.value) })} /></Field><Field label="Minimum stock (kg)"><input type="number" min="0" step="0.1" value={materialForm.min ?? 1} onChange={e => setMaterialForm({ ...materialForm, min: Number(e.target.value) })} /></Field></div><div className="modal-actions"><button type="button" className="btn secondary" onClick={() => setModal("")}>Cancel</button><button className="btn primary">Save material</button></div></form></Modal>}
    {modal === "customer" && <Modal title={editing ? "Edit customer" : "Add customer"} onClose={() => setModal("")}><form onSubmit={saveCustomer}><div className="field-grid"><Field label="Customer / company name"><input required value={customerForm.name || ""} onChange={e => setCustomerForm({ ...customerForm, name: e.target.value })} /></Field><Field label="Customer type"><select value={customerForm.type || "Business"} onChange={e => setCustomerForm({ ...customerForm, type: e.target.value })}>{["Individual", "Business", "Reseller", "Wholesale"].map(x => <option key={x}>{x}</option>)}</select></Field><Field label="Phone / WhatsApp"><input value={customerForm.phone || ""} onChange={e => setCustomerForm({ ...customerForm, phone: e.target.value })} /></Field><Field label="City"><input value={customerForm.city || ""} onChange={e => setCustomerForm({ ...customerForm, city: e.target.value })} /></Field><Field label="Outstanding (₹)"><input type="number" min="0" value={customerForm.outstanding ?? 0} onChange={e => setCustomerForm({ ...customerForm, outstanding: Number(e.target.value) })} /></Field></div><div className="modal-actions"><button type="button" className="btn secondary" onClick={() => setModal("")}>Cancel</button><button className="btn primary">Save customer</button></div></form></Modal>}
    {modal === "order" && <Modal title="Create new order" onClose={() => setModal("")}><form onSubmit={saveOrder}><div className="field-grid"><Field label="Customer name"><input required value={orderForm.customer} onChange={e => setOrderForm({ ...orderForm, customer: e.target.value })} /></Field><Field label="Product / service"><input required value={orderForm.product} onChange={e => setOrderForm({ ...orderForm, product: e.target.value })} /></Field><Field label="Order amount (₹)"><input required type="number" min="0" value={orderForm.amount} onChange={e => setOrderForm({ ...orderForm, amount: e.target.value })} /></Field><Field label="Location"><select value={orderForm.location} onChange={e => setOrderForm({ ...orderForm, location: e.target.value })}><option>Main Workshop</option><option>Resin Lab</option><option>Branch 03</option></select></Field><Field label="Order status"><select value={orderForm.status} onChange={e => setOrderForm({ ...orderForm, status: e.target.value })}>{["New enquiry", "Quotation", "Confirmed", "Printing", "Post-processing", "Quality check", "Delivered"].map(x => <option key={x}>{x}</option>)}</select></Field><Field label="Due date"><input type="date" value={orderForm.due} onChange={e => setOrderForm({ ...orderForm, due: e.target.value })} /></Field></div><div className="modal-actions"><button type="button" className="btn secondary" onClick={() => setModal("")}>Cancel</button><button className="btn primary">Create order</button></div></form></Modal>}
    {toast && <div className="toast"><CheckCircle2 size={17} />{toast}</div>}
  </div>;
}