# 💰 FinSight

### **Track. Analyze. Grow.**

FinSight is a personal financial intelligence platform designed to help users manage and understand their complete financial ecosystem in one place.

Instead of maintaining financial information across multiple applications, spreadsheets, and platforms, FinSight provides a unified dashboard for tracking investments, expenses, savings, SIPs, mutual funds, PF contributions, and financial goals.

---

## 🚀 About the Project

Managing personal finances can often be complicated because financial information is scattered across different platforms.

For example, users may track:

* 💳 Daily expenses separately
* 📈 Mutual fund investments on another platform
* 🔄 SIP investments separately
* 🏦 PF contributions elsewhere
* 🎯 Financial goals manually using spreadsheets

FinSight aims to solve this problem by providing a centralized platform where users can organize, monitor, and analyze their financial information.

---

## 🎯 Problem Statement

Many individuals lack a unified system to track their complete financial portfolio.

Financial information is often distributed across:

* Excel spreadsheets
* Banking applications
* Investment platforms
* Mutual fund applications
* PF portals

This makes it difficult for users to understand their overall financial position and make informed financial decisions.

---

## 💡 Solution

FinSight provides a centralized financial dashboard that enables users to:

* Track income and expenses
* Monitor mutual fund investments
* Manage SIP investments
* Track PF contributions
* Monitor savings
* Set financial goals
* Visualize financial data using analytics
* Generate meaningful insights about financial health

---

# ✨ Key Features

## 🔐 User Authentication

* User Registration
* Secure Login
* Personalized Financial Dashboard

---

## 📊 Financial Dashboard

The dashboard provides an overview of the user's financial information, including:

* 💰 Total Net Worth
* 📈 Total Investments
* 💳 Monthly Expenses
* 💵 Monthly Savings
* 🏦 PF Balance
* 📊 Mutual Fund Portfolio Value

---

## 📈 Mutual Fund Tracker

Users can track their mutual fund investments by storing:

* Fund Name
* Investment Amount
* Current Value
* Investment Date
* Returns

FinSight can calculate investment performance and portfolio growth.

---

## 🔄 SIP Tracker

The SIP module allows users to manage recurring investments.

Features include:

* SIP Name
* Monthly Investment Amount
* Start Date
* Investment Frequency
* Total Investment
* Current Portfolio Value
* Upcoming SIP Information

---

## 🏦 PF Tracker

Users can track their Provident Fund details, including:

* Employee Contribution
* Employer Contribution
* Monthly Contribution
* Current PF Balance

---

## 💳 Expense Tracker

Users can record and categorize their expenses.

Example categories include:

* 🍔 Food
* 🚗 Travel
* 🛍️ Shopping
* 📚 Education
* 🏠 Housing
* 🎬 Entertainment

The system provides visual analytics to help users understand their spending habits.

---

## 🎯 Financial Goals

Users can create and monitor financial goals.

Examples:

* 🏠 Buying a House
* 🚗 Buying a Car
* 🎓 Education
* ✈️ Travel
* 💰 Emergency Fund

FinSight displays progress toward each financial goal.

---

## 🤖 Smart Financial Insights

FinSight analyzes financial information and generates useful insights.

Examples:

> 💡 Your monthly expenses increased compared to the previous month.

> 📈 Your investment portfolio has shown positive growth.

> 🎯 You are making progress toward your financial goals.

> 💰 Your savings rate can be improved to achieve your goals faster.

---

## 💚 Financial Health Score

FinSight can generate a Financial Health Score based on factors such as:

* Savings habits
* Expense patterns
* Investment activity
* Financial goal progress
* Overall financial consistency

This provides users with a simple way to understand their overall financial health.

---

# 🛠️ Tech Stack

## 📱 Frontend

* Flutter
* Dart

## ⚙️ Backend

* Node.js
* Express.js

## 🗄️ Database

* MongoDB

## 📊 Data Visualization

* Charts and Analytics

---

# 🏗️ Project Structure

```text
FinSight/
│
├── frontend/                 # Flutter Application
│   └── lib/
│       ├── screens/          # Application Screens
│       ├── widgets/          # Reusable UI Components
│       ├── models/           # Data Models
│       ├── services/         # API Services
│       └── utils/            # Utility Functions
│
├── backend/                  # Node.js Backend
│   ├── controllers/          # Application Logic
│   ├── models/               # MongoDB Models
│   ├── routes/               # API Routes
│   ├── middleware/           # Middleware
│   ├── config/               # Configuration Files
│   └── server.js             # Backend Entry Point
│
├── docs/                     # Project Documentation
│
└── README.md
```

---

# 🔗 Planned Modules

```text
                ┌─────────────────┐
                │    FinSight     │
                │ Financial Hub   │
                └────────┬────────┘
                         │
       ┌─────────────────┼─────────────────┐
       │                 │                 │
       ▼                 ▼                 ▼
   Dashboard         Investments        Expenses
       │                 │                 │
       ▼                 ▼                 ▼
 Financial Score    MF / SIP / PF      Analytics
       │
       ▼
 Smart Insights
```

---

# 📱 Application Workflow

```text
User
 │
 ▼
Login / Register
 │
 ▼
Financial Dashboard
 │
 ├── 💳 Expenses
 │
 ├── 📈 Mutual Funds
 │
 ├── 🔄 SIP Tracker
 │
 ├── 🏦 PF Tracker
 │
 ├── 🎯 Financial Goals
 │
 └── 🤖 Smart Insights
```

---

# 🔌 Planned API Endpoints

## Authentication

```text
POST /api/auth/register
POST /api/auth/login
```

## Dashboard

```text
GET /api/dashboard
```

## Expenses

```text
POST /api/expenses
GET /api/expenses
DELETE /api/expenses/:id
```

## Investments

```text
POST /api/investments
GET /api/investments
PUT /api/investments/:id
DELETE /api/investments/:id
```

## SIP

```text
POST /api/sip
GET /api/sip
PUT /api/sip/:id
DELETE /api/sip/:id
```

## PF

```text
POST /api/pf
GET /api/pf
```

## Financial Goals

```text
POST /api/goals
GET /api/goals
PUT /api/goals/:id
DELETE /api/goals/:id
```

## Smart Insights

```text
GET /api/insights
GET /api/financial-health-score
```

---

# 🔮 Future Enhancements

* 🤖 AI-powered financial assistant
* 🔔 SIP and bill reminders
* 📈 Real-time mutual fund data
* 🏦 Bank account integration
* 📄 Financial report generation
* 📱 Mobile notifications
* 🔐 Advanced security and encryption
* ☁️ Cloud synchronization
* 📊 Advanced investment analytics

---

# 🎯 Project Goal

The goal of FinSight is to simplify personal finance management by providing users with a single platform to track, analyze, and understand their financial information.

FinSight focuses on transforming raw financial data into meaningful insights that can help users make better financial decisions.

---

# 🚧 Development Status

**Project Status: Planning & Preparation Phase**

The project architecture, features, and development workflow are currently being finalized.

Development will focus on building a functional financial management platform with an intuitive user experience and meaningful financial analytics.

---

# 👩‍💻 Developer

**Prarthana P Rao**

Computer Science & Engineering — Data Science

---

## ⭐ FinSight

### **Track your money. Understand your finances. Build your future.**

If you like this project, consider giving the repository a ⭐!
