const express = require("express");
const connectDB = require("./config/db");
const dotenv = require("dotenv").config(); // Load environment variables from .env file
const UserModel = require("./models/user.model");
const Product = require("./models/product.model");
const port = 5000;



//connexion a db
connectDB(); // Connect to MongoDB

const app = express();   

//middleware 
app.use(express.json()); // Parse JSON bodies
app.use(express.urlencoded({ extended: false })); // Parse URL-encoded bodies


app.use("/post", require("./routes/post.routes"));
app.use("/product", require("./routes/product.routes"));
app.use("/stock", require("./routes/stock.routes")); // Ajout des routes de stock
app.use("/chariot", require("./routes/chariot.routes")); // Ajout des routes de chariot

app.use("/cart", require("./routes/cart.routes")); // Add cart routes
app.use("/ewallet", require("./routes/ewallet.routes")); // Add e-wallet routes
app.use("/code", require("./routes/code.routes")); // Add code routes
app.use("/notification", require("./routes/notification.routes")); // Add this line with your other routes


//Lancer le server
app.listen(port, () => {
  console.log("Server is running on port " + port);
});

