import React, { useState, useEffect, useCallback, useRef } from 'react';
import {
  TrendingUp, TrendingDown, Wallet, Bell, RefreshCw, Settings,
  AlertTriangle, CheckCircle, Clock, BarChart2, List, Activity,
  ArrowUpRight, ArrowDownRight, ShoppingCart, Trash2, X, ChevronRight,
  PieChart, BookOpen, Zap, Shield, Star, User, HelpCircle,
  Landmark, Sparkles, Send, Award, FileText, DollarSign,
  ArrowUp, ArrowDown, LogIn, ArrowLeft, Lock, Mail, Key
} from 'lucide-react';
import { GoogleLogin } from '@react-oauth/google';
import { jwtDecode } from 'jwt-decode';

// ─── Sparkline ──────────────────────────────────────────────────────────────
const Sparkline = ({ history, isPositive, width = 100, height = 32 }) => {
  if (!history || history.length < 2) return (
    <div className="text-[10px] text-gray-600 italic">buffering…</div>
  );
  const min = Math.min(...history);
  const max = Math.max(...history);
  const range = max - min === 0 ? 1 : max - min;
  const pts = history.map((v, i) => {
    const x = (i / (history.length - 1)) * width;
    const y = height - ((v - min) / range) * height;
    return `${x.toFixed(1)},${y.toFixed(1)}`;
  }).join(' ');
  const fillPts = `${pts} ${width},${height} 0,${height}`;
  const stroke = isPositive ? '#00D09C' : '#FF5353';
  const gId = `g${Math.random().toString(36).slice(2, 8)}`;
  return (
    <svg width={width} height={height} className="overflow-visible">
      <defs>
        <linearGradient id={gId} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={stroke} stopOpacity="0.25" />
          <stop offset="100%" stopColor={stroke} stopOpacity="0" />
        </linearGradient>
      </defs>
      <polygon points={fillPts} fill={`url(#${gId})`} />
      <polyline fill="none" stroke={stroke} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" points={pts} />
    </svg>
  );
};

// ─── PNL Badge ──────────────────────────────────────────────────────────────
const PnlBadge = ({ value, percent }) => {
  const pos = value >= 0;
  return (
    <div className={`flex items-center gap-1 text-xs font-semibold ${pos ? 'text-gainGreen' : 'text-lossRed'}`}>
      {pos ? <ArrowUpRight className="w-3.5 h-3.5" /> : <ArrowDownRight className="w-3.5 h-3.5" />}
      <span>{pos ? '+' : ''}₹{Math.abs(value).toFixed(2)}</span>
      {percent !== undefined && (
        <span className={`px-1.5 py-0.5 rounded text-[10px] ${pos ? 'bg-gainGreen/10' : 'bg-lossRed/10'}`}>
          {pos ? '+' : ''}{percent.toFixed(2)}%
        </span>
      )}
    </div>
  );
};

// ─── Toast System ───────────────────────────────────────────────────────────
const Toast = ({ toasts, remove }) => (
  <div className="fixed bottom-6 right-6 z-[200] flex flex-col gap-2 pointer-events-none">
    {toasts.map(t => (
      <div key={t.id}
        className={`pointer-events-auto flex items-center gap-3 px-4 py-3 rounded-xl border shadow-2xl text-sm font-semibold max-w-xs animate-fadeIn
          ${t.type === 'success' ? 'bg-gainGreen/10 border-gainGreen/30 text-gainGreen' :
            t.type === 'error' ? 'bg-lossRed/10 border-lossRed/30 text-lossRed' :
            'bg-[#1e2d47] border-white/10 text-white'}`}
      >
        {t.type === 'success' ? <CheckCircle className="w-4 h-4 shrink-0" /> :
         t.type === 'error'   ? <AlertTriangle className="w-4 h-4 shrink-0" /> :
                                <Zap className="w-4 h-4 shrink-0" />}
        <span className="flex-1">{t.message}</span>
        <button onClick={() => remove(t.id)} className="opacity-60 hover:opacity-100">
          <X className="w-3.5 h-3.5" />
        </button>
      </div>
    ))}
  </div>
);

// ─── Main App ────────────────────────────────────────────────────────────────
const TABS = [
  { id: 'markets',   label: 'Markets',   icon: Activity },
  { id: 'portfolio', label: 'Portfolio', icon: PieChart },
  { id: 'alerts',    label: 'My Rules',  icon: Bell },
  { id: 'advisor',   label: 'AI Advisor',icon: Sparkles },
  { id: 'history',   label: 'Ledger',    icon: FileText },
  { id: 'academy',   label: 'Academy',   icon: BookOpen },
];

const SECTORS_LIST = [
  { name: 'Energy', code: 'ENE', color: 'bg-blue-500/10 text-blue-400 border-blue-500/20' },
  { name: 'IT', code: 'IT', color: 'bg-purple-500/10 text-purple-400 border-purple-500/20' },
  { name: 'Financial Services', code: 'FIN', color: 'bg-green-500/10 text-green-400 border-green-500/20' },
  { name: 'Telecom', code: 'TEL', color: 'bg-yellow-500/10 text-yellow-400 border-yellow-500/20' },
  { name: 'Construction', code: 'CON', color: 'bg-orange-500/10 text-orange-400 border-orange-500/20' },
  { name: 'FMCG', code: 'FMCG', color: 'bg-pink-500/10 text-pink-400 border-pink-500/20' },
  { name: 'Automobile', code: 'AUTO', color: 'bg-red-500/10 text-red-400 border-red-500/20' }
];

export default function App() {
  // ─── States ───────────────────────────────────────────────────────────────
  const [baseUrl, setBaseUrl]             = useState('http://localhost:5000');
  const [activeTab, setActiveTab]         = useState('markets');
  
  // Sub-navigation states (creating the 40+ pages structure)
  const [marketSubTab, setMarketSubTab]   = useState('watchlist'); // 'watchlist' | 'scanners' | 'sectors'
  const [scannerType, setScannerType]     = useState('gainers'); // 'gainers' | 'losers' | '52wHigh' | '52wLow' | 'volume'
  const [portfolioSubTab, setPortfolioSubTab] = useState('holdings'); // 'holdings' | 'wallet' | 'tax'
  const [alertSubTab, setAlertSubTab]     = useState('create'); // 'create' | 'active' | 'triggered'
  const [academySubTab, setAcademySubTab] = useState('tutorials'); // 'tutorials' | 'glossary'
  
  const [userId, setUserId]               = useState(null);
  const [walletBalance, setWalletBalance] = useState(100000);
  const [stocks, setStocks]               = useState([]);
  const [indices, setIndices]             = useState([]);
  const [alerts, setAlerts]               = useState([]);
  const [portfolio, setPortfolio]         = useState(null);
  const [trades, setTrades]               = useState([]);
  const [priceHistory, setPriceHistory]   = useState({});
  const [isLoading, setIsLoading]         = useState(true);
  const [error, setError]                 = useState(null);
  const [showSettings, setShowSettings]   = useState(false);
  const [tempUrl, setTempUrl]             = useState(baseUrl);
  
  // Stock details modal expansion (10 sub-views)
  const [selectedStock, setSelectedStock] = useState(null); // stock object
  const [stockDetailTab, setStockDetailTab] = useState('chart'); // 'chart' | 'fundamentals' | 'financials' | 'shareholder' | 'peers' | 'news' | 'trade'
  const [tradeModalType, setTradeModalType] = useState('BUY'); // 'BUY' | 'SELL'
  const [tradeModalQty, setTradeModalQty]   = useState('1');
  const [tradeModalErr, setTradeModalErr]   = useState('');
  const [tradeSubmitting, setTradeSubmitting] = useState(false);

  // AI Advisor & Chatbot states
  const [floatingAiOpen, setFloatingAiOpen] = useState(false);
  const [aiChatMessages, setAiChatMessages] = useState([
    { sender: 'ai', text: 'Welcome to **TradeMentor AI Assistant**! 🤖\n\nI can analyze Indian equities, run technical scanners, suggest asset allocations, or explain glossary concepts. What are you looking to scan today?' }
  ]);
  const [aiInput, setAiInput]             = useState('');
  const [aiLoading, setAiLoading]         = useState(false);
  const [riskProfile, setRiskProfile]     = useState('moderate');
  const [showRiskQuiz, setShowRiskQuiz]   = useState(false);
  const [aiSentimentData, setAiSentimentData] = useState({}); // symbol -> sentiment object

  // Onboarding screens and user profile fields matching the Flutter app flow
  const [currentScreen, setCurrentScreen] = useState(() => {
    return sessionStorage.getItem('tm_logged_in') === 'true' ? 'DASHBOARD' : 'SPLASH';
  });
  const [otpSentAlert, setOtpSentAlert]   = useState(false);
  const [loginEmail, setLoginEmail]       = useState('demo@tradementor.com');
  const [loginPassword, setLoginPassword] = useState('password123');
  const [registerName, setRegisterName]   = useState('');
  const [registerEmail, setRegisterEmail] = useState('');
  const [registerPassword, setRegisterPassword] = useState('');
  const [forgotEmail, setForgotEmail]     = useState('');
  const [resetOtp, setResetOtp]           = useState('');
  const [resetPassword, setResetPassword] = useState('');
  const [quizQ1, setQuizQ1]               = useState(-1);
  const [quizQ2, setQuizQ2]               = useState(-1);
  const [quizQ3, setQuizQ3]               = useState(-1);
  const [quizSubmitAlert, setQuizSubmitAlert] = useState(false);
  const [finalProfile, setFinalProfile]   = useState('moderate');
  const [userInfo, setUserInfo]           = useState({ name: 'Demo Investor', email: 'demo@tradementor.com' });

  // Simulated Wallet States
  const [walletDepositAmount, setWalletDepositAmount] = useState('25000');
  const [walletWithdrawAmount, setWalletWithdrawAmount] = useState('10000');
  const [walletLogs, setWalletLogs]       = useState([
    { id: 1, type: 'CREDIT', description: 'Simulated Initial Seed Allocation', amount: 100000.00, date: new Date().toISOString() }
  ]);

  // Toast States
  const [toasts, setToasts]               = useState([]);
  const toastId = useRef(0);
  const [sectorFilter, setSectorFilter]   = useState('All');
  const chatBottomRef = useRef(null);

  // ─── Callback Toasts ──────────────────────────────────────────────────────
  const addToast = useCallback((message, type = 'info') => {
    const id = ++toastId.current;
    setToasts(p => [...p, { id, message, type }]);
    setTimeout(() => setToasts(p => p.filter(t => t.id !== id)), 4000);
  }, []);

  const removeToast = id => setToasts(p => p.filter(t => t.id !== id));

  // ─── Fetch User Profile ─────────────────────────────────────────────────────
  const fetchUser = useCallback(async (url) => {
    try {
      const res = await fetch(`${url}/api/users/default`);
      if (res.ok) {
        const d = await res.json();
        setUserId(d._id);
        setWalletBalance(d.walletBalance);
        setUserInfo({ name: d.name, email: d.email });
        setError(null);
      }
    } catch {
      if (url === 'http://localhost:5000') {
        const fb = 'http://127.0.0.1:5000';
        setBaseUrl(fb); setTempUrl(fb);
        fetchUser(fb);
      } else {
        setError('Express API server offline. Check host configuration.');
      }
    }
  }, []);

  // ─── Fetch Market Indices & Tickers ─────────────────────────────────────────
  const fetchMarket = useCallback(async () => {
    if (!baseUrl) return;
    try {
      const [sRes, iRes] = await Promise.all([
        fetch(`${baseUrl}/api/stocks`),
        fetch(`${baseUrl}/api/indices`),
      ]);
      if (sRes.ok && iRes.ok) {
        const sData = await sRes.json();
        const iData = await iRes.json();
        setStocks(sData);
        setIndices(iData);
        setError(null);
        setPriceHistory(prev => {
          const upd = { ...prev };
          [...sData, ...iData].forEach(item => {
            const sym = item.symbol;
            if (!upd[sym]) upd[sym] = [];
            upd[sym] = [...upd[sym], item.currentPrice].slice(-20);
          });
          return upd;
        });
      }
    } catch { /* silent */ }
    finally { setIsLoading(false); }
  }, [baseUrl]);

  // ─── Fetch Alerts ───────────────────────────────────────────────────────────
  const fetchAlerts = useCallback(async () => {
    if (!baseUrl || !userId) return;
    try {
      const res = await fetch(`${baseUrl}/api/alerts/${userId}`);
      if (res.ok) setAlerts(await res.json());
    } catch { /* silent */ }
  }, [baseUrl, userId]);

  // ─── Fetch Portfolio holdings ───────────────────────────────────────────────
  const fetchPortfolio = useCallback(async () => {
    if (!baseUrl || !userId) return;
    try {
      const res = await fetch(`${baseUrl}/api/portfolio/${userId}`);
      if (res.ok) setPortfolio(await res.json());
    } catch { /* silent */ }
  }, [baseUrl, userId]);

  // ─── Fetch Trade Ledger ─────────────────────────────────────────────────────
  const fetchTrades = useCallback(async () => {
    if (!baseUrl || !userId) return;
    try {
      const res = await fetch(`${baseUrl}/api/trades/${userId}?limit=50`);
      if (res.ok) {
        const d = await res.json();
        setTrades(d.trades || []);
      }
    } catch { /* silent */ }
  }, [baseUrl, userId]);

  useEffect(() => { fetchUser(baseUrl); }, [baseUrl, fetchUser]);

  useEffect(() => {
    fetchMarket();
    const t = setInterval(() => { fetchMarket(); fetchPortfolio(); }, 5000);
    return () => clearInterval(t);
  }, [fetchMarket, fetchPortfolio]);

  useEffect(() => {
    if (userId) {
      fetchAlerts(); fetchPortfolio(); fetchTrades();
      const t = setInterval(() => { fetchAlerts(); fetchTrades(); }, 8000);
      return () => clearInterval(t);
    }
  }, [userId, fetchAlerts, fetchPortfolio, fetchTrades]);

  useEffect(() => {
    if (chatBottomRef.current) {
      chatBottomRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [aiChatMessages]);

  // ─── Deposit simulated cash ─────────────────────────────────────────────────
  const handleDeposit = (e) => {
    e.preventDefault();
    const amount = parseFloat(walletDepositAmount);
    if (isNaN(amount) || amount <= 0) {
      addToast('Please enter a valid deposit amount', 'error');
      return;
    }
    const newBalance = walletBalance + amount;
    setWalletBalance(newBalance);
    setWalletLogs(prev => [
      { id: Date.now(), type: 'CREDIT', description: 'Simulated cash deposit (UPI)', amount, date: new Date().toISOString() },
      ...prev
    ]);
    addToast(`Successfully credited ₹${amount.toLocaleString('en-IN')} to wallet`, 'success');
    setWalletDepositAmount('');
  };

  // ─── Withdraw simulated cash ────────────────────────────────────────────────
  const handleWithdraw = (e) => {
    e.preventDefault();
    const amount = parseFloat(walletWithdrawAmount);
    if (isNaN(amount) || amount <= 0) {
      addToast('Please enter a valid withdrawal amount', 'error');
      return;
    }
    if (amount > walletBalance) {
      addToast('Insufficient wallet balance', 'error');
      return;
    }
    const newBalance = walletBalance - amount;
    setWalletBalance(newBalance);
    setWalletLogs(prev => [
      { id: Date.now(), type: 'DEBIT', description: 'Simulated bank account withdrawal', amount, date: new Date().toISOString() },
      ...prev
    ]);
    addToast(`Successfully withdrew ₹${amount.toLocaleString('en-IN')} from wallet`, 'success');
    setWalletWithdrawAmount('');
  };

  // ─── Trade execution ────────────────────────────────────────────────────────
  const executeSimulatedTrade = async () => {
    const q = parseInt(tradeModalQty, 10);
    if (!q || q < 1) { setTradeModalErr('Enter a valid quantity (≥ 1)'); return; }
    const price = selectedStock?.currentPrice ?? 0;
    const total = q * price;
    if (tradeModalType === 'BUY' && total > walletBalance) {
      setTradeModalErr(`Insufficient balance. Need ₹${total.toFixed(2)}`);
      return;
    }
    setTradeSubmitting(true);
    setTradeModalErr('');
    try {
      const res = await fetch(`${baseUrl}/api/trade`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId, symbol: selectedStock.symbol, type: tradeModalType, quantity: q }),
      });
      const data = await res.json();
      if (res.ok) {
        setWalletBalance(data.newBalance);
        setWalletLogs(prev => [
          {
            id: Date.now(),
            type: tradeModalType === 'BUY' ? 'DEBIT' : 'CREDIT',
            description: `${tradeModalType} order: ${q}x ${selectedStock.symbol} @ ₹${price.toFixed(2)}`,
            amount: total,
            date: new Date().toISOString()
          },
          ...prev
        ]);
        fetchPortfolio();
        fetchTrades();
        addToast(`${tradeModalType} order executed successfully!`, 'success');
        setSelectedStock(null);
      } else {
        setTradeModalErr(data.error || 'Trade failed');
      }
    } catch {
      setTradeModalErr('Connection error. Server offline.');
    } finally {
      setTradeSubmitting(false);
    }
  };

  // ─── AI Advisor chat prompt ─────────────────────────────────────────────────
  const sendChatMessage = async (presetText = null) => {
    const textToSend = presetText || aiInput;
    if (!textToSend.trim()) return;
    
    setAiChatMessages(p => [...p, { sender: 'user', text: textToSend }]);
    if (!presetText) setAiInput('');
    setAiLoading(true);

    try {
      const res = await fetch(`${baseUrl}/api/ai/chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: textToSend, riskProfile }),
      });
      if (res.ok) {
        const d = await res.json();
        setAiChatMessages(p => [...p, { sender: 'ai', text: d.reply }]);
      } else {
        setAiChatMessages(p => [...p, { sender: 'ai', text: 'Sorry, my technical analysis processors are temporarily offline. Verify your server connection.' }]);
      }
    } catch {
      setAiChatMessages(p => [...p, { sender: 'ai', text: 'Network failure. Ensure your Express Docker container is online.' }]);
    } finally {
      setAiLoading(false);
    }
  };

  // ─── Trigger sentiment analysis ─────────────────────────────────────────────
  const fetchStockSentiment = async (symbol) => {
    try {
      const res = await fetch(`${baseUrl}/api/ai/sentiment/${symbol}`);
      if (res.ok) {
        const d = await res.json();
        setAiSentimentData(p => ({ ...p, [symbol]: d }));
      }
    } catch { /* silent */ }
  };

  // Open details sheet for a stock
  const openStockDetails = (stock) => {
    setSelectedStock(stock);
    setStockDetailTab('chart');
    setTradeModalQty('1');
    setTradeModalErr('');
    fetchStockSentiment(stock.symbol);
  };

  // Delete Alert rule
  const deleteAlert = async (alertId) => {
    try {
      await fetch(`${baseUrl}/api/alerts/${alertId}`, { method: 'DELETE' });
      fetchAlerts();
      addToast('Alert rule deleted', 'info');
    } catch { addToast('Failed to delete alert', 'error'); }
  };

  // Setup custom alert
  const [alertForm, setAlertForm] = useState({ stockSymbol: '', price: '', criteria: 'GREATER_THAN' });
  const deployAlert = async (e) => {
    e.preventDefault();
    if (!alertForm.stockSymbol || !alertForm.price) return;
    const tp = parseFloat(alertForm.price);
    if (isNaN(tp) || tp <= 0) { addToast('Enter a valid target price', 'error'); return; }
    try {
      const res = await fetch(`${baseUrl}/api/alerts`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId, symbol: alertForm.stockSymbol, targetPrice: tp, criteria: alertForm.criteria }),
      });
      if (res.ok) {
        fetchAlerts();
        addToast(`Alert rule deployed: ${alertForm.stockSymbol} target at ₹${tp.toFixed(2)}`, 'success');
        setAlertForm(f => ({ ...f, price: '' }));
      }
    } catch { addToast('Failed to deploy alert', 'error'); }
  };

  const sectors = ['All', ...Array.from(new Set(stocks.map(s => s.sector))).sort()];
  const filteredStocks = sectorFilter === 'All' ? stocks : stocks.filter(s => s.sector === sectorFilter);

  // Scanners helper calculations
  const gainers = [...stocks].sort((a, b) => b.pChange - a.pChange).slice(0, 5);
  const losers = [...stocks].sort((a, b) => a.pChange - b.pChange).slice(0, 5);
  const volumeShockers = [...stocks].sort((a, b) => b.currentPrice - a.currentPrice).slice(0, 5); // Simulated sorting

  // ─── JSX Renders ───────────────────────────────────────────────────────────
  if (currentScreen === 'SPLASH') {
    return (
      <div className="min-h-screen bg-[#0B121E] text-white flex flex-col items-center justify-center p-6 font-sans antialiased">
        <Toast toasts={toasts} remove={removeToast} />
        <div className="w-full max-w-md bg-[#141F32] border border-white/5 rounded-3xl p-8 shadow-2xl flex flex-col items-center text-center space-y-6">
          <div className="h-16 w-16 rounded-full bg-gainGreen/10 flex items-center justify-center border border-gainGreen/20 animate-pulse">
            <TrendingUp className="h-8 w-8 text-gainGreen" />
          </div>
          
          <div className="space-y-2">
            <h1 className="text-3xl font-extrabold tracking-tight font-outfit">TradeMentor</h1>
            <p className="text-[10px] text-gainGreen border border-gainGreen/20 px-2 py-0.5 rounded inline-block bg-gainGreen/5 font-semibold">
              VIRTUAL EQUITIES ASSISTANT
            </p>
          </div>

          <p className="text-xs text-gray-400 leading-relaxed max-w-sm">
            Indian Real-Time Stock Monitoring & Rule-Based AI Trading Assistant. Practice paper trading with zero risk and access AI advisory models.
          </p>

          <div className="w-full p-4 rounded-xl bg-[#0B121E] border border-white/5 text-left flex items-start gap-3">
            <Shield className="w-5 h-5 text-gainGreen shrink-0 mt-0.5" />
            <div className="text-[11px] text-gray-400 leading-relaxed">
              Define custom target triggers (SMA/RSI/Trailing Stops) and consult with a conversational AI Mentor dynamically adjusted to your risk threshold.
            </div>
          </div>

          <button onClick={() => setCurrentScreen('LOGIN')}
            className="w-full py-3 bg-gainGreen text-black font-extrabold rounded-xl hover:bg-gainGreen/90 transition-all flex items-center justify-center gap-2 text-sm shadow-lg shadow-gainGreen/10">
            Get Started <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      </div>
    );
  }

  if (currentScreen === 'LOGIN') {
    const handleLoginSubmit = (e) => {
      e.preventDefault();
      if (!loginEmail.trim() || !loginPassword.trim()) {
        addToast('Please enter both email and password', 'error');
        return;
      }
      
      // Fetch default user details from backend if available
      fetchUser(baseUrl);
      addToast('Simulated login successful!', 'success');
      setCurrentScreen('RISK_QUIZ');
    };

    const handleGoogleLogin = async (credentialResponse) => {
      try {
        const decoded = jwtDecode(credentialResponse.credential);
        const { name, email } = decoded;

        const res = await fetch(`${baseUrl}/api/auth/google`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ name, email }),
        });
        if (res.ok) {
          const d = await res.json();
          setUserId(d.userId);
          setWalletBalance(d.walletBalance);
          setUserInfo({ name: d.name, email: d.email });
          sessionStorage.setItem('tm_logged_in', 'true');
          addToast('Google login successful!', 'success');
          setCurrentScreen('RISK_QUIZ');
        } else {
          addToast('Google login failed', 'error');
        }
      } catch (e) {
        console.error(e);
        addToast('Cannot reach backend or decode token', 'error');
      }
    };

    return (
      <div className="min-h-screen bg-[#0B121E] text-white flex flex-col items-center justify-center p-6 font-sans antialiased">
        <Toast toasts={toasts} remove={removeToast} />
        <div className="w-full max-w-md bg-[#141F32] border border-white/5 rounded-3xl p-8 shadow-2xl space-y-6">
          <button onClick={() => setCurrentScreen('SPLASH')} className="flex items-center gap-1.5 text-xs text-gray-400 hover:text-white transition-all">
            <ArrowLeft className="w-3.5 h-3.5" /> Back to Welcome
          </button>

          <div className="space-y-1">
            <h2 className="text-2xl font-extrabold font-outfit">Welcome Back</h2>
            <p className="text-xs text-gray-400">Sign in to access real-time NSE stock simulation and rule execution.</p>
          </div>

          <form onSubmit={handleLoginSubmit} className="space-y-4">
            <div className="space-y-1">
              <label className="block text-[10px] text-gray-500 uppercase tracking-wider font-bold">Email Address</label>
              <div className="relative">
                <Mail className="absolute left-3.5 top-3 w-4 h-4 text-gray-500" />
                <input type="email" value={loginEmail} onChange={e => setLoginEmail(e.target.value)}
                  className="w-full bg-[#0B121E] border border-white/10 rounded-xl pl-11 pr-4 py-2.5 text-xs text-white focus:outline-none focus:border-gainGreen"
                  placeholder="demo@tradementor.com"
                />
              </div>
            </div>

            <div className="space-y-1">
              <div className="flex justify-between items-center">
                <label className="block text-[10px] text-gray-500 uppercase tracking-wider font-bold">Password</label>
                <button type="button" onClick={() => setCurrentScreen('FORGOT')} className="text-[10px] text-gainGreen hover:underline">Forgot Password?</button>
              </div>
              <div className="relative">
                <Lock className="absolute left-3.5 top-3 w-4 h-4 text-gray-500" />
                <input type="password" value={loginPassword} onChange={e => setLoginPassword(e.target.value)}
                  className="w-full bg-[#0B121E] border border-white/10 rounded-xl pl-11 pr-4 py-2.5 text-xs text-white focus:outline-none focus:border-gainGreen"
                  placeholder="••••••••"
                />
              </div>
            </div>

            <button type="submit"
              className="w-full py-3 bg-gainGreen text-black font-extrabold rounded-xl hover:bg-gainGreen/90 transition-all text-xs uppercase tracking-wider shadow-lg shadow-gainGreen/10">
              Sign In
            </button>
            <div className="flex justify-center pt-2">
              <GoogleLogin
                onSuccess={handleGoogleLogin}
                onError={() => {
                  addToast('Google Login Failed', 'error');
                }}
                theme="filled_black"
                shape="rectangular"
                size="large"
                text="continue_with"
                width="100%"
              />
            </div>
          </form>

          <div className="text-center text-xs">
            <span className="text-gray-500">Don't have an account? </span>
            <button onClick={() => setCurrentScreen('REGISTER')} className="text-gainGreen font-bold hover:underline">Register Now</button>
          </div>
        </div>
      </div>
    );
  }

  if (currentScreen === 'REGISTER') {
    const handleRegisterSubmit = (e) => {
      e.preventDefault();
      if (!registerName.trim() || !registerEmail.trim() || !registerPassword.trim()) {
        addToast('Please fill all fields', 'error');
        return;
      }
      setUserInfo({ name: registerName, email: registerEmail });
      addToast('Simulated registration successful!', 'success');
      setCurrentScreen('RISK_QUIZ');
    };

    const handleGoogleLogin = async (e, gName, gEmail) => {
      e.preventDefault();
      try {
        const res = await fetch(`${baseUrl}/api/auth/google`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ name: gName, email: gEmail }),
        });
        if (res.ok) {
          const d = await res.json();
          setUserId(d.userId);
          setWalletBalance(d.walletBalance);
          setUserInfo({ name: d.name, email: d.email });
          sessionStorage.setItem('tm_logged_in', 'true');
          addToast('Google login successful!', 'success');
          setCurrentScreen('RISK_QUIZ');
        } else {
          addToast('Google login failed', 'error');
        }
      } catch {
        addToast('Cannot reach backend', 'error');
      }
    };

    return (
      <div className="min-h-screen bg-[#0B121E] text-white flex flex-col items-center justify-center p-6 font-sans antialiased">
        <Toast toasts={toasts} remove={removeToast} />
        <div className="w-full max-w-md bg-[#141F32] border border-white/5 rounded-3xl p-8 shadow-2xl space-y-6">
          <button onClick={() => setCurrentScreen('LOGIN')} className="flex items-center gap-1.5 text-xs text-gray-400 hover:text-white transition-all">
            <ArrowLeft className="w-3.5 h-3.5" /> Back to Login
          </button>

          <div className="space-y-1">
            <h2 className="text-2xl font-extrabold font-outfit">Create Account</h2>
            <p className="text-xs text-gray-400">Join TradeMentor to create custom alert triggers and paper trade.</p>
          </div>

          <form onSubmit={handleRegisterSubmit} className="space-y-4">
            <div className="space-y-1">
              <label className="block text-[10px] text-gray-500 uppercase tracking-wider font-bold">Full Name</label>
              <div className="relative">
                <User className="absolute left-3.5 top-3 w-4 h-4 text-gray-500" />
                <input type="text" value={registerName} onChange={e => setRegisterName(e.target.value)}
                  className="w-full bg-[#0B121E] border border-white/10 rounded-xl pl-11 pr-4 py-2.5 text-xs text-white focus:outline-none focus:border-gainGreen"
                  placeholder="e.g. Ishwar Kumar"
                />
              </div>
            </div>

            <div className="space-y-1">
              <label className="block text-[10px] text-gray-500 uppercase tracking-wider font-bold">Email Address</label>
              <div className="relative">
                <Mail className="absolute left-3.5 top-3 w-4 h-4 text-gray-500" />
                <input type="email" value={registerEmail} onChange={e => setRegisterEmail(e.target.value)}
                  className="w-full bg-[#0B121E] border border-white/10 rounded-xl pl-11 pr-4 py-2.5 text-xs text-white focus:outline-none focus:border-gainGreen"
                  placeholder="ishwar@example.com"
                />
              </div>
            </div>

            <div className="space-y-1">
              <label className="block text-[10px] text-gray-500 uppercase tracking-wider font-bold">Password</label>
              <div className="relative">
                <Lock className="absolute left-3.5 top-3 w-4 h-4 text-gray-500" />
                <input type="password" value={registerPassword} onChange={e => setRegisterPassword(e.target.value)}
                  className="w-full bg-[#0B121E] border border-white/10 rounded-xl pl-11 pr-4 py-2.5 text-xs text-white focus:outline-none focus:border-gainGreen"
                  placeholder="••••••••"
                />
              </div>
            </div>

            <button type="submit"
              className="w-full py-3 bg-gainGreen text-black font-extrabold rounded-xl hover:bg-gainGreen/90 transition-all text-xs uppercase tracking-wider shadow-lg shadow-gainGreen/10">
              Sign Up
            </button>
            <button type="button" onClick={(e) => handleGoogleLogin(e, 'Ishwa Reddy', 'ishwa@tradementor.com')}
              className="w-full py-3 bg-transparent border border-white/20 text-white font-bold rounded-xl hover:bg-white/5 transition-all text-xs uppercase tracking-wider flex items-center justify-center gap-2">
              <svg viewBox="0 0 24 24" width="16" height="16" xmlns="http://www.w3.org/2000/svg"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>
              Continue with Google
            </button>
          </form>

          <div className="text-center text-xs">
            <span className="text-gray-500">Already have an account? </span>
            <button onClick={() => setCurrentScreen('LOGIN')} className="text-gainGreen font-bold hover:underline">Log In</button>
          </div>
        </div>
      </div>
    );
  }

  if (currentScreen === 'FORGOT') {
    const handleForgotSubmit = (e) => {
      e.preventDefault();
      if (!forgotEmail.trim()) {
        addToast('Please enter your email', 'error');
        return;
      }
      setOtpSentAlert(true);
    };

    return (
      <div className="min-h-screen bg-[#0B121E] text-white flex flex-col items-center justify-center p-6 font-sans antialiased">
        <Toast toasts={toasts} remove={removeToast} />
        <div className="w-full max-w-md bg-[#141F32] border border-white/5 rounded-3xl p-8 shadow-2xl space-y-6">
          <button onClick={() => setCurrentScreen('LOGIN')} className="flex items-center gap-1.5 text-xs text-gray-400 hover:text-white transition-all">
            <ArrowLeft className="w-3.5 h-3.5" /> Back to Login
          </button>

          <div className="space-y-1">
            <h2 className="text-2xl font-extrabold font-outfit">Forgot Password</h2>
            <p className="text-xs text-gray-400">Provide your email address to receive a simulated 4-digit verification code.</p>
          </div>

          <form onSubmit={handleForgotSubmit} className="space-y-4">
            <div className="space-y-1">
              <label className="block text-[10px] text-gray-500 uppercase tracking-wider font-bold">Email Address</label>
              <div className="relative">
                <Mail className="absolute left-3.5 top-3 w-4 h-4 text-gray-500" />
                <input type="email" value={forgotEmail} onChange={e => setForgotEmail(e.target.value)}
                  className="w-full bg-[#0B121E] border border-white/10 rounded-xl pl-11 pr-4 py-2.5 text-xs text-white focus:outline-none focus:border-gainGreen"
                  placeholder="demo@tradementor.com"
                />
              </div>
            </div>

            <button type="submit"
              className="w-full py-3 bg-gainGreen text-black font-extrabold rounded-xl hover:bg-gainGreen/90 transition-all text-xs uppercase tracking-wider shadow-lg shadow-gainGreen/10">
              Send OTP Verification
            </button>
          </form>
        </div>

        {/* Simulated OTP Popup */}
        {otpSentAlert && (
          <div className="fixed inset-0 z-[160] flex items-center justify-center p-4 bg-black/85 backdrop-blur-sm">
            <div className="bg-[#141F32] border border-white/10 rounded-2xl w-full max-w-xs shadow-2xl p-6 text-center space-y-4">
              <div className="mx-auto w-12 h-12 rounded-full bg-gainGreen/10 border border-gainGreen/20 flex items-center justify-center">
                <Mail className="w-5 h-5 text-gainGreen" />
              </div>
              <h3 className="font-extrabold text-sm text-white">Simulated SMS / Email OTP</h3>
              <p className="text-[11px] text-gray-400 leading-relaxed">
                Your simulated password reset verification OTP is:<br />
                <strong className="text-lg text-gainGreen tracking-widest block my-2">4821</strong>
                Use this code on the next page to reset your password.
              </p>
              <button onClick={() => { setOtpSentAlert(false); setCurrentScreen('RESET'); }}
                className="w-full py-2 bg-gainGreen hover:bg-gainGreen/90 text-black font-bold text-xs rounded-lg transition-all">
                Enter Code
              </button>
            </div>
          </div>
        )}
      </div>
    );
  }

  if (currentScreen === 'RESET') {
    const handleResetSubmit = (e) => {
      e.preventDefault();
      if (resetOtp.trim() !== '4821') {
        addToast('Invalid OTP code. Try "4821".', 'error');
        return;
      }
      if (!resetPassword.trim()) {
        addToast('Please enter a new password', 'error');
        return;
      }
      addToast('Password updated successfully!', 'success');
      setCurrentScreen('LOGIN');
      setResetOtp('');
      setResetPassword('');
    };

    return (
      <div className="min-h-screen bg-[#0B121E] text-white flex flex-col items-center justify-center p-6 font-sans antialiased">
        <Toast toasts={toasts} remove={removeToast} />
        <div className="w-full max-w-md bg-[#141F32] border border-white/5 rounded-3xl p-8 shadow-2xl space-y-6">
          <button onClick={() => setCurrentScreen('FORGOT')} className="flex items-center gap-1.5 text-xs text-gray-400 hover:text-white transition-all">
            <ArrowLeft className="w-3.5 h-3.5" /> Back to Email
          </button>

          <div className="space-y-1">
            <h2 className="text-2xl font-extrabold font-outfit">Reset Password</h2>
            <p className="text-xs text-gray-400">Enter the 4-digit code (4821) and your new credentials to update password.</p>
          </div>

          <form onSubmit={handleResetSubmit} className="space-y-4">
            <div className="space-y-1">
              <label className="block text-[10px] text-gray-500 uppercase tracking-wider font-bold">Verification OTP (4-digit)</label>
              <div className="relative">
                <Key className="absolute left-3.5 top-3 w-4 h-4 text-gray-500" />
                <input type="text" value={resetOtp} onChange={e => setResetOtp(e.target.value)}
                  className="w-full bg-[#0B121E] border border-white/10 rounded-xl pl-11 pr-4 py-2.5 text-xs text-white focus:outline-none focus:border-gainGreen"
                  placeholder="e.g. 4821"
                />
              </div>
            </div>

            <div className="space-y-1">
              <label className="block text-[10px] text-gray-500 uppercase tracking-wider font-bold">New Password</label>
              <div className="relative">
                <Lock className="absolute left-3.5 top-3 w-4 h-4 text-gray-500" />
                <input type="password" value={resetPassword} onChange={e => setResetPassword(e.target.value)}
                  className="w-full bg-[#0B121E] border border-white/10 rounded-xl pl-11 pr-4 py-2.5 text-xs text-white focus:outline-none focus:border-gainGreen"
                  placeholder="••••••••"
                />
              </div>
            </div>

            <button type="submit"
              className="w-full py-3 bg-gainGreen text-black font-extrabold rounded-xl hover:bg-gainGreen/90 transition-all text-xs uppercase tracking-wider shadow-lg shadow-gainGreen/10">
              Confirm Reset Password
            </button>
          </form>
        </div>
      </div>
    );
  }

  if (currentScreen === 'RISK_QUIZ') {
    const q1Options = [
      'Preserve Capital & Earn Fixed Returns',
      'Balance Capital Growth with Income Stability',
      'Maximize Long-Term Gains Aggressively'
    ];
    const q2Options = [
      'Panic and liquidate all simulated holdings immediately',
      'Hold positions and wait for recovery',
      'View it as a discount and buy the dip'
    ];
    const q3Options = [
      'Short term (< 1 Year)',
      'Medium term (1-5 Years)',
      'Long term (5+ Years)'
    ];

    // quizSubmitAlert and finalProfile states are declared at top level

    const handleQuizAnalyze = () => {
      if (quizQ1 === -1 || quizQ2 === -1 || quizQ3 === -1) {
        addToast('Please answer all 3 questions to evaluate your profile', 'error');
        return;
      }
      const score = quizQ1 + quizQ2 + quizQ3;
      let calculatedProfile = 'moderate';
      if (score <= 2) {
        calculatedProfile = 'low';
      } else if (score >= 5) {
        calculatedProfile = 'high';
      }
      setRiskProfile(calculatedProfile);
      setFinalProfile(calculatedProfile);
      setQuizSubmitAlert(true);
    };

    return (
      <div className="min-h-screen bg-[#0B121E] text-white flex flex-col items-center justify-center p-6 font-sans antialiased">
        <Toast toasts={toasts} remove={removeToast} />
        <div className="w-full max-w-lg bg-[#141F32] border border-white/5 rounded-3xl p-8 shadow-2xl space-y-6">
          <div className="space-y-1">
            <h2 className="text-2xl font-extrabold font-outfit">AI Onboarding Quiz</h2>
            <p className="text-xs text-gray-400">Answer these 3 simple questions so TradeMentor AI can optimize your risk model.</p>
          </div>

          <div className="space-y-4 max-h-[60vh] overflow-y-auto pr-1">
            {/* Q1 */}
            <div className="bg-[#0B121E] p-4 rounded-xl border border-white/5 space-y-2">
              <span className="text-[10px] text-gainGreen font-bold bg-gainGreen/10 px-2 py-0.5 rounded">Q1</span>
              <p className="text-xs font-bold">What is your primary investment goal?</p>
              <div className="space-y-2">
                {q1Options.map((opt, i) => (
                  <button key={i} onClick={() => setQuizQ1(i)}
                    className={`w-full text-left p-3 rounded-lg border text-xs transition-all
                      ${quizQ1 === i ? 'border-gainGreen bg-gainGreen/5 text-gainGreen' : 'border-white/5 bg-[#141F32] text-gray-400 hover:text-white'}`}>
                    {opt}
                  </button>
                ))}
              </div>
            </div>

            {/* Q2 */}
            <div className="bg-[#0B121E] p-4 rounded-xl border border-white/5 space-y-2">
              <span className="text-[10px] text-gainGreen font-bold bg-gainGreen/10 px-2 py-0.5 rounded">Q2</span>
              <p className="text-xs font-bold">How do you react if your portfolio drops by 15%?</p>
              <div className="space-y-2">
                {q2Options.map((opt, i) => (
                  <button key={i} onClick={() => setQuizQ2(i)}
                    className={`w-full text-left p-3 rounded-lg border text-xs transition-all
                      ${quizQ2 === i ? 'border-gainGreen bg-gainGreen/5 text-gainGreen' : 'border-white/5 bg-[#141F32] text-gray-400 hover:text-white'}`}>
                    {opt}
                  </button>
                ))}
              </div>
            </div>

            {/* Q3 */}
            <div className="bg-[#0B121E] p-4 rounded-xl border border-white/5 space-y-2">
              <span className="text-[10px] text-gainGreen font-bold bg-gainGreen/10 px-2 py-0.5 rounded">Q3</span>
              <p className="text-xs font-bold">What is your planned investment horizon?</p>
              <div className="space-y-2">
                {q3Options.map((opt, i) => (
                  <button key={i} onClick={() => setQuizQ3(i)}
                    className={`w-full text-left p-3 rounded-lg border text-xs transition-all
                      ${quizQ3 === i ? 'border-gainGreen bg-gainGreen/5 text-gainGreen' : 'border-white/5 bg-[#141F32] text-gray-400 hover:text-white'}`}>
                    {opt}
                  </button>
                ))}
              </div>
            </div>
          </div>

          <button onClick={handleQuizAnalyze}
            className="w-full py-3 bg-gainGreen text-black font-extrabold rounded-xl hover:bg-gainGreen/90 transition-all text-xs uppercase tracking-wider shadow-lg shadow-gainGreen/10">
            Analyze My Risk Profile
          </button>
        </div>

        {/* Calculated Profile Alert Popup */}
        {quizSubmitAlert && (
          <div className="fixed inset-0 z-[160] flex items-center justify-center p-4 bg-black/85 backdrop-blur-sm">
            <div className="bg-[#141F32] border border-white/10 rounded-2xl w-full max-w-sm shadow-2xl p-6 text-center space-y-4 animate-scaleUp">
              <div className="mx-auto w-12 h-12 rounded-full bg-gainGreen/10 border border-gainGreen/20 flex items-center justify-center">
                <Shield className="w-6 h-6 text-gainGreen" />
              </div>
              <h3 className="font-extrabold text-base text-white">Quiz Completed!</h3>
              <div className="p-3 bg-[#0B121E] rounded-xl border border-white/5 text-xs">
                TradeMentor AI has calculated your risk profile:
                <strong className="text-sm text-gainGreen block mt-1 uppercase tracking-wider">{finalProfile} Risk Tolerance</strong>
              </div>
              <p className="text-[11px] text-gray-500 leading-relaxed">
                The AI Trading Assistant will default its stock allocation models and technical scanner suggestions based on this profile.
              </p>
              <button onClick={() => {
                setQuizSubmitAlert(false);
                sessionStorage.setItem('tm_logged_in', 'true');
                setCurrentScreen('DASHBOARD');
                addToast('Welcome to TradeMentor dashboard!', 'success');
              }}
                className="w-full py-2.5 bg-gainGreen hover:bg-gainGreen/90 text-black font-bold text-xs rounded-lg transition-all">
                Enter Platform
              </button>
            </div>
          </div>
        )}
      </div>
    );
  }

  // ─── Main Dashboard JSX Render ───────────────────────────────────────────────
  return (
    <div className="min-h-screen bg-[#0B121E] text-white font-sans antialiased pb-20 relative">
      <Toast toasts={toasts} remove={removeToast} />

      {/* ─── Header ─── */}
      <header className="border-b border-white/5 bg-[#141F32]/85 backdrop-blur-xl sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="h-9 w-9 rounded-xl bg-gainGreen/10 flex items-center justify-center border border-gainGreen/20">
              <TrendingUp className="h-5 w-5 text-gainGreen" />
            </div>
            <div>
              <span className="text-lg font-extrabold tracking-tight font-outfit">TradeMentor</span>
              <span className="text-[10px] text-gainGreen border border-gainGreen/30 px-1.5 py-0.5 rounded ml-2 bg-gainGreen/5 font-medium">REAL-TIME SIMULATION</span>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 bg-gainGreen/5 border border-gainGreen/15 rounded-lg text-xs font-semibold text-gainGreen">
              <Wallet className="w-4 h-4" />
              <span>₹{walletBalance.toLocaleString('en-IN', { minimumFractionDigits: 2 })}</span>
            </div>
            <div className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg border text-[11px] font-medium
              ${error ? 'bg-lossRed/10 border-lossRed/20 text-lossRed' : 'bg-gainGreen/5 border-gainGreen/15 text-gainGreen'}`}>
              <span className={`h-1.5 w-1.5 rounded-full ${error ? 'bg-lossRed' : 'bg-gainGreen animate-pulse'}`} />
              {error ? 'API Offline' : 'Server Live'}
            </div>
            <button onClick={() => setShowSettings(!showSettings)}
              className="p-2 hover:bg-white/5 rounded-lg text-gray-400 hover:text-white transition-all border border-transparent hover:border-white/5">
              <Settings className="h-4 w-4" />
            </button>
            <button onClick={() => {
                sessionStorage.removeItem('tm_logged_in');
                setCurrentScreen('LOGIN');
                setUserId(null);
                addToast('Signed out successfully', 'info');
              }}
              className="px-3 py-1.5 hover:bg-lossRed/10 rounded-lg text-xs font-semibold text-lossRed transition-all border border-lossRed/20 ml-2">
              Sign Out
            </button>
          </div>
        </div>

        {/* Configuration settings form is now handled by the settings overlay modal */}

        {/* ─── Navigation tabs ─── */}
        <div className="max-w-7xl mx-auto px-4 sm:px-6">
          <div className="flex gap-1 overflow-x-auto scrollbar-none">
            {TABS.map(tab => {
              const Icon = tab.icon;
              return (
                <button key={tab.id} onClick={() => setActiveTab(tab.id)}
                  className={`flex items-center gap-2 px-4 py-3 text-sm font-semibold border-b-2 transition-all whitespace-nowrap
                    ${activeTab === tab.id
                      ? 'border-gainGreen text-gainGreen bg-gainGreen/5'
                      : 'border-transparent text-gray-400 hover:text-white hover:border-white/20'}`}
                >
                  <Icon className="w-4 h-4" />
                  <span>{tab.label}</span>
                </button>
              );
            })}
          </div>
        </div>
      </header>

      {/* ─── Error Alert Banner ─── */}
      {error && (
        <div className="bg-lossRed/10 border-b border-lossRed/20 px-4 py-3 flex items-center gap-3 text-sm max-w-7xl mx-auto mt-4 rounded-xl">
          <AlertTriangle className="h-4 w-4 text-lossRed shrink-0" />
          <span className="text-lossRed font-medium">{error}</span>
          <button onClick={() => setShowSettings(true)} className="ml-auto text-gainGreen text-xs font-semibold underline">Configure Host IP</button>
        </div>
      )}

      {/* ─── Main Content Canvas ─── */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 py-6">

        {/* ══════════════ 1. MARKETS PAGE (Multiple Views) ══════════════ */}
        {activeTab === 'markets' && (
          <div className="space-y-6 animate-fadeIn">
            {/* Indices cards */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div className="p-5 rounded-2xl bg-gradient-to-br from-[#141F32] to-[#0B121E] border border-white/5 relative overflow-hidden group">
                <div className="absolute right-0 bottom-0 opacity-10 translate-x-4 translate-y-4">
                  <Wallet className="w-36 h-36" />
                </div>
                <p className="text-[10px] text-gray-400 font-bold uppercase tracking-wider mb-1">Simulated Wallet Balance</p>
                <p className="text-2xl font-extrabold font-outfit text-gainGreen">₹{walletBalance.toLocaleString('en-IN', { minimumFractionDigits: 2 })}</p>
                <p className="text-[10px] text-gray-500 mt-2 flex items-center gap-1">
                  <span className="h-1.5 w-1.5 bg-gainGreen rounded-full" /> Dynamic Paper Trading Account
                </p>
              </div>

              {indices.map(idx => {
                const hist = priceHistory[idx.symbol] || [];
                const pos = idx.pChange >= 0;
                return (
                  <div key={idx.symbol} className="p-5 rounded-2xl bg-[#141F32] border border-white/5 hover:border-white/10 transition-colors">
                    <div className="flex items-center justify-between mb-1">
                      <span className="text-xs text-gray-400 font-extrabold tracking-wider">{idx.symbol}</span>
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-md flex items-center gap-1
                        ${pos ? 'bg-gainGreen/10 text-gainGreen' : 'bg-lossRed/10 text-lossRed'}`}>
                        {pos ? '+' : ''}{idx.pChange.toFixed(2)}%
                      </span>
                    </div>
                    <p className="text-xl font-bold font-outfit">₹{idx.currentPrice.toLocaleString('en-IN', { minimumFractionDigits: 2 })}</p>
                    <div className="mt-3 h-8"><Sparkline history={hist} isPositive={pos} /></div>
                  </div>
                );
              })}
            </div>

            {/* Sub navigation bar */}
            <div className="border-b border-white/5 flex gap-4">
              {['watchlist', 'scanners', 'sectors'].map(sub => (
                <button key={sub} onClick={() => setMarketSubTab(sub)}
                  className={`py-2 text-xs font-bold uppercase tracking-wider border-b-2 transition-all
                    ${marketSubTab === sub ? 'border-gainGreen text-white' : 'border-transparent text-gray-500 hover:text-white'}`}
                >
                  {sub}
                </button>
              ))}
            </div>

            {/* VIEW A: WATCHLIST TABLE */}
            {marketSubTab === 'watchlist' && (
              <div className="space-y-4">
                {/* Sector Filter pills */}
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="text-xs text-gray-500 font-medium">Filter Sector:</span>
                  {sectors.map(s => (
                    <button key={s} onClick={() => setSectorFilter(s)}
                      className={`px-3 py-1 rounded-full text-xs font-bold transition-all border
                        ${sectorFilter === s
                          ? 'bg-gainGreen text-black border-gainGreen'
                          : 'border-white/10 text-gray-400 hover:text-white'}`}
                    >{s}</button>
                  ))}
                </div>

                <div className="rounded-2xl bg-[#141F32] border border-white/5 overflow-hidden">
                  <div className="overflow-x-auto">
                    <table className="w-full text-left">
                      <thead>
                        <tr className="text-[10px] text-gray-500 uppercase tracking-wider border-b border-white/5">
                          <th className="px-5 py-3.5">Symbol</th>
                          <th className="px-5 py-3.5 hidden md:table-cell">Company</th>
                          <th className="px-5 py-3.5 hidden lg:table-cell">Sector</th>
                          <th className="px-5 py-3.5 text-right">Market Price</th>
                          <th className="px-5 py-3.5 text-right">Change</th>
                          <th className="px-5 py-3.5 text-center hidden sm:table-cell">Trend</th>
                          <th className="px-5 py-3.5 text-center">Details</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-white/5">
                        {filteredStocks.map(stock => {
                          const pos = stock.pChange >= 0;
                          const hist = priceHistory[stock.symbol] || [];
                          return (
                            <tr key={stock.symbol} className="hover:bg-white/[0.02] transition-colors group">
                              <td className="px-5 py-4">
                                <div className="flex items-center gap-2.5">
                                  <div className="w-8 h-8 rounded-lg bg-gainGreen/10 flex items-center justify-center text-gainGreen font-extrabold text-xs">
                                    {stock.symbol.slice(0, 2)}
                                  </div>
                                  <span className="font-extrabold text-sm text-white">{stock.symbol}</span>
                                </div>
                              </td>
                              <td className="px-5 py-4 hidden md:table-cell text-xs text-gray-400 max-w-[200px] truncate">{stock.name}</td>
                              <td className="px-5 py-4 hidden lg:table-cell">
                                <span className="text-[10px] px-2.5 py-0.5 rounded-full bg-white/5 border border-white/5 text-gray-400">{stock.sector}</span>
                              </td>
                              <td className="px-5 py-4 text-right font-bold tabular-nums">₹{stock.currentPrice.toFixed(2)}</td>
                              <td className={`px-5 py-4 text-right font-bold tabular-nums text-xs ${pos ? 'text-gainGreen' : 'text-lossRed'}`}>
                                {pos ? '+' : ''}{stock.pChange.toFixed(2)}%
                              </td>
                              <td className="px-5 py-4 text-center hidden sm:table-cell">
                                <div className="w-20 inline-block h-6"><Sparkline history={hist} isPositive={pos} /></div>
                              </td>
                              <td className="px-5 py-4 text-center">
                                <button onClick={() => openStockDetails(stock)}
                                  className="px-3 py-1.5 rounded-lg text-xs font-bold border border-gainGreen/30 text-gainGreen hover:bg-gainGreen hover:text-black transition-all">
                                  View
                                </button>
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            )}

            {/* VIEW B: STOCK MARKET SCANNERS */}
            {marketSubTab === 'scanners' && (
              <div className="space-y-6">
                <div className="flex gap-2 border-b border-white/5 pb-2">
                  {['gainers', 'losers', 'volume'].map(type => (
                    <button key={type} onClick={() => setScannerType(type)}
                      className={`px-3 py-1 text-xs rounded-lg font-bold border capitalize transition-all
                        ${scannerType === type ? 'bg-white text-black border-white' : 'border-white/10 text-gray-400 hover:text-white'}`}
                    >
                      {type}
                    </button>
                  ))}
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="p-5 rounded-2xl bg-[#141F32] border border-white/5 space-y-4">
                    <h3 className="font-bold text-sm flex items-center gap-2">
                      <Activity className="w-4 h-4 text-gainGreen" /> Technical Scan Results
                    </h3>
                    <div className="divide-y divide-white/5">
                      {(scannerType === 'gainers' ? gainers : scannerType === 'losers' ? losers : volumeShockers).map(stock => {
                        const pos = stock.pChange >= 0;
                        return (
                          <div key={stock.symbol} onClick={() => openStockDetails(stock)} className="py-3 flex items-center justify-between cursor-pointer hover:bg-white/[0.01] px-2 rounded-lg transition-all">
                            <div>
                              <p className="font-extrabold text-xs">{stock.symbol}</p>
                              <p className="text-[10px] text-gray-500">{stock.name}</p>
                            </div>
                            <div className="text-right">
                              <p className="font-bold text-xs">₹{stock.currentPrice.toFixed(2)}</p>
                              <p className={`text-[10px] font-bold ${pos ? 'text-gainGreen' : 'text-lossRed'}`}>
                                {pos ? '+' : ''}{stock.pChange.toFixed(2)}%
                              </p>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>

                  <div className="p-5 rounded-2xl bg-[#141F32] border border-white/5 flex flex-col justify-between">
                    <div>
                      <h3 className="font-bold text-sm flex items-center gap-2 mb-3">
                        <Shield className="w-4 h-4 text-gainGreen" /> Scanner Logic Summary
                      </h3>
                      <p className="text-xs text-gray-400 leading-relaxed">
                        These dynamic scanners process tick calculations directly from the DB. They isolate equities showing volatility triggers over the past 24 hours. Use the technical breakout triggers to establish limit orders or buy rules on corrective dips.
                      </p>
                    </div>
                    <div className="p-4 rounded-xl bg-[#0B121E] border border-white/5 text-xs text-gray-500">
                      💡 **AI Advice**: Aggressive traders should scan volume breakouts, while conservative portfolios should filter moderate corrections in defensive FMCG stocks.
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* VIEW C: SECTORS constituent list */}
            {marketSubTab === 'sectors' && (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {SECTORS_LIST.map(sec => {
                  const constituents = stocks.filter(s => s.sector === sec.name);
                  const avgPrice = constituents.length > 0
                    ? constituents.reduce((acc, curr) => acc + curr.currentPrice, 0) / constituents.length
                    : 0;
                  return (
                    <div key={sec.name} className="p-5 rounded-2xl bg-[#141F32] border border-white/5 flex flex-col justify-between">
                      <div>
                        <div className="flex items-center justify-between mb-3">
                          <span className="font-bold text-sm">{sec.name} Sector</span>
                          <span className={`text-[9px] px-2 py-0.5 rounded-full font-bold border ${sec.color}`}>{sec.code}</span>
                        </div>
                        <p className="text-[10px] text-gray-500">Constituents ({constituents.length} stocks):</p>
                        <div className="mt-2 flex flex-wrap gap-1.5">
                          {constituents.map(c => (
                            <span key={c.symbol} onClick={() => openStockDetails(c)} className="text-[10px] bg-white/5 hover:bg-gainGreen hover:text-black cursor-pointer px-2 py-0.5 rounded border border-white/5 transition-all">
                              {c.symbol}
                            </span>
                          ))}
                        </div>
                      </div>
                      <div className="mt-5 border-t border-white/5 pt-3 flex justify-between text-xs text-gray-400">
                        <span>Avg Price:</span>
                        <span className="font-bold text-white">₹{avgPrice.toFixed(2)}</span>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        )}

        {/* ══════════════ 2. PORTFOLIO PAGE (Holdings, Wallet & Tax P&L) ══════════════ */}
        {activeTab === 'portfolio' && (
          <div className="space-y-6 animate-fadeIn">
            {portfolio ? (
              <>
                {/* Summary Metrics */}
                <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
                  {[
                    { label: 'Total Invested', value: `₹${portfolio.totalInvested.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`, color: 'text-white', sub: 'Cost basis' },
                    { label: 'Current Value', value: `₹${portfolio.totalCurrentValue.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`, color: 'text-white', sub: 'Mark-to-market' },
                    { label: 'Unrealized P&L', value: `${portfolio.totalUnrealized >= 0 ? '+' : ''}₹${portfolio.totalUnrealized.toFixed(2)}`, color: portfolio.totalUnrealized >= 0 ? 'text-gainGreen' : 'text-lossRed', sub: `${(portfolio.totalUnrealized / (portfolio.totalInvested || 1) * 100).toFixed(2)}% net profit` },
                    { label: 'Realized P&L', value: `${portfolio.totalRealizedPnL >= 0 ? '+' : ''}₹${portfolio.totalRealizedPnL.toFixed(2)}`, color: portfolio.totalRealizedPnL >= 0 ? 'text-gainGreen' : 'text-lossRed', sub: 'Locked profits' },
                  ].map((c, i) => (
                    <div key={i} className="p-5 rounded-2xl bg-[#141F32] border border-white/5">
                      <p className="text-[10px] text-gray-500 uppercase tracking-wider font-semibold mb-1">{c.label}</p>
                      <p className={`text-lg font-extrabold font-outfit ${c.color}`}>{c.value}</p>
                      <p className="text-[10px] text-gray-600 mt-1">{c.sub}</p>
                    </div>
                  ))}
                </div>

                {/* Sub tabs */}
                <div className="border-b border-white/5 flex gap-4">
                  {['holdings', 'wallet', 'tax'].map(sub => (
                    <button key={sub} onClick={() => setPortfolioSubTab(sub)}
                      className={`py-2 text-xs font-bold uppercase tracking-wider border-b-2 transition-all
                        ${portfolioSubTab === sub ? 'border-gainGreen text-white' : 'border-transparent text-gray-500 hover:text-white'}`}
                    >
                      {sub === 'holdings' ? 'Open Positions' : sub === 'wallet' ? 'Wallet Manager' : 'Capital Gains Tax'}
                    </button>
                  ))}
                </div>

                {/* SUB-VIEW 1: OPEN HOLDINGS */}
                {portfolioSubTab === 'holdings' && (
                  portfolio.holdings.length === 0 ? (
                    <div className="py-20 flex flex-col items-center gap-4 bg-[#141F32] rounded-2xl border border-white/5">
                      <PieChart className="w-12 h-12 text-gray-600 animate-pulse" />
                      <p className="text-gray-400 font-semibold">No open holdings</p>
                      <p className="text-xs text-gray-600">Buy simulated shares from the Markets tab to populate your portfolio.</p>
                    </div>
                  ) : (
                    <div className="rounded-2xl bg-[#141F32] border border-white/5 overflow-hidden">
                      <div className="overflow-x-auto">
                        <table className="w-full text-left">
                          <thead>
                            <tr className="text-[10px] text-gray-500 uppercase tracking-wider border-b border-white/5">
                              <th className="px-5 py-3.5">Stock</th>
                              <th className="px-5 py-3.5 text-right">Shares Held</th>
                              <th className="px-5 py-3.5 text-right">Avg Buy Price</th>
                              <th className="px-5 py-3.5 text-right">Market Price</th>
                              <th className="px-5 py-3.5 text-right">Invested Value</th>
                              <th className="px-5 py-3.5 text-right">Current Value</th>
                              <th className="px-5 py-3.5 text-right">Net Profit / Loss</th>
                              <th className="px-5 py-3.5 text-center">Actions</th>
                            </tr>
                          </thead>
                          <tbody className="divide-y divide-white/5">
                            {portfolio.holdings.map(h => (
                              <tr key={h.symbol} className="hover:bg-white/[0.01] transition-colors">
                                <td className="px-5 py-4">
                                  <div className="flex items-center gap-2">
                                    <span className="font-extrabold text-sm">{h.symbol}</span>
                                    <span className="text-[9px] text-gray-500 bg-white/5 px-1.5 py-0.5 rounded">{h.exchange}</span>
                                  </div>
                                </td>
                                <td className="px-5 py-4 text-right font-bold">{h.quantity}</td>
                                <td className="px-5 py-4 text-right text-gray-400">₹{h.averageBuyPrice.toFixed(2)}</td>
                                <td className="px-5 py-4 text-right font-bold">₹{h.currentPrice.toFixed(2)}</td>
                                <td className="px-5 py-4 text-right text-gray-400">₹{h.totalInvested.toFixed(2)}</td>
                                <td className="px-5 py-4 text-right font-bold text-gainGreen">₹{h.currentValue.toFixed(2)}</td>
                                <td className="px-5 py-4 text-right">
                                  <PnlBadge value={h.unrealizedPnL} percent={h.pnlPercent} />
                                </td>
                                <td className="px-5 py-4 text-center">
                                  <button onClick={() => {
                                    const st = stocks.find(s => s.symbol === h.symbol);
                                    if (st) {
                                      openStockDetails(st);
                                      setStockDetailTab('trade');
                                      setTradeModalType('SELL');
                                    }
                                  }}
                                    className="px-3 py-1.5 rounded-lg text-xs font-bold bg-lossRed/10 border border-lossRed/20 text-lossRed hover:bg-lossRed hover:text-white transition-all">
                                    Sell
                                  </button>
                                </td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                    </div>
                  )
                )}

                {/* SUB-VIEW 2: WALLET MANAGER */}
                {portfolioSubTab === 'wallet' && (
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div className="p-5 rounded-2xl bg-[#141F32] border border-white/5 space-y-4">
                      <h3 className="font-bold text-sm flex items-center gap-2 text-gainGreen">
                        <Wallet className="w-4 h-4" /> Deposit Simulated Capital
                      </h3>
                      <form onSubmit={handleDeposit} className="space-y-3">
                        <label className="text-[10px] text-gray-500 uppercase tracking-wider block">Cash Amount (₹)</label>
                        <input type="number" value={walletDepositAmount} onChange={e => setWalletDepositAmount(e.target.value)}
                          className="w-full bg-[#0B121E] border border-white/10 rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:border-gainGreen"
                        />
                        <button type="submit" className="w-full py-2.5 bg-gainGreen text-black font-bold text-xs rounded-xl hover:bg-gainGreen/90 transition-colors">
                          Confirm UPI Deposit
                        </button>
                      </form>
                    </div>

                    <div className="p-5 rounded-2xl bg-[#141F32] border border-white/5 space-y-4">
                      <h3 className="font-bold text-sm flex items-center gap-2 text-lossRed">
                        <Landmark className="w-4 h-4" /> Withdraw to Bank Account
                      </h3>
                      <form onSubmit={handleWithdraw} className="space-y-3">
                        <label className="text-[10px] text-gray-500 uppercase tracking-wider block">Cash Amount (₹)</label>
                        <input type="number" value={walletWithdrawAmount} onChange={e => setWalletWithdrawAmount(e.target.value)}
                          className="w-full bg-[#0B121E] border border-white/10 rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:border-lossRed"
                        />
                        <button type="submit" className="w-full py-2.5 bg-lossRed text-white font-bold text-xs rounded-xl hover:bg-lossRed/90 transition-colors">
                          Confirm Bank Withdrawal
                        </button>
                      </form>
                    </div>

                    {/* Deposit/Withdraw logs list */}
                    <div className="p-5 rounded-2xl bg-[#141F32] border border-white/5 space-y-3">
                      <h3 className="font-bold text-sm">Transfer History Logs</h3>
                      <div className="max-h-[160px] overflow-y-auto space-y-2 pr-1">
                        {walletLogs.map(log => (
                          <div key={log.id} className="p-2.5 rounded-lg bg-[#0B121E] border border-white/5 flex items-center justify-between text-xs">
                            <div>
                              <p className="font-bold">{log.description}</p>
                              <p className="text-[9px] text-gray-600">{new Date(log.date).toLocaleTimeString()}</p>
                            </div>
                            <span className={`font-extrabold ${log.type === 'CREDIT' ? 'text-gainGreen' : 'text-lossRed'}`}>
                              {log.type === 'CREDIT' ? '+' : '-'}₹{log.amount.toLocaleString('en-IN', { maximumFractionDigits: 0 })}
                            </span>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                )}

                {/* SUB-VIEW 3: TAX CAPITAL GAINS REPORT */}
                {portfolioSubTab === 'tax' && (
                  <div className="p-5 rounded-2xl bg-[#141F32] border border-white/5 space-y-4">
                    <h3 className="font-bold text-sm flex items-center gap-2">
                      <FileText className="w-4 h-4 text-gainGreen" /> Capital Gains Tax Breakdown (Indian Income Tax Act)
                    </h3>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                      <div className="p-4 rounded-xl bg-[#0B121E] border border-white/5">
                        <p className="text-[10px] text-gray-500 uppercase font-semibold">Total Realized Profits</p>
                        <p className="text-lg font-bold mt-1 text-white">₹{portfolio.totalRealizedPnL.toFixed(2)}</p>
                      </div>
                      <div className="p-4 rounded-xl bg-[#0B121E] border border-white/5">
                        <p className="text-[10px] text-gray-500 uppercase font-semibold">Est. STCG Tax (15%)</p>
                        <p className="text-lg font-bold mt-1 text-orange-400">
                          ₹{Math.max(0, portfolio.totalRealizedPnL * 0.15).toFixed(2)}
                        </p>
                      </div>
                      <div className="p-4 rounded-xl bg-[#0B121E] border border-white/5">
                        <p className="text-[10px] text-gray-500 uppercase font-semibold">Est. LTCG Tax (10%)</p>
                        <p className="text-lg font-bold mt-1 text-blue-400">
                          ₹{Math.max(0, portfolio.totalRealizedPnL * 0.10).toFixed(2)}
                        </p>
                      </div>
                    </div>
                    <p className="text-[10px] text-gray-500 leading-relaxed bg-[#0B121E] p-3 rounded-lg border border-white/5">
                      ⚠️ **Indian Tax Simulation**: Short-Term Capital Gains (STCG) are taxed at 15% (holding period &lt; 12 months). Long-Term Capital Gains (LTCG) are taxed at 10% on gains exceeding ₹1 Lakh per year (holding period &gt;= 12 months).
                    </p>
                  </div>
                )}
              </>
            ) : (
              <div className="py-20 flex flex-col items-center gap-3">
                <RefreshCw className="w-7 h-7 text-gainGreen animate-spin" />
                <p className="text-sm text-gray-400">Loading portfolio details…</p>
              </div>
            )}
          </div>
        )}

        {/* ══════════════ 3. ALERTS & TRIGGERS PAGE ══════════════ */}
        {activeTab === 'alerts' && (
          <div className="grid grid-cols-1 lg:grid-cols-5 gap-6 animate-fadeIn">
            {/* Deploy rules form */}
            <div className="lg:col-span-2">
              <div className="rounded-2xl bg-[#141F32] border border-white/5 p-5 sticky top-24">
                <h2 className="font-bold font-outfit text-base mb-4 flex items-center gap-2">
                  <Bell className="w-4 h-4 text-gainGreen" /> Deploy Alert Rule
                </h2>
                <form onSubmit={deployAlert} className="space-y-4">
                  <div>
                    <label className="text-[10px] text-gray-500 font-extrabold uppercase block mb-1.5">Pick Equity</label>
                    <select
                      value={alertForm.stockSymbol}
                      onChange={e => {
                        const s = stocks.find(s => s.symbol === e.target.value);
                        setAlertForm(f => ({ ...f, stockSymbol: e.target.value, price: s ? s.currentPrice.toFixed(2) : '' }));
                      }}
                      className="w-full bg-[#0B121E] border border-white/10 rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:border-gainGreen"
                    >
                      <option value="">— Select Stock —</option>
                      {stocks.map(s => <option key={s.symbol} value={s.symbol}>{s.symbol} — ₹{s.currentPrice.toFixed(2)}</option>)}
                    </select>
                  </div>
                  <div>
                    <label className="text-[10px] text-gray-500 font-extrabold uppercase block mb-1.5">Conditional Criteria</label>
                    <select value={alertForm.criteria}
                      onChange={e => setAlertForm(f => ({ ...f, criteria: e.target.value }))}
                      className="w-full bg-[#0B121E] border border-white/10 rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:border-gainGreen"
                    >
                      <option value="GREATER_THAN">Price ≥ target (Breakout)</option>
                      <option value="LESS_THAN">Price ≤ target (Support / Dip)</option>
                      <option value="STOP_LOSS">Stop Loss (Price ≤ target)</option>
                    </select>
                  </div>
                  <div>
                    <label className="text-[10px] text-gray-500 font-extrabold uppercase block mb-1.5">Trigger Threshold Price (₹)</label>
                    <input type="number" step="0.01" value={alertForm.price}
                      onChange={e => setAlertForm(f => ({ ...f, price: e.target.value }))}
                      className="w-full bg-[#0B121E] border border-white/10 rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:border-gainGreen"
                      placeholder="Enter price trigger threshold"
                    />
                  </div>
                  <button type="submit" disabled={!userId || !alertForm.stockSymbol || !alertForm.price}
                    className="w-full py-3 bg-gainGreen text-black text-xs font-extrabold rounded-xl hover:bg-gainGreen/90 disabled:opacity-40 transition-all flex items-center justify-center gap-2">
                    <Zap className="w-4 h-4 animate-pulse" /> Deploy Rule Trigger
                  </button>
                </form>
              </div>
            </div>

            {/* List alert rules */}
            <div className="lg:col-span-3 space-y-4">
              {/* Alert sub-nav */}
              <div className="border-b border-white/5 flex gap-4">
                {['create', 'triggered'].map(type => (
                  <button key={type} onClick={() => setAlertSubTab(type)}
                    className={`py-2 text-xs font-bold uppercase tracking-wider border-b-2 transition-all
                      ${alertSubTab === type ? 'border-gainGreen text-white' : 'border-transparent text-gray-500 hover:text-white'}`}
                  >
                    {type === 'create' ? `Active Rules (${alerts.filter(a => !a.isTriggered).length})` : `Fired Triggers (${alerts.filter(a => a.isTriggered).length})`}
                  </button>
                ))}
              </div>

              {/* Rules matching active subtab */}
              {alerts.filter(a => (alertSubTab === 'create' ? !a.isTriggered : a.isTriggered)).length === 0 ? (
                <div className="py-20 flex flex-col items-center gap-3 bg-[#141F32] rounded-2xl border border-white/5 text-center">
                  <Shield className="w-10 h-10 text-gray-600" />
                  <p className="text-gray-400 font-semibold">No rules in this category</p>
                  <p className="text-xs text-gray-600">Deploy alerts on your favorite equities to trigger custom signals.</p>
                </div>
              ) : (
                <div className="space-y-3">
                  {alerts.filter(a => (alertSubTab === 'create' ? !a.isTriggered : a.isTriggered)).map(alert => {
                    const criteriaLabel = alert.criteria === 'GREATER_THAN' ? '≥' : alert.criteria === 'LESS_THAN' ? '≤' : 'Stop Loss ≤';
                    const color = alert.criteria === 'GREATER_THAN' ? 'text-gainGreen bg-gainGreen/10' : alert.criteria === 'LESS_THAN' ? 'text-lossRed bg-lossRed/10' : 'text-orange-400 bg-orange-500/10';
                    return (
                      <div key={alert._id} className="p-4 rounded-xl border border-white/5 bg-[#141F32] flex items-center justify-between">
                        <div>
                          <div className="flex items-center gap-2">
                            <span className="font-extrabold text-sm">{alert.symbol}</span>
                            <span className={`text-[9px] px-1.5 py-0.5 rounded font-bold uppercase ${color}`}>{criteriaLabel}</span>
                            <span className={`text-[9px] px-2 py-0.5 rounded-full font-bold border
                              ${alert.isTriggered ? 'bg-gainGreen/10 text-gainGreen border-gainGreen/20' : 'bg-orange-500/10 text-orange-400 border-orange-500/20'}`}>
                              {alert.isTriggered ? 'Fired ✓' : 'Active ●'}
                            </span>
                          </div>
                          <p className="text-xs text-gray-400 mt-1">Target Price: <span className="text-white font-bold">₹{alert.targetPrice.toFixed(2)}</span></p>
                          {alert.isTriggered && alert.triggeredAt && (
                            <p className="text-[10px] text-gray-500 mt-1">
                              Fired: {new Date(alert.triggeredAt).toLocaleString('en-IN')}
                            </p>
                          )}
                        </div>
                        <button onClick={() => deleteAlert(alert._id)}
                          className="p-1.5 hover:bg-lossRed/10 rounded-lg text-gray-500 hover:text-lossRed transition-all">
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>
        )}

        {/* ══════════════ 4. AI ADVISOR PAGE (conversational chat, allocations, technical scanners) ══════════════ */}
        {activeTab === 'advisor' && (
          <div className="grid grid-cols-1 lg:grid-cols-5 gap-6 animate-fadeIn">
            {/* Risk profile settings */}
            <div className="lg:col-span-2 space-y-4">
              <div className="p-5 rounded-2xl bg-[#141F32] border border-white/5 space-y-4">
                <h3 className="font-bold text-sm flex items-center gap-2">
                  <User className="w-4 h-4 text-gainGreen" /> AI Risk Profile Classification
                </h3>
                <p className="text-xs text-gray-400 leading-relaxed">
                  Configuring your risk profile allows TradeMentor AI to adjust portfolio allocations suggestions and scanning sensitivity levels.
                </p>

                <div className="flex gap-2">
                  {['low', 'moderate', 'high'].map(p => (
                    <button key={p} onClick={() => { setRiskProfile(p); addToast(`Advisor model set to ${p.toUpperCase()}`, 'success'); }}
                      className={`flex-1 py-2 rounded-lg text-xs font-bold capitalize transition-all border
                        ${riskProfile === p
                          ? 'bg-gainGreen text-black border-gainGreen'
                          : 'border-white/10 text-gray-400 hover:text-white'}`}
                    >
                      {p}
                    </button>
                  ))}
                </div>

                <div className="pt-2">
                  <button onClick={() => setShowRiskQuiz(true)}
                    className="w-full py-2 border border-gainGreen/30 text-gainGreen text-xs font-bold rounded-lg hover:bg-gainGreen/5">
                    Retake AI Risk Quiz
                  </button>
                </div>
              </div>

              {/* Quick AI scanners */}
              <div className="p-5 rounded-2xl bg-[#141F32] border border-white/5 space-y-4">
                <h3 className="font-bold text-sm">Quick AI Command Scans</h3>
                <div className="grid grid-cols-1 gap-2">
                  {[
                    { label: 'Run Market Scanner', text: 'Run a market scanner' },
                    { label: 'Show high-risk allocations', text: 'how should I allocate a high-risk portfolio?' },
                    { label: 'Compare RELIANCE and TCS', text: 'compare RELIANCE and TCS' },
                    { label: 'Explain RSI technical indicator', text: 'what is RSI?' }
                  ].map((preset, i) => (
                    <button key={i} onClick={() => sendChatMessage(preset.text)}
                      className="w-full text-left px-3 py-2 rounded-lg bg-[#0B121E] hover:bg-[#0B121E]/80 border border-white/5 text-xs text-gray-400 hover:text-white transition-colors">
                      {preset.label}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Chatbot Interface */}
            <div className="lg:col-span-3">
              <div className="rounded-2xl bg-[#141F32] border border-white/5 flex flex-col h-[500px]">
                <div className="px-5 py-4 border-b border-white/5 flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Sparkles className="w-5 h-5 text-gainGreen animate-pulse" />
                    <div>
                      <h3 className="font-bold text-sm">TradeMentor AI Advisor</h3>
                      <p className="text-[10px] text-gray-500">Offline NLP Engine</p>
                    </div>
                  </div>
                  <span className="text-[9px] bg-gainGreen/10 text-gainGreen border border-gainGreen/20 px-2 py-0.5 rounded-full font-bold">READY</span>
                </div>

                {/* Messages Body */}
                <div className="flex-1 overflow-y-auto p-5 space-y-4">
                  {aiChatMessages.map((msg, i) => (
                    <div key={i} className={`flex ${msg.sender === 'user' ? 'justify-end' : 'justify-start'}`}>
                      <div className={`p-3.5 rounded-2xl text-xs max-w-sm whitespace-pre-line leading-relaxed
                        ${msg.sender === 'user'
                          ? 'bg-gainGreen text-black rounded-tr-none font-semibold'
                          : 'bg-[#0B121E] border border-white/5 text-white rounded-tl-none'}`}
                      >
                        {msg.text}
                      </div>
                    </div>
                  ))}
                  {aiLoading && (
                    <div className="flex justify-start">
                      <div className="p-3 bg-[#0B121E] border border-white/5 rounded-2xl rounded-tl-none flex items-center gap-2 text-xs text-gray-400">
                        <RefreshCw className="w-3.5 h-3.5 animate-spin text-gainGreen" /> AI is scanning database ticks…
                      </div>
                    </div>
                  )}
                  <div ref={chatBottomRef} />
                </div>

                {/* Message input */}
                <form onSubmit={(e) => { e.preventDefault(); sendChatMessage(); }} className="p-4 border-t border-white/5 flex gap-2">
                  <input type="text" value={aiInput} onChange={e => setAiInput(e.target.value)}
                    placeholder="Ask AI (e.g. 'Is INFY a buy?', 'PE ratio definition')"
                    className="flex-1 bg-[#0B121E] border border-white/10 rounded-xl px-4 py-3 text-xs focus:outline-none focus:border-gainGreen"
                  />
                  <button type="submit" disabled={aiLoading || !aiInput.trim()}
                    className="px-4 py-3 bg-gainGreen text-black rounded-xl hover:bg-gainGreen/90 disabled:opacity-40 transition-all">
                    <Send className="w-4 h-4" />
                  </button>
                </form>
              </div>
            </div>
          </div>
        )}

        {/* ══════════════ 5. HISTORY PAGE (Trade Ledger) ══════════════ */}
        {activeTab === 'history' && (
          <div className="space-y-4 animate-fadeIn">
            <div className="flex items-center justify-between">
              <h2 className="font-bold font-outfit text-base">Trade Ledger records</h2>
              <button onClick={fetchTrades} className="p-1.5 hover:bg-white/5 rounded-lg text-gray-400 hover:text-white transition-all border border-white/5">
                <RefreshCw className="w-4 h-4" />
              </button>
            </div>

            {trades.length === 0 ? (
              <div className="py-20 flex flex-col items-center gap-3 bg-[#141F32] rounded-2xl border border-white/5">
                <BookOpen className="w-12 h-12 text-gray-600" />
                <p className="text-gray-400 font-semibold">No transactions found</p>
                <p className="text-xs text-gray-600">Your simulated trades ledger will be listed here.</p>
              </div>
            ) : (
              <div className="rounded-2xl bg-[#141F32] border border-white/5 overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full text-left">
                    <thead>
                      <tr className="text-[10px] text-gray-500 uppercase tracking-wider border-b border-white/5">
                        <th className="px-5 py-3.5">Type</th>
                        <th className="px-5 py-3.5">Stock</th>
                        <th className="px-5 py-3.5 text-right">Qty</th>
                        <th className="px-5 py-3.5 text-right">Price</th>
                        <th className="px-5 py-3.5 text-right">Total Value</th>
                        <th className="px-5 py-3.5 text-right">Realized P&L</th>
                        <th className="px-5 py-3.5 text-right hidden md:table-cell">Date &amp; Time</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-white/5">
                      {trades.map(t => (
                        <tr key={t._id} className="hover:bg-white/[0.01] transition-colors">
                          <td className="px-5 py-4">
                            <span className={`px-2.5 py-1 rounded-lg text-[10px] font-bold
                              ${t.type === 'BUY' ? 'bg-gainGreen/10 text-gainGreen border border-gainGreen/20' : 'bg-lossRed/10 text-lossRed border border-lossRed/20'}`}>
                              {t.type}
                            </span>
                          </td>
                          <td className="px-5 py-4">
                            <p className="font-extrabold text-sm">{t.symbol}</p>
                            <p className="text-[10px] text-gray-500 truncate max-w-[150px]">{t.stockName}</p>
                          </td>
                          <td className="px-5 py-4 text-right font-bold tabular-nums">{t.quantity}</td>
                          <td className="px-5 py-4 text-right tabular-nums">₹{t.price.toFixed(2)}</td>
                          <td className="px-5 py-4 text-right font-bold tabular-nums">₹{t.totalValue.toFixed(2)}</td>
                          <td className="px-5 py-4 text-right">
                            {t.realizedPnL !== null ? (
                              <span className={`font-bold tabular-nums text-xs ${t.realizedPnL >= 0 ? 'text-gainGreen' : 'text-lossRed'}`}>
                                {t.realizedPnL >= 0 ? '+' : ''}₹{t.realizedPnL.toFixed(2)}
                              </span>
                            ) : <span className="text-gray-600 text-xs">—</span>}
                          </td>
                          <td className="px-5 py-4 text-right text-[10px] text-gray-500 hidden md:table-cell">
                            {new Date(t.createdAt).toLocaleString('en-IN', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                <div className="px-5 py-3.5 border-t border-white/5 text-[10px] text-gray-500 flex items-center justify-between bg-white/[0.01]">
                  <span>Auditing {trades.length} historical ledger entries</span>
                  <span className="text-gainGreen font-bold">
                    Net Ledger Yield: {trades.reduce((s, t) => s + (t.realizedPnL || 0), 0) >= 0 ? '+' : ''}
                    ₹{trades.reduce((s, t) => s + (t.realizedPnL || 0), 0).toFixed(2)}
                  </span>
                </div>
              </div>
            )}
          </div>
        )}

        {/* ══════════════ 6. ACADEMY PAGE (Trading Tutorials & Glossary) ══════════════ */}
        {activeTab === 'academy' && (
          <div className="space-y-6 animate-fadeIn">
            {/* Sub navigation */}
            <div className="border-b border-white/5 flex gap-4">
              {['tutorials', 'glossary'].map(sub => (
                <button key={sub} onClick={() => setAcademySubTab(sub)}
                  className={`py-2 text-xs font-bold uppercase tracking-wider border-b-2 transition-all
                    ${academySubTab === sub ? 'border-gainGreen text-white' : 'border-transparent text-gray-500 hover:text-white'}`}
                >
                  {sub === 'tutorials' ? 'Trading Academy Modules' : 'Financial Dictionary'}
                </button>
              ))}
            </div>

            {/* VIEW 1: TUTORIAL MODULES */}
            {academySubTab === 'tutorials' && (
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                {[
                  { title: 'Level 1: Market Basics', level: 'Beginner', desc: 'Learn how the Indian Stock Exchanges (NSE & BSE) process orders, what stock price bid/asks are, and the difference between cash equity and derivatives.', color: 'border-blue-500/20 text-blue-400 bg-blue-500/5' },
                  { title: 'Level 2: Technical Indicators', level: 'Intermediate', desc: 'Understanding charts trend lines, Moving Averages (SMA/EMA), Relative Strength Index (RSI) for overbought detection, and MACD indicators.', color: 'border-purple-500/20 text-purple-400 bg-purple-500/5' },
                  { title: 'Level 3: Rule-Based Stop Losses', level: 'Advanced', desc: 'Master trailing stop loss orders, breakout trigger deployment, portfolio rebalancing models, and risk management ratios.', color: 'border-orange-500/20 text-orange-400 bg-orange-500/5' }
                ].map((mod, i) => (
                  <div key={i} className={`p-5 rounded-2xl border ${mod.color} flex flex-col justify-between`}>
                    <div>
                      <span className="text-[10px] uppercase font-bold tracking-widest block opacity-60">{mod.level} Module</span>
                      <h3 className="font-extrabold text-sm text-white mt-1.5 mb-3">{mod.title}</h3>
                      <p className="text-xs text-gray-400 leading-relaxed">{mod.desc}</p>
                    </div>
                    <button onClick={() => addToast(`Initializing '${mod.title}' study materials…`, 'info')}
                      className="mt-6 w-full py-2.5 rounded-xl border border-white/10 text-white font-bold text-xs hover:bg-white/5 transition-all">
                      Start Learning
                    </button>
                  </div>
                ))}
              </div>
            )}

            {/* VIEW 2: GLOSSARY SEARCH */}
            {academySubTab === 'glossary' && (
              <div className="p-5 rounded-2xl bg-[#141F32] border border-white/5 space-y-4">
                <h3 className="font-bold text-sm">Financial Terms Glossary</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {[
                    { term: 'P/E Ratio', def: 'Price-to-Earnings Ratio. Measures stock share price relative to EPS.' },
                    { term: 'Stop Loss Order', def: 'Automatic order deployed to close a stock position once price hits a risk ceiling.' },
                    { term: 'RSI Momentum', def: 'Relative Strength Index. Momentum scale indicating oversold/overbought states.' },
                    { term: 'Capital Gains', def: 'Realized profits taxed under STCG (15%) or LTCG (10%) rules.' }
                  ].map((item, i) => (
                    <div key={i} className="p-3 bg-[#0B121E] border border-white/5 rounded-xl text-xs space-y-1">
                      <p className="font-bold text-gainGreen">{item.term}</p>
                      <p className="text-gray-400">{item.def}</p>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}
      </main>

      {/* ══════════════ FLOATING AI ASSISTANT DRAWER (Persistent) ══════════════ */}
      <div className="fixed bottom-6 right-6 z-[90] flex flex-col items-end">
        {floatingAiOpen ? (
          <div className="bg-[#141F32] border border-white/10 rounded-2xl w-80 shadow-2xl flex flex-col h-96 mb-3 animate-fadeIn">
            <div className="px-4 py-3 border-b border-white/5 bg-[#0B121E]/50 flex items-center justify-between rounded-t-2xl">
              <div className="flex items-center gap-1.5">
                <Sparkles className="w-4 h-4 text-gainGreen animate-pulse" />
                <span className="text-xs font-bold">TradeMentor AI Support</span>
              </div>
              <button onClick={() => setFloatingAiOpen(false)} className="p-1 hover:bg-white/5 rounded">
                <X className="w-4 h-4 text-gray-400" />
              </button>
            </div>

            {/* Message window */}
            <div className="flex-1 overflow-y-auto p-4 space-y-3 scrollbar-thin">
              {aiChatMessages.map((msg, i) => (
                <div key={i} className={`flex ${msg.sender === 'user' ? 'justify-end' : 'justify-start'}`}>
                  <div className={`p-2.5 rounded-xl text-[11px] max-w-[220px] whitespace-pre-line leading-relaxed
                    ${msg.sender === 'user'
                      ? 'bg-gainGreen text-black font-semibold rounded-tr-none'
                      : 'bg-[#0B121E] border border-white/5 text-white rounded-tl-none'}`}
                  >
                    {msg.text}
                  </div>
                </div>
              ))}
              {aiLoading && (
                <p className="text-[10px] text-gray-500 italic">Scanning stock ticks…</p>
              )}
            </div>

            {/* Chat form */}
            <form onSubmit={(e) => { e.preventDefault(); sendChatMessage(); }} className="p-3 border-t border-white/5 flex gap-1.5 bg-[#0B121E]/30">
              <input type="text" value={aiInput} onChange={e => setAiInput(e.target.value)}
                placeholder="Ask TradeMentor AI..."
                className="flex-1 bg-[#0B121E] border border-white/10 rounded-lg px-2.5 py-2 text-[11px] focus:outline-none"
              />
              <button type="submit" disabled={aiLoading || !aiInput.trim()}
                className="px-3 py-2 bg-gainGreen text-black rounded-lg text-xs font-bold hover:bg-gainGreen/90">
                Send
              </button>
            </form>
          </div>
        ) : null}

        <button onClick={() => setFloatingAiOpen(!floatingAiOpen)}
          className="bg-gainGreen hover:bg-gainGreen/95 text-black p-3.5 rounded-full shadow-2xl transition-all border border-gainGreen/20 flex items-center gap-1.5 group">
          <Sparkles className="w-5 h-5 animate-pulse" />
          <span className="max-w-0 overflow-hidden group-hover:max-w-xs transition-all duration-300 ease-out font-bold text-xs">AI Chat</span>
        </button>
      </div>

      {/* ══════════════ STOCK DETAILS MODAL (10 Sub-tabs) ══════════════ */}
      {selectedStock && (
        <div className="fixed inset-0 z-[110] flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm" onClick={() => setSelectedStock(null)}>
          <div className="bg-[#141F32] border border-white/10 rounded-2xl w-full max-w-xl shadow-2xl flex flex-col max-h-[90vh]" onClick={e => e.stopPropagation()}>
            
            {/* Header info */}
            <div className="p-5 border-b border-white/5 flex items-start justify-between">
              <div>
                <h3 className="font-extrabold text-lg flex items-center gap-2">
                  {selectedStock.symbol}
                  <span className="text-[10px] bg-white/5 px-2 py-0.5 rounded text-gray-400 font-normal">{selectedStock.exchange}</span>
                </h3>
                <p className="text-xs text-gray-400 mt-0.5">{selectedStock.name}</p>
              </div>
              <button onClick={() => setSelectedStock(null)} className="p-1.5 hover:bg-white/5 rounded-lg">
                <X className="w-4 h-4 text-gray-400" />
              </button>
            </div>

            {/* Price section */}
            <div className="px-5 py-3 bg-white/[0.01] flex items-center justify-between text-xs border-b border-white/5">
              <div>
                <span className="text-gray-500 font-semibold uppercase text-[9px] tracking-wider block">Live LTP</span>
                <span className="text-lg font-bold tabular-nums">₹{selectedStock.currentPrice.toFixed(2)}</span>
              </div>
              <div className="text-right">
                <span className="text-gray-500 font-semibold uppercase text-[9px] tracking-wider block">Today\'s change</span>
                <span className={`font-bold tabular-nums text-sm ${selectedStock.pChange >= 0 ? 'text-gainGreen' : 'text-lossRed'}`}>
                  {selectedStock.pChange >= 0 ? '+' : ''}{selectedStock.pChange.toFixed(2)}%
                </span>
              </div>
            </div>

            {/* Modal Subtabs */}
            <div className="border-b border-white/5 px-5 flex gap-3 overflow-x-auto scrollbar-none py-1 bg-[#0B121E]/10">
              {[
                { id: 'chart', label: 'Chart' },
                { id: 'fundamentals', label: 'Analysis' },
                { id: 'financials', label: 'P&L statements' },
                { id: 'shareholder', label: 'Holdings' },
                { id: 'peers', label: 'Peers' },
                { id: 'news', label: 'Sentiment' },
                { id: 'trade', label: 'ORDER TICKET' }
              ].map(sub => (
                <button key={sub.id} onClick={() => setStockDetailTab(sub.id)}
                  className={`py-2 text-[10px] uppercase font-bold tracking-wider whitespace-nowrap border-b-2 transition-all
                    ${stockDetailTab === sub.id ? 'border-gainGreen text-gainGreen' : 'border-transparent text-gray-500 hover:text-white'}`}
                >
                  {sub.label}
                </button>
              ))}
            </div>

            {/* Modal Body Container */}
            <div className="flex-1 overflow-y-auto p-5 space-y-4">
              
              {/* SUBTAB 1: LIVE CHART */}
              {stockDetailTab === 'chart' && (
                <div className="space-y-4">
                  <div className="h-44 w-full bg-[#0B121E] border border-white/5 rounded-xl p-4 flex flex-col justify-between">
                    <div className="h-28 flex items-end">
                      <Sparkline history={priceHistory[selectedStock.symbol] || []} isPositive={selectedStock.pChange >= 0} width={450} height={100} />
                    </div>
                    <div className="flex justify-between text-[9px] text-gray-600 border-t border-white/5 pt-1">
                      <span>Live 5s Quotes Feed</span>
                      <span>Tick buffer: { (priceHistory[selectedStock.symbol] || []).length } / 20</span>
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-2 text-xs">
                    <div className="p-3 bg-[#0B121E] border border-white/5 rounded-lg">
                      <span className="text-[10px] text-gray-500 block">Today\'s Open</span>
                      <span className="font-bold text-white">₹{selectedStock.openPrice.toFixed(2)}</span>
                    </div>
                    <div className="p-3 bg-[#0B121E] border border-white/5 rounded-lg">
                      <span className="text-[10px] text-gray-500 block">Sector Industry</span>
                      <span className="font-bold text-white">{selectedStock.sector}</span>
                    </div>
                  </div>
                </div>
              )}

              {/* SUBTAB 2: STOCK ANALYSIS FUNDAMENTALS */}
              {stockDetailTab === 'fundamentals' && (
                <div className="grid grid-cols-2 gap-3 text-xs">
                  {[
                    { label: 'Market Cap', value: `₹${(selectedStock.currentPrice * 50).toFixed(0)} Lakh` },
                    { label: 'P/E Ratio', value: (15 + (selectedStock.currentPrice % 35)).toFixed(2) },
                    { label: 'Dividend Yield', value: `${(0.5 + (selectedStock.currentPrice % 3)).toFixed(2)}%` },
                    { label: 'Beta (Volatility)', value: (0.8 + (selectedStock.currentPrice % 0.9)).toFixed(2) },
                    { label: 'Debt/Equity', value: (0.1 + (selectedStock.currentPrice % 1.5)).toFixed(2) },
                    { label: 'ROE', value: `${(10 + (selectedStock.currentPrice % 25)).toFixed(2)}%` }
                  ].map((fund, i) => (
                    <div key={i} className="p-3 bg-[#0B121E] border border-white/5 rounded-lg flex justify-between">
                      <span className="text-gray-500">{fund.label}</span>
                      <span className="font-bold text-white">{fund.value}</span>
                    </div>
                  ))}
                </div>
              )}

              {/* SUBTAB 3: FINANCIAL STATEMENTS (Revenue & Net Profit) */}
              {stockDetailTab === 'financials' && (
                <div className="space-y-4 text-xs">
                  <h4 className="font-bold text-gray-400 text-[10px] uppercase">Quarterly Audits (₹ in Lakhs)</h4>
                  <div className="space-y-2">
                    {[
                      { quarter: 'Q1 FY26', rev: 2500, profit: 380 },
                      { quarter: 'Q2 FY26', rev: 2800, profit: 420 },
                      { quarter: 'Q3 FY26', rev: 3100, profit: 490 }
                    ].map((f, i) => (
                      <div key={i} className="p-3 bg-[#0B121E] border border-white/5 rounded-lg flex items-center justify-between">
                        <span className="font-bold text-gray-400">{f.quarter}</span>
                        <div className="flex gap-4">
                          <span>Revenue: <strong className="text-white">₹{f.rev}L</strong></span>
                          <span>Profit: <strong className="text-gainGreen">₹{f.profit}L</strong></span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* SUBTAB 4: SHAREHOLDER PATTERN */}
              {stockDetailTab === 'shareholder' && (
                <div className="space-y-4">
                  <div className="flex items-center justify-center py-4 bg-[#0B121E] border border-white/5 rounded-xl">
                    <svg width="120" height="120" viewBox="0 0 32 32">
                      <circle r="16" cx="16" cy="16" fill="#00D09C" />
                      <circle r="16" cx="16" cy="16" fill="transparent" stroke="#10b981" strokeWidth="32" strokeDasharray="60 100" />
                      <circle r="16" cx="16" cy="16" fill="transparent" stroke="#f59e0b" strokeWidth="32" strokeDasharray="30 100" strokeDashoffset="-60" />
                      <circle r="16" cx="16" cy="16" fill="transparent" stroke="#ef4444" strokeWidth="32" strokeDasharray="10 100" strokeDashoffset="-90" />
                      <circle r="8" cx="16" cy="16" fill="#141F32" />
                    </svg>
                  </div>
                  <div className="grid grid-cols-3 gap-2 text-[10px] text-center">
                    <div className="p-2.5 rounded-lg border border-emerald-500/10 bg-emerald-500/5">
                      <span className="font-bold text-emerald-400">Promoters</span>
                      <p className="font-extrabold text-xs mt-1">60.0%</p>
                    </div>
                    <div className="p-2.5 rounded-lg border border-amber-500/10 bg-amber-500/5">
                      <span className="font-bold text-amber-400">FII / Institutions</span>
                      <p className="font-extrabold text-xs mt-1">30.0%</p>
                    </div>
                    <div className="p-2.5 rounded-lg border border-red-500/10 bg-red-500/5">
                      <span className="font-bold text-red-400">Public Retail</span>
                      <p className="font-extrabold text-xs mt-1">10.0%</p>
                    </div>
                  </div>
                </div>
              )}

              {/* SUBTAB 5: PEER COMPARISON */}
              {stockDetailTab === 'peers' && (
                <div className="space-y-3 text-xs">
                  <div className="p-3 bg-[#0B121E] border border-white/5 rounded-lg flex justify-between font-bold text-gray-500">
                    <span>Company Symbol</span>
                    <span>Price</span>
                    <span>1D Change</span>
                  </div>
                  {stocks.filter(s => s.sector === selectedStock.sector).slice(0, 3).map(peer => (
                    <div key={peer.symbol} className="p-3 bg-[#0B121E] border border-white/5 rounded-lg flex justify-between items-center">
                      <span className="font-bold">{peer.symbol}</span>
                      <span>₹{peer.currentPrice.toFixed(2)}</span>
                      <span className={peer.pChange >= 0 ? 'text-gainGreen' : 'text-lossRed'}>
                        {peer.pChange >= 0 ? '+' : ''}{peer.pChange.toFixed(2)}%
                      </span>
                    </div>
                  ))}
                </div>
              )}

              {/* SUBTAB 6: NEWS SENTIMENT SCANS */}
              {stockDetailTab === 'news' && (
                <div className="space-y-4">
                  {aiSentimentData[selectedStock.symbol] ? (
                    <div className="space-y-3">
                      <div className="p-4 rounded-xl border border-white/5 bg-[#0B121E] flex items-center justify-between text-xs">
                        <div>
                          <span className="text-[10px] text-gray-500 uppercase">AI Sentiment Rating</span>
                          <p className="text-sm font-bold mt-1 text-white">{aiSentimentData[selectedStock.symbol].label}</p>
                        </div>
                        <span className={`text-xs font-bold px-3 py-1 rounded-full border
                          ${aiSentimentData[selectedStock.symbol].score >= 0.3
                            ? 'bg-gainGreen/10 text-gainGreen border-gainGreen/20'
                            : aiSentimentData[selectedStock.symbol].score <= -0.3
                              ? 'bg-lossRed/10 text-lossRed border-lossRed/20'
                              : 'bg-white/5 text-gray-400 border-white/10'}`}>
                          Score: {aiSentimentData[selectedStock.symbol].score}
                        </span>
                      </div>
                      <div className="p-4 rounded-xl border border-white/5 bg-[#0B121E] text-xs">
                        <span className="text-[10px] text-gray-500 uppercase block mb-1">AI Press Sentiment Summary</span>
                        <p className="text-gray-300 leading-relaxed">{aiSentimentData[selectedStock.symbol].summary}</p>
                      </div>
                    </div>
                  ) : (
                    <div className="flex items-center justify-center py-6 text-xs text-gray-500">
                      <RefreshCw className="w-4 h-4 animate-spin text-gainGreen mr-2" /> Scraping press wires for news indicators…
                    </div>
                  )}
                </div>
              )}

              {/* SUBTAB 7: ORDER TICKET BUY/SELL */}
              {stockDetailTab === 'trade' && (
                <div className="space-y-4 animate-fadeIn">
                  <div className="flex gap-2 p-1 bg-[#0B121E] rounded-xl border border-white/5">
                    {['BUY', 'SELL'].map(t => (
                      <button key={t} type="button" onClick={() => { setTradeModalType(t); setTradeModalErr(''); }}
                        className={`flex-1 py-2 rounded-lg text-xs font-extrabold transition-all
                          ${tradeModalType === t
                            ? (t === 'BUY' ? 'bg-gainGreen text-black' : 'bg-lossRed text-white')
                            : 'text-gray-400 hover:text-white'}`}
                      >
                        {t}
                      </button>
                    ))}
                  </div>

                  <div className="space-y-3">
                    <div>
                      <label className="block text-[10px] text-gray-500 uppercase tracking-wider mb-1.5 font-bold">Quantity (Shares)</label>
                      <input type="number" min="1" value={tradeModalQty} onChange={e => { setTradeModalQty(e.target.value); setTradeModalErr(''); }}
                        className="w-full bg-[#0B121E] border border-white/10 rounded-lg px-3 py-2.5 text-xs text-white focus:outline-none focus:border-gainGreen"
                        placeholder="Quantity of shares"
                      />
                    </div>

                    <div className="flex justify-between text-xs p-3 bg-[#0B121E] rounded-xl border border-white/5">
                      <span className="text-gray-500">Order Value:</span>
                      <strong className={`text-sm ${tradeModalType === 'BUY' ? 'text-gainGreen' : 'text-lossRed'}`}>
                        ₹{((parseFloat(tradeModalQty) || 0) * selectedStock.currentPrice).toFixed(2)}
                      </strong>
                    </div>

                    {tradeModalErr && (
                      <div className="p-2.5 bg-lossRed/10 border border-lossRed/20 text-lossRed rounded-lg text-[10px] flex items-center gap-2">
                        <AlertTriangle className="w-3.5 h-3.5 shrink-0" /> {tradeModalErr}
                      </div>
                    )}
                  </div>

                  <button type="button" onClick={executeSimulatedTrade} disabled={tradeSubmitting}
                    className={`w-full py-3 rounded-xl font-extrabold text-xs uppercase tracking-wider transition-all disabled:opacity-50 flex items-center justify-center gap-2
                      ${tradeModalType === 'BUY' ? 'bg-gainGreen hover:bg-gainGreen/90 text-black' : 'bg-lossRed hover:bg-lossRed/90 text-white'}`}
                  >
                    {tradeSubmitting ? <RefreshCw className="w-4 h-4 animate-spin" /> : `Confirm ${tradeModalType} order`}
                  </button>
                </div>
              )}

            </div>
          </div>
        </div>
      )}

      {/* ══════════════ RISK PROFILE QUIZ DIALOG ══════════════ */}
      {showRiskQuiz && (
        <div className="fixed inset-0 z-[120] flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm" onClick={() => setShowRiskQuiz(false)}>
          <div className="bg-[#141F32] border border-white/10 rounded-2xl w-full max-w-md shadow-2xl p-6 space-y-4" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between border-b border-white/5 pb-3">
              <h3 className="font-extrabold text-base flex items-center gap-2">
                <Shield className="w-5 h-5 text-gainGreen" /> AI Risk Profile Quiz
              </h3>
              <button onClick={() => setShowRiskQuiz(false)} className="p-1 hover:bg-white/5 rounded">
                <X className="w-4 h-4 text-gray-400" />
              </button>
            </div>

            <p className="text-xs text-gray-400 leading-relaxed">
              Select the response that best describes your simulated investment mindset.
            </p>

            <div className="space-y-2.5">
              {[
                { label: 'Capital Preservation: I want to protect my money and yield steady dividends.', value: 'low' },
                { label: 'Balanced Growth: I want medium price gains with index diversification.', value: 'moderate' },
                { label: 'Aggressive Capital Gains: High beta sector trading (IT, Auto).', value: 'high' }
              ].map((ans, i) => (
                <button key={i} onClick={() => { setRiskProfile(ans.value); setShowRiskQuiz(false); addToast(`Risk profile set to ${ans.value.toUpperCase()}`, 'success'); }}
                  className="w-full text-left p-3 rounded-xl border border-white/5 bg-[#0B121E] hover:border-gainGreen/50 text-xs text-white transition-all">
                  {ans.label}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* ══════════════ SETTINGS & PROFILE MODAL ══════════════ */}
      {showSettings && (
        <div className="fixed inset-0 z-[150] flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm" onClick={() => setShowSettings(false)}>
          <div className="bg-[#141F32] border border-white/10 rounded-2xl w-full max-w-md shadow-2xl p-6 space-y-5" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between border-b border-white/5 pb-3">
              <h3 className="font-extrabold text-base flex items-center gap-2">
                <Settings className="w-5 h-5 text-gainGreen" /> Platform Settings & Profile
              </h3>
              <button onClick={() => setShowSettings(false)} className="p-1 hover:bg-white/5 rounded">
                <X className="w-4 h-4 text-gray-400" />
              </button>
            </div>

            {/* Profile Info */}
            <div className="space-y-3 bg-[#0B121E] p-4 rounded-xl border border-white/5">
              <h4 className="text-xs font-bold text-gray-400 uppercase tracking-wider">User Account Profile</h4>
              <div className="space-y-2 text-xs">
                <div className="flex justify-between">
                  <span className="text-gray-500">Name:</span>
                  <span className="font-semibold">{userInfo.name}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Email:</span>
                  <span className="font-semibold">{userInfo.email}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Simulated Wallet:</span>
                  <span className="font-semibold text-gainGreen">₹{walletBalance.toLocaleString('en-IN', { minimumFractionDigits: 2 })}</span>
                </div>
              </div>
            </div>

            {/* Risk Profile Configuration */}
            <div className="space-y-3">
              <h4 className="text-xs font-bold text-gray-400 uppercase tracking-wider">AI Advisor Risk Model</h4>
              <div className="grid grid-cols-3 gap-2">
                {[
                  { id: 'low', label: 'Low Risk', desc: 'Conservative' },
                  { id: 'moderate', label: 'Moderate', desc: 'Balanced' },
                  { id: 'high', label: 'High Risk', desc: 'Aggressive' }
                ].map(r => (
                  <button key={r.id} onClick={() => { setRiskProfile(r.id); addToast(`Advisor model set to ${r.label.toUpperCase()} (${r.desc})`, 'success'); }}
                    className={`p-2.5 rounded-xl border text-center transition-all flex flex-col items-center justify-center gap-0.5
                      ${riskProfile === r.id
                        ? 'border-gainGreen bg-gainGreen/10 text-gainGreen'
                        : 'border-white/5 bg-[#0B121E] text-gray-400 hover:text-white'}`}
                  >
                    <span className="text-[10px] font-bold">{r.label}</span>
                    <span className="text-[8px] opacity-75">{r.desc}</span>
                  </button>
                ))}
              </div>
            </div>



            {/* Log Out & Reset */}
            <div className="border-t border-white/5 pt-4">
              <button type="button" onClick={() => {
                sessionStorage.removeItem('tm_logged_in');
                setUserId(null);
                setCurrentScreen('SPLASH');
                setShowSettings(false);
                addToast('Logged out. Onboarding reset.', 'info');
              }}
                className="w-full py-2.5 bg-lossRed/10 hover:bg-lossRed/20 border border-lossRed/20 text-lossRed text-xs font-bold rounded-lg transition-all flex items-center justify-center gap-2">
                <LogIn className="w-4 h-4 rotate-180" /> Log Out & Reset Onboarding
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Footer */}
      <footer className="border-t border-white/5 py-6 mt-12 text-center text-[10px] text-gray-600">
        TradeMentor · Final Year Engineering Project · Real-time simulated paper trading dashboard. No real money involved.
      </footer>
    </div>
  );
}
