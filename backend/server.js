const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const dotenv = require("dotenv");

const authRoutes = require("./routes/authRoutes");
const portfolioRoutes = require("./routes/portfolioRouters");

dotenv.config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Authentication Routes
app.use("/api/auth", authRoutes);

// Portfolio Routes
app.use("/api/portfolio", portfolioRoutes);

// MongoDB Connection
mongoose
  .connect("mongodb://127.0.0.1:27017/FinSightDB")
  .then(() => {
    console.log("MongoDB Connected Successfully!");
  })
  .catch((error) => {
    console.log("MongoDB Connection Error:", error.message);
  });

// Test Route
app.get("/", (req, res) => {
  res.send("FinSight Backend is Running!");
});

// Start Server
const PORT = 5000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});