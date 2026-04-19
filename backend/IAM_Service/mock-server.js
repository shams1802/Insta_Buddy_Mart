const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');

const app = express();
app.use(express.json());
app.use(cors());

const PORT = 3003;
const JWT_SECRET = 'f698e9aa2aa04bf2aa47763c4eff3e22ccba46169d9e6965aa2462e59d3a1d3b5fc72ed9ae4810dcbae0981e9038c3e9753441ffb3bcdac7801cc6e2aeae397f';

// In-memory user database and OTP storage
const users = {};
const otpCodes = {};

// Mock user for testing
users['test@example.com'] = {
  id: 'user_1',
  fullName: 'Test User',
  email: 'test@example.com',
  phone: '9876543210',
  password: 'Test@1234',
  role: 'requester'
};

// POST /register
app.post('/register', (req, res) => {
  const { fullName, email, phone, password } = req.body;

  if (!fullName || !email || !phone || !password) {
    return res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Missing required fields'
      }
    });
  }

  if (users[email]) {
    return res.status(409).json({
      error: {
        code: 'USER_EXISTS',
        message: 'User with this email already exists'
      }
    });
  }

  const userId = `user_${Date.now()}`;
  users[email] = {
    id: userId,
    fullName,
    email,
    phone,
    password,
    role: 'requester'
  };

  const token = jwt.sign({ id: userId, email }, JWT_SECRET, { expiresIn: '24h' });

  res.status(201).json({
    message: 'User registered successfully',
    user: {
      id: userId,
      fullName,
      email,
      phone,
      role: 'requester'
    }
  });
});

// POST /login
app.post('/login', (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Email and password are required'
      }
    });
  }

  const user = users[email];

  if (!user || user.password !== password) {
    return res.status(401).json({
      error: {
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password'
      }
    });
  }

  const token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '24h' });

  res.status(200).json({
    message: 'Login successful',
    accessToken: token,
    user: {
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      role: user.role
    }
  });
});

// POST /otp/request
app.post('/otp/request', (req, res) => {
  const { identifier } = req.body;

  if (!identifier) {
    return res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Identifier (email or phone) is required'
      }
    });
  }

  // Generate a 6-digit OTP
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  otpCodes[identifier] = {
    code: otp,
    createdAt: Date.now(),
    expiresAt: Date.now() + 10 * 60 * 1000 // 10 minutes
  };

  console.log(`[OTP Generated for ${identifier}]: ${otp}`);

  res.status(200).json({
    message: 'OTP sent successfully',
    debug: { otp } // Only for development!
  });
});

// POST /otp/verify
app.post('/otp/verify', (req, res) => {
  const { identifier, code } = req.body;

  if (!identifier || !code) {
    return res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Identifier and OTP code are required'
      }
    });
  }

  const otpData = otpCodes[identifier];

  if (!otpData) {
    return res.status(400).json({
      error: {
        code: 'OTP_NOT_FOUND',
        message: 'No OTP found for this identifier'
      }
    });
  }

  if (otpData.expiresAt < Date.now()) {
    delete otpCodes[identifier];
    return res.status(400).json({
      error: {
        code: 'OTP_EXPIRED',
        message: 'OTP has expired'
      }
    });
  }

  if (otpData.code !== code) {
    return res.status(400).json({
      error: {
        code: 'INVALID_OTP',
        message: 'Invalid OTP code'
      }
    });
  }

  // Check if user exists, if not create one
  let user = users[identifier];
  if (!user) {
    const userId = `user_${Date.now()}`;
    user = {
      id: userId,
      fullName: identifier.includes('@') ? 'OTP User' : 'Phone User',
      email: identifier.includes('@') ? identifier : `user_${Date.now()}@temp.com`,
      phone: identifier.includes('@') ? '0000000000' : identifier,
      password: `temp_${Date.now()}`,
      role: 'requester'
    };
    users[identifier] = user;
  }

  const token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '24h' });

  // Clean up OTP
  delete otpCodes[identifier];

  res.status(200).json({
    message: 'OTP verified successfully',
    accessToken: token,
    user: {
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      role: user.role
    }
  });
});

app.listen(PORT, () => {
  console.log(`✓ Mock IAM Service running on http://localhost:${PORT}`);
  console.log(`
  Test credentials:
  - Email: test@example.com
  - Password: Test@1234
  `);
});
