import '../src/Config/env.config.js';
import mongoose from 'mongoose';
import { connectDB } from '../src/Config/db.connection.config.js';
import { WalletEntry } from '../src/Models/wallet.model.js';
import { User } from '../src/Models/user.model.js';
import { ledgerSignature, exportSecurityAudit } from '../src/Services/security-audit.js';

try {
  await connectDB();
  if (process.argv.includes('--export')) await exportSecurityAudit();
  let unsigned = 0, tampered = 0, mismatches = 0;
  if (!process.env.WALLET_LEDGER_HMAC_KEY) throw new Error('Ledger verification key required');
  for await (const entry of WalletEntry.find().select('+signature').cursor()) {
    if (!entry.signature) unsigned++;
    else if (entry.signature !== ledgerSignature(entry)) tampered++;
  }
  for await (const user of User.find({ role: 'USER' }).select('+walletBalancePaise +walletDebtPaise').cursor()) {
    const totals = await WalletEntry.aggregate([{ $match: { user: user._id } }, { $group: { _id: null, sum: { $sum: '$amountPaise' } } }]);
    if ((totals[0]?.sum || 0) !== (user.walletBalancePaise || 0) - (user.walletDebtPaise || 0)) mismatches++;
  }
  console.log(JSON.stringify({ unsigned, tampered, mismatches }));
  if (unsigned || tampered || mismatches) process.exitCode = 1;
} catch (error) { console.error('Wallet security check failed:', error.message); process.exitCode = 1; }
finally { await mongoose.disconnect(); }
