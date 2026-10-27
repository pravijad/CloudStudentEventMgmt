# Cloud Student Event Management

> **This fork adds Terraform infrastructure for Azure.** I rebuilt the app's hosting as code: App Service, PostgreSQL, Blob Storage, Key Vault with managed identity, a reusable module and remote state. See [infra/README.md](infra/README.md) for the architecture and how to run it.

## Description
A full-stack web application for managing student events.

## Tech Stack
- Frontend: React
- Backend: Node.js, Express
- Database: PostgreSQL

## Features
- User authentication (JWT)
- Create and manage events
- Event registration
- Role-based access

## Setup
1. Clone the repo
2. Copy `backend/.env.example` to `backend/.env` and fill in your values
3. Run backend: `cd backend && npm install && npm run dev`
4. Run frontend: `cd frontend && npm install && npm start`

## Deployment
CI/CD is handled via GitHub Actions. Pushing changes to `backend/` or `frontend/` on `main` triggers automatic deployment of the affected app to Azure App Service. Azure App Settings and GitHub Secrets must be configured first.
