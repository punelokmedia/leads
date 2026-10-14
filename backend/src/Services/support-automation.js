import { SupportMessage } from '../Models/supportMessage.model.js';
export const SUPPORT_HELP = {
  PAYMENT: 'Open purchase history and check whether the order is listed. If payment was deducted but the order is missing, select Still need help and share the order/payment reference. Do not share OTPs, passwords or card details, and avoid paying again until the first payment is checked.',
  WALLET: 'Refresh your wallet balance and transaction history. If a top-up is missing, select Still need help and share the payment reference and time. This automated assistant cannot confirm payments or change your balance.',
  LEAD_QUALITY: 'Open the purchased lead in your history and describe what is incorrect. Select Still need help for a representative to review the lead. This message does not approve a refund.',
  DOWNLOAD: 'Open purchase history, select the paid order and retry Download with a working internet connection. If it still fails, select Still need help and mention the order ID and error.',
  MEMBERSHIP: 'Refresh your profile and check your membership information and wallet transaction history. If membership is still unavailable after payment, select Still need help and share the payment reference.',
  REFERRAL: 'Open your referral section and check your referral ID and reward history. Rewards depend on eligibility rules. Select Still need help if you want a representative to review a missing reward.',
  ACCOUNT: 'Try signing in again if your session ended. Use the password recovery option if needed. Select Still need help if access is still unavailable. Never send your password or OTP in this chat.',
  OTHER: 'Describe the issue and any error message. Select Still need help to request a human representative. Automated guidance cannot make account or payment changes.',
};
export async function automatedMessage(ticket, choice) {
  const text = choice === 'START'
    ? 'I am the automated support assistant. Choose an issue below for guidance. If this does not solve your problem, select Still need help to request a human representative.'
    : choice === 'HUMAN'
      ? 'Your ticket has been transferred to the human support queue. A representative will reply here when available. You can add more details below; no representative has been assigned by this automated message.'
      : SUPPORT_HELP[choice];
  const key = { user: ticket.user, author: ticket.user, ticket: ticket._id, clientId: `automated-${ticket._id}-${choice}` };
  try { return await SupportMessage.findOneAndUpdate(key, { $setOnInsert: { ...key, sender: 'automated', text } }, { upsert: true, returnDocument: 'after', runValidators: true }); }
  catch (error) { if (error.code !== 11000) throw error; return SupportMessage.findOne(key); }
}
