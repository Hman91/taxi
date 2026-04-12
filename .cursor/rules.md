# Project Rules — Taxi App

## Backend (Flask)
- Use Flask with Blueprints
- Separate routes from business logic
- All endpoints return JSON
- Use JWT for authentication
- Do not mix logic inside routes

## Frontend (Flutter)
- Use clean architecture (UI / services / models)
- No business logic inside widgets
- API calls must go through service layer
- Keep UI simple and readable

## Database (SQLite)
- Tables: users, drivers, rides
- Use foreign keys
- Avoid duplicated data

## Domain Logic
- Users can request rides
- Drivers accept/reject rides
- One active ride per user
- Ride statuses: pending, accepted, ongoing, completed

## General Rules
- Do not rewrite entire files unless asked
- Modify only necessary parts
- Keep code simple (no over-engineering)
- Add comments for important logic
- all newly added texts should be avalable in theses languages: [Arab, French, english, german, Spanish, chinease, russian, italian]