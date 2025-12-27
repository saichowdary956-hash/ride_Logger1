# DataLogger Deployment Guide

## Quick Deployment to Render

Your app is ready to deploy! Follow these simple steps:

### Step 1: Install Git (if not already installed)

1. Close this terminal
2. Download Git from: https://git-scm.com/download/win
3. Install with default options
4. Restart VS Code or open a new PowerShell terminal

### Step 2: Initialize Git Repository

Open a new PowerShell terminal in VS Code and run:

```powershell
cd c:\Users\gotti\Documents\datalogger
git init
git add .
git commit -m "Initial commit - DataLogger ride logger app"
```

### Step 3: Create GitHub Repository

1. Go to: https://github.com/new
2. Repository name: `datalogger` or `ride-logger`
3. Make it **Public**
4. **Don't** add README, .gitignore, or license
5. Click "Create repository"

### Step 4: Push to GitHub

After creating the repository, run these commands (replace YOUR_USERNAME and YOUR_REPO):

```powershell
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

### Step 5: Deploy on Render

1. Go to: https://render.com
2. Sign in (or create account - it's free!)
3. Click **"New +"** → **"Web Service"**
4. Click **"Connect GitHub"** and authorize Render
5. Select your `datalogger` repository
6. Render will auto-detect the settings from `render.yaml`
7. Click **"Create Web Service"**
8. Wait 2-3 minutes for deployment

### Step 6: Get Your Public URL

Once deployed, Render will give you a URL like:
`https://ride-logger.onrender.com`

Your app will be live and accessible from anywhere!

---

## Alternative: Deploy on Netlify

If you prefer Netlify instead:

1. Go to: https://app.netlify.com
2. Drag and drop the entire `datalogger` folder
3. Your site will be live instantly!
4. You'll get a URL like: `https://your-site-name.netlify.app`

---

## Files Already Configured ✅

- ✅ `server.js` - Express server ready
- ✅ `package.json` - Dependencies configured
- ✅ `render.yaml` - Deployment settings
- ✅ `ride_logger.html` - Main app file

---

## Need Help?

If you get stuck:
1. Make sure Git is installed: `git --version`
2. Make sure you're in the right directory: `pwd`
3. Check if remote is set: `git remote -v`

## Test Locally First

Before deploying, test locally:

```powershell
npm install
npm start
```

Then open: http://localhost:3000

---

**Your app is ready to go live! 🚀**
