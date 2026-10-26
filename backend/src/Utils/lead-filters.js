export function applyLeadFilters(query, filters) {
  const price = {};
  for (const [key, operator] of [['priceMin', '$gte'], ['priceMax', '$lte']]) {
    if (filters[key] === undefined) continue;
    const value = Number(filters[key]);
    if (typeof filters[key] !== 'string' || !filters[key].trim() || !Number.isFinite(value) || value < 0 || value > 5000) throw new Error('Lead price must be between ₹0 and ₹5,000.');
    price[operator] = value;
  }
  if (price.$gte !== undefined && price.$lte !== undefined && price.$gte > price.$lte) throw new Error('Minimum lead price must not exceed maximum.');
  if (Object.keys(price).length) query.price = price;
  for (const [param, field] of [['projectTypes', 'requirement'], ['propertyTypes', 'propertyType']]) {
    if (filters[param] === undefined) continue;
    if (typeof filters[param] !== 'string' || filters[param].length > 500) throw new Error('Invalid filter options.');
    const items = filters[param].split(',').map(value => value.trim()).filter(Boolean);
    if (items.length > 20) throw new Error('Too many filter options.');
    if (items.length) query[field] = { $in: items.map(value => new RegExp(`^${value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i')) };
  }
  const bounds = {};
  for (const key of ['budgetMin', 'budgetMax']) {
    if (filters[key] === undefined) continue;
    const value = Number(filters[key]);
    if (typeof filters[key] !== 'string' || !filters[key].trim() || !Number.isFinite(value) || value < 0) throw new Error('Invalid budget range.');
    bounds[key] = value;
  }
  if (bounds.budgetMin !== undefined && bounds.budgetMax !== undefined && bounds.budgetMin > bounds.budgetMax) throw new Error('Minimum budget must not exceed maximum budget.');
  if (Object.keys(bounds).length) {
    // Older leads store only a display range. Read it without rewriting records.
    const numbers = { $map: {
      input: { $regexFindAll: { input: { $toLower: { $replaceAll: { input: { $ifNull: ['$budgetRange', ''] }, find: ',', replacement: '' } } }, regex: '([0-9]+(?:\\.[0-9]+)?)\\s*(crores?|cr|lakhs?|lacs?|k)?' } },
      as: 'match', in: { $multiply: [
        { $convert: { input: { $arrayElemAt: ['$$match.captures', 0] }, to: 'double', onError: 0 } },
        { $switch: { branches: [
          { case: { $in: [{ $arrayElemAt: ['$$match.captures', 1] }, ['crore', 'crores', 'cr']] }, then: 10000000 },
          { case: { $in: [{ $arrayElemAt: ['$$match.captures', 1] }, ['lakh', 'lakhs', 'lac', 'lacs']] }, then: 100000 },
          { case: { $eq: [{ $arrayElemAt: ['$$match.captures', 1] }, 'k'] }, then: 1000 },
        ], default: 1 } },
      ] },
    } };
    const low = { $ifNull: ['$budget.min', { $min: '$$numbers' }] };
    const high = { $ifNull: ['$budget.max', { $max: '$$numbers' }] };
    const conditions = [{ $ne: [low, null] }, { $ne: [high, null] }];
    if (bounds.budgetMin !== undefined) conditions.push({ $gte: [high, bounds.budgetMin] });
    if (bounds.budgetMax !== undefined) conditions.push({ $lte: [low, bounds.budgetMax] });
    query.$expr = { $let: { vars: { numbers }, in: { $and: conditions } } };
  }
  const dates = {};
  for (const [key, operator] of [['postedFrom', '$gte'], ['postedTo', '$lt']]) {
    if (filters[key] === undefined) continue;
    if (typeof filters[key] !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(filters[key])) throw new Error('Invalid posted date.');
    const calendarDate = new Date(`${filters[key]}T00:00:00Z`);
    if (!Number.isFinite(calendarDate.getTime()) || calendarDate.toISOString().slice(0, 10) !== filters[key]) throw new Error('Invalid posted date.');
    const date = new Date(`${filters[key]}T00:00:00+05:30`);
    if (key === 'postedTo') date.setUTCDate(date.getUTCDate() + 1);
    dates[operator] = date;
  }
  if (dates.$gte && dates.$lt && dates.$gte >= dates.$lt) throw new Error('Invalid posted date range.');
  if (Object.keys(dates).length) query.createdAt = dates;
}
