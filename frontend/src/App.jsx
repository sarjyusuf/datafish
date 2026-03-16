import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { useState, useEffect } from 'react';
import './App.css';

// Components
import Navbar from './components/Navbar';
import Home from './pages/Home';
import Products from './pages/Products';
import ProductDetail from './pages/ProductDetail';
import Cart from './pages/Cart';
import Orders from './pages/Orders';

function App() {
  const [sessionId, setSessionId] = useState('');

  useEffect(() => {
    // Get or create session ID
    let session = localStorage.getItem('sessionId');
    if (!session) {
      session = generateSessionId();
      localStorage.setItem('sessionId', session);
    }
    setSessionId(session);
  }, []);

  const generateSessionId = () => {
    return 'session_' + Math.random().toString(36).substring(2) + Date.now().toString(36);
  };

  if (!sessionId) {
    return (
      <div className="loading-screen">
        <div className="spinner"></div>
        <p className="text-primary mt-2">Loading DataFish...</p>
      </div>
    );
  }

  return (
    <Router>
      <div className="app">
        <Navbar />
        <main className="main-content">
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/products" element={<Products />} />
            <Route path="/products/:id" element={<ProductDetail sessionId={sessionId} />} />
            <Route path="/cart" element={<Cart sessionId={sessionId} />} />
            <Route path="/orders" element={<Orders sessionId={sessionId} />} />
          </Routes>
        </main>
        <footer className="footer">
          <p>🐟 DataFish © 2025 - The Retro Fish Store</p>
          <p className="text-dim" style={{ fontSize: '10px', marginTop: '10px' }}>
            Built with Java • Python • Go • Node.js
          </p>
        </footer>
      </div>
    </Router>
  );
}

export default App;
