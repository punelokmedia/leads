// Reject query operators and prototype paths before controllers construct database queries.
export function invalidInput(value, depth = 0) {
  if (depth > 20) return true;
  if (!value || typeof value !== 'object') return false;
  return Object.entries(value).some(([key, child]) =>
    key.startsWith('$') || key.includes('.') || ['__proto__', 'prototype', 'constructor'].includes(key) || invalidInput(child, depth + 1));
}
export function requestSecurity(req, res, next) {
  if (invalidInput(req.body) || invalidInput(req.query) || invalidInput(req.params)) {
    return res.status(400).json({ success: false, message: 'Invalid request fields.' });
  }
  next();
}
export function safeErrors(error, _req, res, next) {
  if (res.headersSent) return next(error);
  const status = error.type === 'entity.too.large' ? 413 :
    error.type === 'entity.parse.failed' || error.name === 'MulterError' ? 400 : 500;
  return res.status(status).json({ success: false, message: status === 413 ? 'Request is too large.' : status === 400 ? 'Invalid request.' : 'Unable to process request.' });
}
