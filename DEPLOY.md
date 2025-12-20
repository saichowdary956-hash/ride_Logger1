# Ride Data Logger

Deploy to Render: [![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

## Features

- Vehicle testing and annotation data logger
- Real-time condition tracking
- CSV export functionality
- Auto-save with localStorage
- Notifications at 30 and 40 minutes
- 5 categories: Weather, Road Type, Lighting, Traffic, Speed

## Live Demo

Visit the deployed app at: [Your Render URL will be here]

## Local Development

```bash
npm install
npm start
```

Then visit: http://localhost:3000

## Deploy to Render

1. Push this code to GitHub
2. Go to https://render.com
3. Click "New +" → "Web Service"
4. Connect your GitHub repository
5. Configure:
   - Name: ride-data-logger
   - Environment: Node
   - Build Command: `npm install`
   - Start Command: `npm start`
6. Click "Create Web Service"

Your app will be live at: `https://ride-data-logger.onrender.com`
