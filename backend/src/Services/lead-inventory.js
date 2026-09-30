export const BUYER_LIMIT = 2;
export const RESERVATION_MS = 10 * 60 * 1000;

export function inventory(lead, now = new Date()) {
  const sold = Math.max(0, Number(lead.buyersCount) || 0);
  const reserved = (lead.reservations || []).filter((r) => new Date(r.expiresAt) > now).length;
  const expired = new Date(lead.expiresAt) <= now;
  return {
    maxBuyers: BUYER_LIMIT,
    remainingSlots: expired ? 0 : Math.max(0, BUYER_LIMIT - sold - reserved),
    reservedSlots: reserved,
    status: expired ? 'EXPIRED' : sold >= BUYER_LIMIT ? 'SOLD_OUT' : reserved + sold >= BUYER_LIMIT ? 'RESERVED' : 'ACTIVE',
  };
}

export class CheckoutError extends Error {
  constructor(code, message, status = 409) {
    super(message);
    this.code = code;
    this.status = status;
  }
}
