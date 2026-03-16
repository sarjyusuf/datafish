const express = require('express');
const cors = require('cors');
const { createProxyMiddleware } = require('http-proxy-middleware');
const morgan = require('morgan');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(cors());
app.use(morgan('combined'));

// Service URLs
const SERVICES = {
  notification: process.env.NOTIFICATION_SERVICE_URL || 'http://localhost:8083',
  product: process.env.PRODUCT_SERVICE_URL || 'http://localhost:8081',
  order: process.env.ORDER_SERVICE_URL || 'http://localhost:8082',
};

console.log('🐟 DataFish API Gateway');
console.log('Service Configuration:');
console.log('  Notification Service:', SERVICES.notification);
console.log('  Product Service:', SERVICES.product);
console.log('  Order Service:', SERVICES.order);

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'api-gateway',
    timestamp: new Date().toISOString(),
    services: SERVICES,
  });
});

// Route info
app.get('/', (req, res) => {
  res.json({
    name: 'DataFish API Gateway',
    version: '1.0.0',
    routes: {
      notifications: '/api/notifications/*',
      products: '/api/products/*',
      orders: '/api/orders/*',
      cart: '/api/cart/*',
    },
    services: SERVICES,
  });
});

// Proxy configurations
const proxyOptions = {
  changeOrigin: true,
  logLevel: 'warn',
  timeout: 30000, // 30 second timeout
  proxyTimeout: 30000,
  onProxyReq: (proxyReq, req, res) => {
    // Log proxy requests for debugging
    console.log(`Proxying ${req.method} ${req.path} to ${proxyReq.path}`);
  },
  onError: (err, req, res) => {
    console.error('Proxy Error:', err.message);
    res.status(502).json({
      error: 'Bad Gateway',
      message: 'Service temporarily unavailable',
      timestamp: new Date().toISOString(),
    });
  },
  onProxyRes: (proxyRes, req, res) => {
    console.log(`Response from ${req.path}: ${proxyRes.statusCode}`);
  },
};

// Notification Service Routes
app.use(
  '/api/notifications',
  createProxyMiddleware({
    target: SERVICES.notification,
    ...proxyOptions,
    pathRewrite: {
      '^/api/notifications': '/api/notifications',
    },
  })
);

// Product Service Routes
app.use(
  '/api/products',
  createProxyMiddleware({
    target: SERVICES.product,
    ...proxyOptions,
    pathRewrite: {
      '^/api/products': '/api/products',
    },
  })
);

// Order Service Routes
app.use(
  '/api/orders',
  createProxyMiddleware({
    target: SERVICES.order,
    ...proxyOptions,
    pathRewrite: {
      '^/api/orders': '/api/orders',
    },
  })
);

// Cart Routes (Order Service)
app.use(
  '/api/cart',
  createProxyMiddleware({
    target: SERVICES.order,
    ...proxyOptions,
    pathRewrite: {
      '^/api/cart': '/api/cart',
    },
  })
);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.method} ${req.path} not found`,
    timestamp: new Date().toISOString(),
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Gateway Error:', err);
  res.status(500).json({
    error: 'Internal Server Error',
    message: err.message,
    timestamp: new Date().toISOString(),
  });
});

// Start server
const server = app.listen(PORT, () => {
  console.log(`\n🚀 API Gateway running on http://localhost:${PORT}`);
  console.log(`📊 Health check available at http://localhost:${PORT}/health\n`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});
