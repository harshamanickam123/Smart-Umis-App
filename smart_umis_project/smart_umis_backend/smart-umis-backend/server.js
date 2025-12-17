const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const sqlite3 = require("sqlite3").verbose();
const path = require("path");
const QRCode = require("qrcode");

const app = express();
const PORT = 5000;

// Middleware
app.use(cors());
app.use(bodyParser.json({ limit: "50mb" }));
app.use(bodyParser.urlencoded({ limit: "50mb", extended: true }));

// Connect to SQLite
const dbPath = path.resolve(__dirname, "smartumis.db");
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) console.error("❌ SQLite error:", err.message);
  else console.log("✅ Connected to SQLite database at", dbPath);
});

// ---------------------- TABLE CREATION ----------------------
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

// UPDATED: Complete students table with ALL fields
db.run(`
  CREATE TABLE IF NOT EXISTS students (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    department TEXT NOT NULL,
    year TEXT NOT NULL,
    section TEXT NOT NULL,
    salutation TEXT,
    studentNameCertificate TEXT NOT NULL,
    studentNameAadhaar TEXT,
    fullName TEXT,
    nationality TEXT,
    gender TEXT,
    dateOfBirth TEXT,
    bloodGroup TEXT,
    religion TEXT,
    community TEXT,
    communityCertificateNumber TEXT,
    caste TEXT,
    aadhaarNumber TEXT,
    isFirstGraduate TEXT,
    firstGraduateCertificateNumber TEXT,
    fatherName TEXT,
    motherName TEXT,
    motherOccupation TEXT,
    fatherOccupation TEXT,
    enteredBy TEXT,
    marksheetFileName TEXT,
    aadhaarFileName TEXT,
    panCardFileName TEXT,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP
  )
`, (err) => {
  if (err) console.error("Error creating students table:", err);
  else console.log("✅ Students table ready");
});

// ---------------------- AUTH ROUTES ----------------------
app.post("/api/auth/register", (req, res) => {
  const { fullName, username, email, password, role } = req.body;
  if (!fullName || !username || !email || !password || !role)
    return res.status(400).json({ message: "Please fill all fields" });

  db.run(
    `INSERT INTO users (fullName, username, email, password, role) VALUES (?, ?, ?, ?, ?)`,
    [fullName, username, email, password, role],
    function (err) {
      if (err) {
        if (err.message.includes("UNIQUE"))
          return res.status(400).json({ message: "Username or Email exists" });
        return res.status(500).json({ message: "DB error" });
      }
      res.status(201).json({ message: "Account created", userId: this.lastID });
    }
  );
});

app.post("/api/auth/login", (req, res) => {
  const { username, password } = req.body;
  db.get(
    `SELECT * FROM users WHERE username = ? AND password = ?`,
    [username, password],
    (err, row) => {
      if (err) return res.status(500).json({ message: "DB error" });
      if (!row)
        return res.status(400).json({ message: "Invalid username/password" });
      res.json({ message: "Login successful", user: row });
    }
  );
});

// ---------------------- STUDENT DATA ----------------------
// UPDATED: Handle ALL student fields
app.post("/api/students/add", (req, res) => {
  console.log("Received data:", req.body); // Debug log
  
  const {
    department,
    year,
    section,
    salutation,
    studentNameCertificate,
    studentNameAadhaar,
    fullName,
    nationality,
    gender,
    dateOfBirth,
    bloodGroup,
    religion,
    community,
    communityCertificateNumber,
    caste,
    aadhaarNumber,
    isFirstGraduate,
    firstGraduateCertificateNumber,
    fatherName,
    motherName,
    motherOccupation,
    fatherOccupation,
    enteredBy,
    marksheetFileName,
    aadhaarFileName,
    panCardFileName
  } = req.body;

  // Validate required fields
  if (!department || !year || !section || !studentNameCertificate) {
    return res.status(400).json({ message: "Missing required fields" });
  }

  const sql = `
    INSERT INTO students (
      department, year, section, salutation, studentNameCertificate,
      studentNameAadhaar, fullName, nationality, gender, dateOfBirth,
      bloodGroup, religion, community, communityCertificateNumber,
      caste, aadhaarNumber, isFirstGraduate, firstGraduateCertificateNumber,
      fatherName, motherName, motherOccupation, fatherOccupation,
      enteredBy, marksheetFileName, aadhaarFileName, panCardFileName
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;

  const params = [
    department,
    year,
    section,
    salutation || null,
    studentNameCertificate,
    studentNameAadhaar || null,
    fullName || null,
    nationality || null,
    gender || null,
    dateOfBirth || null,
    bloodGroup || null,
    religion || null,
    community || null,
    communityCertificateNumber || null,
    caste || null,
    aadhaarNumber || null,
    isFirstGraduate || null,
    firstGraduateCertificateNumber || null,
    fatherName || null,
    motherName || null,
    motherOccupation || null,
    fatherOccupation || null,
    enteredBy || null,
    marksheetFileName || null,
    aadhaarFileName || null,
    panCardFileName || null
  ];

  db.run(sql, params, function (err) {
    if (err) {
      console.error("Database error:", err);
      return res.status(500).json({ message: "DB error", error: err.message });
    }
    
    console.log("✅ Student data saved with ID:", this.lastID);
    res.json({
      message: "Student data saved",
      studentId: this.lastID,
    });
  });
});

app.get("/api/students", (req, res) => {
  db.all(`SELECT * FROM students ORDER BY createdAt DESC`, [], (err, rows) => {
    if (err) return res.status(500).json({ message: "DB error" });
    res.json(rows);
  });
});

// ---------------------- QR ROUTES ----------------------

// Student-specific QR
app.get("/api/getQRCodes/:userId", (req, res) => {
  const { userId } = req.params;
  db.get(`SELECT * FROM students WHERE id = ?`, [userId], (err, row) => {
    if (err) return res.status(500).json({ message: "DB error" });
    if (!row) return res.status(404).json({ message: "Student not found" });

    const qrPayload = JSON.stringify({
      id: row.id,
      name: row.studentNameCertificate,
      department: row.department,
      year: row.year,
      section: row.section,
    });

    QRCode.toDataURL(qrPayload, { errorCorrectionLevel: "H" }, (err, url) => {
      if (err) return res.status(500).json({ message: "QR gen error" });
      res.json({ student: row, qrCode: url });
    });
  });
});

// All students' QR (Staff)
app.get("/api/getAllQRCodes", (req, res) => {
  db.all(`SELECT * FROM students ORDER BY createdAt DESC`, [], async (err, rows) => {
    if (err) return res.status(500).json({ message: "DB error" });

    const qrList = await Promise.all(
      rows.map(async (row) => {
        const qrPayload = JSON.stringify({
          id: row.id,
          name: row.studentNameCertificate,
          department: row.department,
          year: row.year,
          section: row.section,
        });
        const qrUrl = await QRCode.toDataURL(qrPayload, { errorCorrectionLevel: "H" });
        return { ...row, qrCode: qrUrl };
      })
    );
    res.json(qrList);
  });
});

// Verify QR route
app.post("/api/verify-qr", (req, res) => {
  try {
    const { qrData } = req.body;
    const parsed = JSON.parse(qrData);

    db.get(`SELECT * FROM students WHERE id = ?`, [parsed.id], (err, row) => {
      if (err) return res.status(500).json({ message: "DB error" });
      if (!row) return res.status(404).json({ message: "Invalid QR" });
      res.json({ valid: true, student: row });
    });
  } catch (e) {
    res.status(400).json({ message: "Invalid QR data" });
  }
});

// Staff filter route
app.get("/api/staff/students", (req, res) => {
  const { department, year, section } = req.query;

  if (!department || !year || !section) {
    return res.status(400).json({ message: "Please provide dept, year, and section" });
  }

  db.all(
    `SELECT * FROM students WHERE department = ? AND year = ? AND section = ? ORDER BY createdAt DESC`,
    [department, year, section],
    (err, rows) => {
      if (err) return res.status(500).json({ message: "DB error" });
      res.json({ students: rows });
    }
  );
});

// Fetch student by ID (public endpoint)
app.get("/api/students/:id", (req, res) => {
  const { id } = req.params;
  db.get(`SELECT * FROM students WHERE id = ?`, [id], (err, row) => {
    if (err) {
      console.error("DB error:", err);
      return res.status(500).json({ message: "DB error" });
    }
    if (!row) return res.status(404).json({ message: "Student not found" });
    res.json({ student: row });
  });
});

// Fetch student by ID (staff endpoint - same functionality)
app.get("/api/staff/students/:id", (req, res) => {
  const { id } = req.params;
  db.get(`SELECT * FROM students WHERE id = ?`, [id], (err, row) => {
    if (err) {
      console.error("DB error:", err);
      return res.status(500).json({ message: "DB error" });
    }
    if (!row) return res.status(404).json({ message: "Student not found" });
    res.json({ student: row });
  });
});

// ---------------------- SERVER START ----------------------
app.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`📡 API ready on http://localhost:${PORT}/api`);
});