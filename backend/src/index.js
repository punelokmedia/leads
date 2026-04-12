import { ENV } from "./Config/env.config.js";
import { connectDB } from "./Config/db.connection.config.js";
import { app } from "./app.js";

const PORT = process.env.PORT || 4000;

connectDB()
  .then(
    app.listen(PORT, () => {
      console.log(`✅ Server is running on port http://localhost:${PORT}`);
    }),
  )
  .catch((err) => console.error(err));
