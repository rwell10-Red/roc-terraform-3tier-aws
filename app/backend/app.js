const express = require('express');
const mysql = require('mysql2/promise');
const { RDS } = require('@aws-sdk/client-rds');
const { Signer } = require('@aws-sdk/rds-signer');

const app = express();
const PORT = process.env.APP_PORT || 5000;

async function getAuthToken() {
  const signer = new Signer({
    hostname: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT || '3306'),
    username: process.env.DB_USER,
    region: process.env.AWS_REGION || 'us-east-1',
  });
  return signer.getAuthToken();
}

app.get('/api/health', async (req, res) => {
  try {
    const token = await getAuthToken();

    const connection = await mysql.createConnection({
      host: process.env.DB_HOST,
      port: parseInt(process.env.DB_PORT || '3306'),
      user: process.env.DB_USER,
      password: token,
      database: 'mysql',
      ssl: { rejectUnauthorized: false },
      connectTimeout: 5000,
    });

    await connection.query('SELECT 1 AS connected');
    await connection.end();

    res.json({
      message: 'Hello Andre Rockwell — DB connected!',
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    res.status(500).json({
      message: 'DB connection failed',
      error: err.message,
    });
  }
});

app.get('/api/ping', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Backend running on port ${PORT}`);
});
