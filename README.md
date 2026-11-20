# CampusFlow AI (Competition Edition — Local MongoDB Compass)

CampusFlow AI is an enterprise-grade Smart Campus Operations, Issue Ticketing, and AI Triaging Platform.

## Architecture
- **Backend (`/server`)**: Node.js, Express, Mongoose, MongoDB Compass (local), JWT Auth, Multer, Nodemailer, AI Triaging Service.
- **Frontend (`/client`)**: React (Vite), Tailwind CSS, Chart.js, Heroicons, Axios.
- **Mobile (`/mobile`)**: Flutter (Cross-platform iOS/Android), HTTP, Shared Preferences.

## Quick Start on Windows 11
1. Run `setup-windows.bat` in command prompt or PowerShell.
2. Ensure MongoDB Compass is running locally at `mongodb://localhost:27017`.
3. Start backend: `cd server && npm run dev`
4. Start frontend: `cd client && npm run dev`
5. Seed database (optional): `cd server && npm run seed`
