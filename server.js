// Simple Node.js server to test the Model Day Chat API
import express from 'express';
import cors from 'cors';
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Get current directory for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('.'));

// Import the chat handler
import chatHandler from './api/chat.js';

// API route
app.all('/api/chat', async (req, res) => {
  try {
    await chatHandler(req, res);
  } catch (error) {
    console.error('❌ Server error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Something went wrong with the server'
    });
  }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'Model Day Chat API is running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    hasOpenAIKey: !!process.env.OPENAI_API_KEY
  });
});

// Serve Flutter web app
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Start server
app.listen(PORT, () => {
  console.log('🚀 Model Day Backend Server Started!');
  console.log(`📍 Server running at: http://localhost:${PORT}`);
  console.log(`🤖 Chat API available at: http://localhost:${PORT}/api/chat`);
  console.log(`❤️ Health check at: http://localhost:${PORT}/api/health`);
  console.log(`🔑 OpenAI API Key: ${process.env.OPENAI_API_KEY ? '✅ Loaded' : '❌ Missing'}`);
  console.log('');
  console.log('🧪 Test the API:');
  console.log(`   curl -X POST http://localhost:${PORT}/api/chat \\`);
  console.log('     -H "Content-Type: application/json" \\');
  console.log('     -d \'{"message":"Hello","context":"Test context"}\'');
  console.log('');
  console.log('📱 Open your Flutter app at: http://localhost:' + PORT);
});
