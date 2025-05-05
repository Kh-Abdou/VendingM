const express = require("express");
const connectDB = require("./config/db");
const dotenv = require("dotenv").config(); // Load environment variables from .env file
const cors = require("cors"); // Ajout de CORS
const UserModel = require("./models/user.model");
const Product = require("./models/product.model");
const port = 5000;

//connexion a db
connectDB(); // Connect to MongoDB

const app = express();   

//middleware 
app.use(cors()); // Activer CORS pour toutes les routes
app.use(express.json()); // Parse JSON bodies
app.use(express.urlencoded({ extended: false })); // Parse URL-encoded bodies

// Routes
app.use("/user", require("./routes/post.routes")); // Changement de /post à /user pour clarté
app.use("/product", require("./routes/product.routes"));
app.use("/stock", require("./routes/stock.routes")); 
app.use("/chariot", require("./routes/chariot.routes")); 
app.use("/cart", require("./routes/cart.routes")); 
app.use("/ewallet", require("./routes/ewallet.routes")); 
app.use("/code", require("./routes/code.routes")); 
app.use("/notification", require("./routes/notification.routes"));

// Route de test simple pour vérifier que le serveur fonctionne
app.get("/", (req, res) => {
  res.json({ message: "API is running correctly" });
});

//Lancer le server
app.listen(port, () => {
  console.log("Server is running on port " + port);
});

