# 🚀 API Rate Limit Testing Script (PowerShell)

This project is a PowerShell-based tool to test API rate limits, track response sizes, and detect throttling (HTTP 429).

---

## 📌 Features

- 🔁 Automated API hit testing
- ⏱ Configurable request count & delay
- 🔐 Token-based authentication support
- 📉 Detects rate limiting (429)
- 🔄 Auto token refresh on 401
- 📊 Logs response size per request
- 📁 Exports results to CSV

---

## ⚙️ Configuration

This script uses **environment variables** for security:

### Required Environment Variables

| Variable | Description |
|----------|------------|
| `TOKEN_URL` | API token generation endpoint |
| `API_USERNAME` | API username |
| `API_PASSWORD` | API password |

---

## 🛠️ Setup

### 1. Set environment variables (Windows PowerShell)

```powershell
setx TOKEN_URL "https://your-api/token"
setx API_USERNAME "your_username"
setx API_PASSWORD "your_password"
