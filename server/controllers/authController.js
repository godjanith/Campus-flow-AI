import jwt from 'jsonwebtoken';
import User from '../models/User.js';

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '7d' });
};

export const loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ message: 'Please enter both email and password' });
    }

    const cleanEmail = email.trim().toLowerCase();
    const user = await User.findOne({ email: cleanEmail });

    if (user && (await user.matchPassword(password))) {
      return res.json({
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        regNo: user.regNo,
        token: generateToken(user._id),
      });
    }
    return res.status(401).json({ message: 'Invalid email or password' });
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
};

export const registerUser = async (req, res) => {
  try {
    const { name, email, password, regNo, role } = req.body;
    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }
    if (!name || name.trim().length === 0) {
      return res.status(400).json({ message: 'Full name is required' });
    }
    if (password.length < 6) {
      return res.status(400).json({ message: 'Password must be at least 6 characters long' });
    }

    const cleanEmail = email.trim().toLowerCase();
    const userExists = await User.findOne({ email: cleanEmail });
    if (userExists) {
      return res.status(400).json({ message: 'An account with this email already exists. Please sign in instead.' });
    }

    // Strictly permit only STUDENT and FACULTY_COORDINATOR registrations
    const normalizedRole = (role || 'STUDENT').toUpperCase().replace(/\s+/g, '_');
    const validRoles = ['STUDENT', 'FACULTY_COORDINATOR'];

    if (!validRoles.includes(normalizedRole)) {
      return res.status(400).json({
        message: 'Self-registration is only permitted for Students and Faculty Coordinators. Administrative accounts require IT command provisioning.',
      });
    }

    const defaultReg = normalizedRole === 'FACULTY_COORDINATOR' ? 'PU-FAC-EMP' : 'PU-STUDENT';
    const finalRegNo = (regNo && regNo.trim().length > 0) ? regNo.trim() : defaultReg;

    const user = await User.create({
      name: name.trim(),
      email: cleanEmail,
      password,
      regNo: finalRegNo,
      role: normalizedRole,
    });

    return res.status(201).json({
      _id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      regNo: user.regNo,
      token: generateToken(user._id),
    });
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
};