const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const dotenv = require("dotenv");

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json());

// Authentication Routes
const authRoutes = require("./routes/authRoutes");

app.use("/api/auth", authRoutes);

// MongoDB Connection
mongoose
  .connect("mongodb://127.0.0.1:27017/FinSightDB")
  .then(() => console.log("MongoDB Connected Successfully!"))
  .catch((error) =>
    console.log("MongoDB Connection Error:", error.message)
  );

// Test Route
app.get("/", (req, res) => {
  res.send("FinSight Backend is Running!");
});

const PORT = 5000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});