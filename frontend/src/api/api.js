import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add session ID to requests
api.interceptors.request.use((config) => {
  const sessionId = localStorage.getItem('sessionId');
  if (sessionId) {
    config.params = {
      ...config.params,
      session_id: sessionId,
    };
  }
  return config;
});

// Product API
export const productAPI = {
  getAll: (params) => 
    api.get('/api/products', { params }),
  
  getById: (id) => 
    api.get(`/api/products/${id}`),
  
  search: (query) => 
    api.get('/api/products', { params: { search: query } }),
  
  getByCategory: (category) => 
    api.get('/api/products', { params: { category } }),
  
  getFeatured: () => 
    api.get('/api/products', { params: { featured: true } }),
};

// Cart API
export const cartAPI = {
  getCart: () => 
    api.get('/api/cart'),
  
  addToCart: (item) => 
    api.post('/api/cart', item),
  
  removeFromCart: (itemId) => 
    api.delete(`/api/cart/${itemId}`),
  
  clearCart: () => 
    api.delete('/api/cart'),
};

// Order API
export const orderAPI = {
  createOrder: (orderData) => 
    api.post('/api/orders', orderData),
  
  getOrders: () => 
    api.get('/api/orders'),
  
  getOrderById: (id) => 
    api.get(`/api/orders/${id}`),
};

export default api;
