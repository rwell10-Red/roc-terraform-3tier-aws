#!/bin/bash
set -e

# Install Node.js 20 LTS
dnf install -y nodejs npm

# Create app directory
mkdir -p /opt/app
cd /opt/app

# Create package.json
cat > package.json << 'PKGEOF'
{
  "name": "roc-3tier-backend",
  "version": "1.0.0",
  "description": "Backend API for 3-tier AWS architecture",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "dependencies": {
    "@aws-sdk/client-rds": "3.712.0",
    "@aws-sdk/rds-signer": "3.712.0",
    "express": "4.21.2",
    "mysql2": "3.12.0"
  }
}
PKGEOF

# Create app.js
cat > app.js << 'APPEOF'
const express = require('express');
const mysql = require('mysql2/promise');
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
APPEOF

# Install dependencies
npm install --production

# Create environment file
cat > /opt/app/.env << ENVEOF
APP_PORT=5000
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_USER=${DB_USER}
AWS_REGION=${AWS_REGION}
ENVEOF

# Create systemd service
cat > /etc/systemd/system/backend.service << 'SVCEOF'
[Unit]
Description=Backend API Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/app
EnvironmentFile=/opt/app/.env
ExecStart=/usr/bin/node app.js
Restart=on-failure
RestartSec=5
User=nobody
Group=nobody

[Install]
WantedBy=multi-user.target
SVCEOF

# Set ownership
chown -R nobody:nobody /opt/app

# Start and enable service
systemctl daemon-reload
systemctl enable backend
systemctl start backend
