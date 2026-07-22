# TradeMentor Web Build & Deployment Hub

This folder is designed to host configurations and production build artifacts compiled from the single Flutter codebase (`mobile_app/`).

## 📁 Files
* 📄 `vercel.json` - Single Page Application URL rewrites for Vercel Hosting.
* 📄 `netlify.toml` - Redirection rules for Netlify Hosting.

## 🚀 How to build and deploy
To build the latest web code, run the appropriate batch script from the root `deployment/` directory:
- Use `deploy_vercel.bat` for automatic Vercel deployment.
- Use `deploy_netlify.bat` for automatic Netlify deployment.
- Use `deploy_web_firebase.bat` for Firebase Hosting.
