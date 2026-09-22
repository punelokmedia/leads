import { ENV } from "./Config/env.config.js";
import { connectDB } from "./Config/db.connection.config.js";
import { app } from "./app.js";

const PORT = process.env.PORT || 5000;

connectDB()
  .then(() => {
    app.listen(PORT, "0.0.0.0", () => {
      console.log(`Server running on port ${PORT}`);
    });
  })
  .catch((err) => console.error(err));
