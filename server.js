require('dotenv').config();
const express = require('express');
const fs = require('fs');
const path = require('path');
const wol = require('wake_on_lan');
const { exec } = require('child_process');

const app = express();
const PORT = process.env.PORT || 3000;
const DEVICES_FILE = path.join(__dirname, 'devices.json');

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

function readDevices() {
  try {
    return JSON.parse(fs.readFileSync(DEVICES_FILE, 'utf8'));
  } catch {
    return [];
  }
}

function writeDevices(devices) {
  fs.writeFileSync(DEVICES_FILE, JSON.stringify(devices, null, 2));
}

function isValidMac(mac) {
  return /^([0-9A-Fa-f]{2}[:\-]){5}[0-9A-Fa-f]{2}$/.test(mac);
}

function isValidIp(ip) {
  return /^(\d{1,3}\.){3}\d{1,3}$/.test(ip) && ip.split('.').every(n => +n <= 255);
}

function pingHost(ip) {
  return new Promise(resolve => {
    exec(`ping -c 1 -W 1 ${ip}`, { timeout: 3000 }, err => resolve(!err));
  });
}

// GET /api/devices
app.get('/api/devices', (req, res) => {
  res.json(readDevices());
});

// POST /api/devices
app.post('/api/devices', (req, res) => {
  const { name, mac, ip } = req.body;
  if (!name || !name.trim()) {
    return res.status(400).json({ error: 'Name ist erforderlich.' });
  }
  if (!mac || !isValidMac(mac.trim())) {
    return res.status(400).json({ error: 'Ungültige MAC-Adresse.' });
  }
  if (ip && !isValidIp(ip.trim())) {
    return res.status(400).json({ error: 'Ungültige IP-Adresse.' });
  }
  const devices = readDevices();
  const device = { id: Date.now().toString(), name: name.trim(), mac: mac.trim() };
  if (ip && ip.trim()) device.ip = ip.trim();
  devices.push(device);
  writeDevices(devices);
  res.status(201).json(device);
});

// DELETE /api/devices/:id
app.delete('/api/devices/:id', (req, res) => {
  const devices = readDevices();
  const index = devices.findIndex(d => d.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: 'Gerät nicht gefunden.' });
  }
  devices.splice(index, 1);
  writeDevices(devices);
  res.json({ success: true });
});

// POST /api/devices/:id/wake
app.post('/api/devices/:id/wake', (req, res) => {
  const device = readDevices().find(d => d.id === req.params.id);
  if (!device) {
    return res.status(404).json({ error: 'Gerät nicht gefunden.' });
  }
  wol.wake(device.mac, err => {
    if (err) {
      return res.status(500).json({ error: 'Wake-on-LAN fehlgeschlagen: ' + err.message });
    }
    res.json({ success: true, message: `Magic Packet an ${device.name} (${device.mac}) gesendet.` });
  });
});

// PUT /api/devices/:id
app.put('/api/devices/:id', (req, res) => {
  const { name, mac, ip } = req.body;
  if (!name || !name.trim()) return res.status(400).json({ error: 'Name ist erforderlich.' });
  if (!mac || !isValidMac(mac.trim())) return res.status(400).json({ error: 'Ungültige MAC-Adresse.' });
  if (ip && !isValidIp(ip.trim())) return res.status(400).json({ error: 'Ungültige IP-Adresse.' });
  const devices = readDevices();
  const index = devices.findIndex(d => d.id === req.params.id);
  if (index === -1) return res.status(404).json({ error: 'Gerät nicht gefunden.' });
  devices[index] = { id: devices[index].id, name: name.trim(), mac: mac.trim() };
  if (ip && ip.trim()) devices[index].ip = ip.trim();
  writeDevices(devices);
  res.json(devices[index]);
});

// GET /api/status – ping all devices
app.get('/api/status', async (req, res) => {
  const devices = readDevices();
  const results = {};
  await Promise.all(devices.map(async d => {
    results[d.id] = (d.ip && isValidIp(d.ip))
      ? ((await pingHost(d.ip)) ? 'online' : 'offline')
      : 'unknown';
  }));
  res.json(results);
});

app.listen(PORT, () => {
  console.log(`wakeweb läuft auf http://localhost:${PORT}`);
});
