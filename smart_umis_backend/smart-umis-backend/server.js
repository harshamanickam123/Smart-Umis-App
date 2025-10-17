// server.js
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const app = express();
const PORT = 5000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Connect to SQLite database
const dbPath = path.resolve(__dirname, 'smartumis.db');
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) console.error('❌ SQLite error:', err.message);
  else console.log('✅ Connected to SQLite database at', dbPath);
});

// Create users table if it doesn't exist
db.run(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fullName TEXT,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    password TEXT,
    role TEXT
  )
`);


// ------------------------
// TEST / PING API
// ------------------------
app.get('/api/ping', (req, res) => {
  res.status(200).json({ message: 'Backend is connected!' });
});


// ------------------------
// REGISTER API
// ------------------------
app.post('/api/auth/register', (req, res) => {
  const { fullName, username, email, password, role } = req.body;

  if (!fullName || !username || !email || !password || !role) {
    return res.status(400).json({ message: 'Please fill all fields' });
  }

  const insertQuery = `
    INSERT INTO users (fullName, username, email, password, role)
    VALUES (?, ?, ?, ?, ?)
  `;

  db.run(insertQuery, [fullName, username, email, password, role], function(err) {
    if (err) {
      if (err.message.includes('UNIQUE')) {
        return res.status(400).json({ message: 'Username or Email already exists' });
      }
      return res.status(500).json({ message: 'Database error' });
    }
    res.status(201).json({ message: 'Account created successfully', userId: this.lastID });
  });
});

// ------------------------
// LOGIN API
// ------------------------
app.post('/api/auth/login', (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ message: 'Please provide username and password' });
  }

  const selectQuery = `
    SELECT * FROM users WHERE username = ? AND password = ?
  `;

  db.get(selectQuery, [username, password], (err, row) => {
    if (err) return res.status(500).json({ message: 'Database error' });
    if (!row) return res.status(400).json({ message: 'Invalid username or password' });

    // Send user data to frontend
    res.status(200).json({
      message: 'Login successful',
      user: {
        id: row.id,
        fullName: row.fullName,
        username: row.username,
        email: row.email,
        role: row.role,
      },
    });
  });
});

// Add this to your existing server.js file
// Add after the auth routes and before the server start

// ============================================
// STUDENT DATA ENTRY ROUTES
// ============================================

// Add Student Data (Protected Route - requires authentication)
app.post('/api/students/add', async (req, res) => {
  try {
    const {
      department,
      fullName,
      fatherName,
      caste,
      motherOccupation,
      fatherOccupation,
      enteredBy
    } = req.body;

    // Validation
    if (!department || !fullName || !fatherName) {
      return res.status(400).json({
        message: 'Department, Full Name, and Father Name are required'
      });
    }

    // Insert student data into SQLite database
    const query = `
      INSERT INTO students (
        department,
        full_name,
        father_name,
        caste,
        mother_occupation,
        father_occupation,
        entered_by,
        created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))
    `;

    db.run(
      query,
      [
        department,
        fullName,
        fatherName,
        caste || '',
        motherOccupation || '',
        fatherOccupation || '',
        enteredBy || 'unknown'
      ],
      function(err) {
        if (err) {
          console.error('Database error:', err);
          return res.status(500).json({
            message: 'Failed to save student data',
            error: err.message
          });
        }

        res.status(201).json({
          message: 'Student data saved successfully',
          studentId: this.lastID,
          student: {
            id: this.lastID,
            department,
            fullName,
            fatherName,
            caste,
            motherOccupation,
            fatherOccupation,
            enteredBy
          }
        });
      }
    );
  } catch (error) {
    console.error('Error saving student data:', error);
    res.status(500).json({
      message: 'Server error while saving student data'
    });
  }
});

// Get All Students
app.get('/api/students', async (req, res) => {
  try {
    const query = 'SELECT * FROM students ORDER BY created_at DESC';
    
    db.all(query, [], (err, rows) => {
      if (err) {
        console.error('Database error:', err);
        return res.status(500).json({
          message: 'Failed to fetch students',
          error: err.message
        });
      }

      res.json({
        message: 'Students fetched successfully',
        count: rows.length,
        students: rows
      });
    });
  } catch (error) {
    console.error('Error fetching students:', error);
    res.status(500).json({
      message: 'Server error while fetching students'
    });
  }
});

// Get Student by ID
app.get('/api/students/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const query = 'SELECT * FROM students WHERE id = ?';

    db.get(query, [id], (err, row) => {
      if (err) {
        console.error('Database error:', err);
        return res.status(500).json({
          message: 'Failed to fetch student',
          error: err.message
        });
      }

      if (!row) {
        return res.status(404).json({
          message: 'Student not found'
        });
      }

      res.json({
        message: 'Student fetched successfully',
        student: row
      });
    });
  } catch (error) {
    console.error('Error fetching student:', error);
    res.status(500).json({
      message: 'Server error while fetching student'
    });
  }
});

// Update Student Data
app.put('/api/students/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const {
      department,
      fullName,
      fatherName,
      caste,
      motherOccupation,
      fatherOccupation
    } = req.body;

    const query = `
      UPDATE students
      SET department = ?,
          full_name = ?,
          father_name = ?,
          caste = ?,
          mother_occupation = ?,
          father_occupation = ?,
          updated_at = datetime('now')
      WHERE id = ?
    `;

    db.run(
      query,
      [
        department,
        fullName,
        fatherName,
        caste || '',
        motherOccupation || '',
        fatherOccupation || '',
        id
      ],
      function(err) {
        if (err) {
          console.error('Database error:', err);
          return res.status(500).json({
            message: 'Failed to update student data',
            error: err.message
          });
        }

        if (this.changes === 0) {
          return res.status(404).json({
            message: 'Student not found'
          });
        }

        res.json({
          message: 'Student data updated successfully',
          changes: this.changes
        });
      }
    );
  } catch (error) {
    console.error('Error updating student:', error);
    res.status(500).json({
      message: 'Server error while updating student'
    });
  }
});

// Delete Student
app.delete('/api/students/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const query = 'DELETE FROM students WHERE id = ?';

    db.run(query, [id], function(err) {
      if (err) {
        console.error('Database error:', err);
        return res.status(500).json({
          message: 'Failed to delete student',
          error: err.message
        });
      }

      if (this.changes === 0) {
        return res.status(404).json({
          message: 'Student not found'
        });
      }

      res.json({
        message: 'Student deleted successfully',
        changes: this.changes
      });
    });
  } catch (error) {
    console.error('Error deleting student:', error);
    res.status(500).json({
      message: 'Server error while deleting student'
    });
  }
});

// ============================================
// DATABASE TABLE CREATION
// ============================================
// Add this near the top of your server.js, after database connection

// Create students table if it doesn't exist
db.run(`
  CREATE TABLE IF NOT EXISTS students (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    department TEXT NOT NULL,
    full_name TEXT NOT NULL,
    father_name TEXT NOT NULL,
    caste TEXT,
    mother_occupation TEXT,
    father_occupation TEXT,
    entered_by TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )
`, (err) => {
  if (err) {
    console.error('Error creating students table:', err);
  } else {
    console.log('✅ Students table ready');
  }
});

// ------------------------
// START SERVER
// ------------------------
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running at http://0.0.0.0:${PORT}`);
});
