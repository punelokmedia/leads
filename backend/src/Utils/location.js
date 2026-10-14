export function parseCoordinates(latitude, longitude) {
  const valid = (value) => (typeof value === 'number' || (typeof value === 'string' && value.trim() !== '')) && Number.isFinite(Number(value));
  if (!valid(latitude) || !valid(longitude) || Math.abs(Number(latitude)) > 90 || Math.abs(Number(longitude)) > 180) {
    throw new Error('Valid latitude (-90 to 90) and longitude (-180 to 180) are required.');
  }
  return { type: 'Point', coordinates: [Number(longitude), Number(latitude)] };
}
