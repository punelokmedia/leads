import "./Config/env.config.js";
import { connectDB } from "./Config/db.connection.config.js";
import { app } from "./app.js";
import { startPaymentMaintenance } from "./Controllers/orders/payment.controller.js";

const PORT = process.env.PORT || 5000;

if (!process.env.VERCEL) {
  connectDB()
    .then(() => {
      startPaymentMaintenance();
      app.listen(PORT, "0.0.0.0", () => {
        console.log(`Server running on port ${PORT}`);
      });
    })
    .catch((err) => {
      console.error("Server startup failed:", err.message);
      process.exitCode = 1;
    });
}

export default app;
