import { Link } from 'react-router-dom';
import './Navbar.css';

function Navbar() {
  return (
    <nav className="navbar">
      <div className="navbar-container">
        <Link to="/" className="navbar-logo">
          <span className="logo-text glitch">🐟 DATAFISH</span>
        </Link>
        
        <div className="navbar-menu">
          <Link to="/" className="navbar-link">
            <span>HOME</span>
          </Link>
          <Link to="/products" className="navbar-link">
            <span>SHOP</span>
          </Link>
          <Link to="/cart" className="navbar-link">
            <span>CART</span>
          </Link>
          <Link to="/orders" className="navbar-link">
            <span>ORDERS</span>
          </Link>
        </div>
      </div>
    </nav>
  );
}

export default Navbar;
