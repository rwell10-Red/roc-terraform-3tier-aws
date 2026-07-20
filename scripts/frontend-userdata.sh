#!/bin/bash
set -e

# Install Nginx
dnf install -y nginx

# Create frontend page
cat > /usr/share/nginx/html/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>3-Tier AWS Architecture</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      background: #f5f5f5;
    }
    .container {
      text-align: center;
      padding: 2rem;
      background: white;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    h1 { color: #232f3e; }
    #status { color: #666; margin-top: 1rem; }
    .success { color: #1b8a2d; }
    .error { color: #d13212; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Hello Andre Rockwell</h1>
    <p>3-Tier AWS Architecture — Dev Environment</p>
    <p id="status">Checking backend connection...</p>
  </div>
  <script>
    fetch('/api/health')
      .then(r => r.json())
      .then(d => {
        const el = document.getElementById('status');
        el.textContent = d.message;
        el.className = 'success';
      })
      .catch(() => {
        const el = document.getElementById('status');
        el.textContent = 'Backend unreachable';
        el.className = 'error';
      });
  </script>
</body>
</html>
HTMLEOF

# Remove default server block to avoid conflict
rm -f /etc/nginx/conf.d/default.conf

# Start and enable Nginx
systemctl enable nginx
systemctl start nginx
