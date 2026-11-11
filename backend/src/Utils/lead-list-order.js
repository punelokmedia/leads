import { BUYER_LIMIT } from '../Services/lead-inventory.js';

// Compute availability at query time so expired reservations cannot bury a lead.
export function leadListOrder(sort = 'latest', now = new Date()) {
  const secondary = sort === 'cheapest' ? { price: 1 } : sort === 'expensive' ? { price: -1 } : {};
  return [
    { $set: { _unavailable: { $cond: [{ $and: [
      { $not: [{ $lte: ['$expiresAt', now] }] },
      { $lt: [{ $add: [
        { $max: [0, { $ifNull: ['$buyersCount', 0] }] },
        { $size: { $filter: { input: { $ifNull: ['$reservations', []] }, as: 'reservation', cond: { $gt: ['$$reservation.expiresAt', now] } } } },
      ] }, BUYER_LIMIT] },
    ] }, 0, 1] } } },
    { $sort: { _unavailable: 1, ...secondary, createdAt: -1, _id: -1 } },
  ];
}
