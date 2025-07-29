import OpenAI from 'openai';
import dotenv from 'dotenv';

// Load environment variables from .env file
dotenv.config();

// System prompt for Model Day AI (matching the Flutter app configuration)
const SYSTEM_PROMPT = `
You are Model Day AI, a personal modeling career assistant for a modeling professional. You have access to ONLY their data and can help analyze it and provide insights.

Key capabilities:
- Analyze modeling jobs, events, and career data
- Calculate earnings and financial insights
- Provide career advice based on their specific data
- Answer questions about their modeling portfolio
- Help with scheduling and planning

Guidelines:
- Only reference data that has been provided in the context
- Be helpful, professional, and encouraging
- Provide specific insights based on their actual data
- If asked about data not in context, politely explain you don't have access to that information
- Keep responses concise but informative
- Focus on actionable advice and insights

Remember: You are their personal AI assistant with access to their modeling career data only.
`;

export default async function handler(req, res) {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    return res.status(200).end();
  }

  // Only allow POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({ 
      error: 'Method not allowed',
      message: 'This endpoint only accepts POST requests'
    });
  }

  // Set CORS headers for actual requests
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  try {
    // Validate request body
    const { message, context } = req.body;

    if (!message || typeof message !== 'string') {
      return res.status(400).json({
        error: 'Invalid request',
        message: 'Message is required and must be a string'
      });
    }

    if (!context || typeof context !== 'string') {
      return res.status(400).json({
        error: 'Invalid request',
        message: 'Context is required and must be a string'
      });
    }

    // Validate message length (prevent abuse)
    if (message.length > 2000) {
      return res.status(400).json({
        error: 'Message too long',
        message: 'Message must be less than 2000 characters'
      });
    }

    // Check for OpenAI API key
    if (!process.env.OPENAI_API_KEY) {
      console.error('❌ OPENAI_API_KEY environment variable not set');
      return res.status(500).json({
        error: 'Configuration error',
        message: 'AI service is not properly configured'
      });
    }

    // Initialize OpenAI client
    const openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY,
    });

    console.log('🤖 Processing chat request:', {
      messageLength: message.length,
      contextLength: context.length,
      timestamp: new Date().toISOString()
    });

    // Create chat completion
    const completion = await openai.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: [
        {
          role: 'system',
          content: SYSTEM_PROMPT
        },
        {
          role: 'system',
          content: context
        },
        {
          role: 'user',
          content: message
        }
      ],
      max_tokens: 500,
      temperature: 0.7,
    });

    // Extract response
    const aiResponse = completion.choices[0]?.message?.content;

    if (!aiResponse) {
      throw new Error('No response generated from OpenAI');
    }

    console.log('✅ AI response generated successfully');

    // Return successful response
    return res.status(200).json({
      response: aiResponse,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Error in chat API:', error);

    // Handle specific OpenAI errors
    if (error.code === 'rate_limit_exceeded') {
      return res.status(429).json({
        error: 'Rate limit exceeded',
        message: 'I\'m currently experiencing high demand. Please wait a moment and try again.'
      });
    }

    if (error.code === 'insufficient_quota') {
      return res.status(429).json({
        error: 'Quota exceeded',
        message: 'The API quota has been exceeded. Please contact support or try again later.'
      });
    }

    if (error.code === 'invalid_api_key' || error.status === 401) {
      return res.status(500).json({
        error: 'Authentication error',
        message: 'There was an issue with the AI service authentication.'
      });
    }

    if (error.code === 'model_not_found' || error.status === 404) {
      return res.status(500).json({
        error: 'Model error',
        message: 'The AI model is currently unavailable.'
      });
    }

    // Handle network/timeout errors
    if (error.code === 'ENOTFOUND' || error.code === 'ECONNRESET' || error.code === 'ETIMEDOUT') {
      return res.status(503).json({
        error: 'Network error',
        message: 'I\'m having trouble connecting to my AI service. Please check your internet connection and try again.'
      });
    }

    // Generic error response
    return res.status(500).json({
      error: 'Internal server error',
      message: 'I\'m having trouble connecting to my AI service. Please try again in a moment.'
    });
  }
}
