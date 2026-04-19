const express = require('express');
const router = express.Router();

const authService = require('../services/authService');
const auth = require('../middleware/auth');
const { otpLimiter, loginLimiter } = require('../middleware/rateLimiter');
const {
  validate,
  registerSchema,
  loginSchema,
  otpRequestSchema,
  otpVerifySchema,
  refreshTokenSchema,
} = require('../utils/validators');

// ============================================================================
// POST /register — Register a new user (requester or runner)
// ============================================================================
router.post('/register', validate(registerSchema), async (req, res, next) => {
  try {
    const user = await authService.registerUser(req.body);
    
    // Generate JWT tokens for auto-login after signup
    const result = await authService.loginUser(user.email, req.body.password);

    res.status(201).json({
      message: 'User registered successfully',
      user,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    });
  } catch (error) {
    // Handle conflict (duplicate email/phone)
    if (error.statusCode) {
      return res.status(error.statusCode).json({
        error: {
          code: error.code,
          message: error.message,
        },
      });
    }
    next(error);
  }
});

// ============================================================================
// POST /login — Login with email + password, returns JWT
// ============================================================================
router.post('/login', loginLimiter, validate(loginSchema), async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const result = await authService.loginUser(email, password);

    res.json({
      message: 'Login successful',
      user: result.user,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    });
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({
        error: {
          code: error.code,
          message: error.message,
        },
      });
    }
    next(error);
  }
});

// ============================================================================
// POST /otp/request — Send OTP to registered email/phone
// ============================================================================
router.post('/otp/request', otpLimiter, validate(otpRequestSchema), async (req, res, next) => {
  try {
    const result = await authService.requestOtp(req.body.identifier);

    res.json({
      message: result.message,
      otpId: result.otpId,
      expiresAt: result.expiresAt,
      // DEV ONLY — expose OTP in development mode
      ...(result.devOtp && { devOtp: result.devOtp }),
    });
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({
        error: {
          code: error.code,
          message: error.message,
        },
      });
    }
    next(error);
  }
});

// ============================================================================
// POST /otp/verify — Verify OTP and return JWT
// ============================================================================
router.post('/otp/verify', validate(otpVerifySchema), async (req, res, next) => {
  try {
    const { identifier, code } = req.body;
    const result = await authService.verifyOtp(identifier, code);

    res.json({
      message: 'OTP verified successfully',
      user: result.user,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    });
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({
        error: {
          code: error.code,
          message: error.message,
        },
      });
    }
    next(error);
  }
});

// ============================================================================
// POST /refresh-token — Refresh an expired access token
// ============================================================================
router.post('/refresh-token', validate(refreshTokenSchema), async (req, res, next) => {
  try {
    const result = await authService.refreshAccessToken(req.body.refreshToken);

    res.json({
      message: 'Token refreshed successfully',
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    });
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({
        error: {
          code: error.code,
          message: error.message,
        },
      });
    }
    next(error);
  }
});

// ============================================================================
// GET /me — Get current user profile (protected)
// ============================================================================
router.get('/me', auth, async (req, res, next) => {
  try {
    const user = await authService.getUserProfile(req.userId);

    res.json({ user });
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({
        error: {
          code: error.code,
          message: error.message,
        },
      });
    }
    next(error);
  }
});

// ============================================================================
// PUT /me — Update current user profile (protected)
// ============================================================================
router.put('/me', auth, async (req, res, next) => {
  try {
    const { fullName, phone, email } = req.body;

    // Validate input
    if (fullName && fullName.length < 2) {
      return res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Full name must be at least 2 characters',
        },
      });
    }

    const user = await authService.updateUserProfile(req.userId, { fullName, phone, email });

    res.json({
      message: 'Profile updated successfully',
      user,
    });
  } catch (error) {
    if (error.statusCode) {
      return res.status(error.statusCode).json({
        error: {
          code: error.code,
          message: error.message,
        },
      });
    }
    next(error);
  }
});

module.exports = router;
