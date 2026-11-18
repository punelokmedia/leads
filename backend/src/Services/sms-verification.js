import crypto from 'node:crypto';

// Phone OTP delivery. Production uses Twilio Verify: Twilio generates, sends and
// checks the code, so the backend never sees or stores a production OTP.
// Outside production, SMS_PROVIDER=local (or missing Twilio config) falls back to a
// locally generated code that is returned to the developer in the API response.

export const PHONE_OTP_PURPOSE = Object.freeze({ LOGIN: 'LOGIN', PHONE_CHANGE: 'PHONE_CHANGE' });
// Twilio Verify's default code validity. Keep in sync with the Verify service setting.
export const PHONE_OTP_TTL_MS = 10 * 60 * 1000;
export const PHONE_OTP_RESEND_COOLDOWN_MS = 30 * 1000;

const TWILIO_TIMEOUT_MS = 10 * 1000;
let twilioFetch = (...args) => globalThis.fetch(...args);

/** Test hook: replace the HTTP client used for Twilio calls. Returns a restore function. */
export function setTwilioFetch(implementation) {
  const previous = twilioFetch;
  twilioFetch = implementation;
  return () => { twilioFetch = previous; };
}

export class SmsProviderError extends Error {
  constructor(message, { status, providerCode } = {}) {
    super(message);
    this.name = 'SmsProviderError';
    this.status = status;
    this.providerCode = providerCode;
  }
}

const isProduction = () => process.env.NODE_ENV === 'production';

const twilioConfig = (purpose) => {
  const env = process.env;
  const serviceSid = (purpose === PHONE_OTP_PURPOSE.PHONE_CHANGE && env.TWILIO_VERIFY_PHONE_CHANGE_SERVICE_SID) || env.TWILIO_VERIFY_SERVICE_SID;
  let username, password;
  if (env.TWILIO_API_KEY_SID && env.TWILIO_API_KEY_SECRET) [username, password] = [env.TWILIO_API_KEY_SID, env.TWILIO_API_KEY_SECRET];
  else if (env.TWILIO_ACCOUNT_SID && env.TWILIO_AUTH_TOKEN) [username, password] = [env.TWILIO_ACCOUNT_SID, env.TWILIO_AUTH_TOKEN];
  if (!serviceSid || !username || !password) return null;
  return { serviceSid, authorization: 'Basic ' + Buffer.from(`${username}:${password}`).toString('base64') };
};

/**
 * Which provider handles phone OTPs right now: 'twilio', 'local' (non-production only),
 * or null when SMS cannot be delivered.
 */
export function phoneOtpProvider(purpose = PHONE_OTP_PURPOSE.LOGIN) {
  const requested = String(process.env.SMS_PROVIDER || '').trim().toLowerCase();
  if (requested === 'local') return isProduction() ? null : 'local';
  if (twilioConfig(purpose)) return 'twilio';
  return isProduction() ? null : 'local';
}

export const toE164India = (tenDigitPhone) => `+91${tenDigitPhone}`;
const maskPhone = (phone) => `******${String(phone).slice(-4)}`;
export const hashLocalCode = (code, binding) =>
  crypto.createHash('sha256').update(`${binding.purpose}:${binding.phoneNumber}:${code}`).digest('hex');

async function twilioRequest(purpose, path, form) {
  const config = twilioConfig(purpose);
  if (!config) throw new SmsProviderError('Twilio Verify is not configured.', { status: 503 });
  let response;
  try {
    response = await twilioFetch(`https://verify.twilio.com/v2/Services/${encodeURIComponent(config.serviceSid)}/${path}`, {
      method: 'POST',
      headers: { Authorization: config.authorization, 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams(form).toString(),
      signal: AbortSignal.timeout(TWILIO_TIMEOUT_MS),
    });
  } catch (error) {
    throw new SmsProviderError(`Twilio request failed: ${error.name}`);
  }
  let body = {};
  try { body = await response.json(); } catch { /* non-JSON error page */ }
  return { status: response.status, ok: response.ok, body };
}

/**
 * Ask Twilio to send a code. Resolves with the Verification SID only once Twilio
 * has accepted the request; throws SmsProviderError otherwise.
 */
export async function startTwilioVerification({ purpose, phoneNumber }) {
  const result = await twilioRequest(purpose, 'Verifications', { To: toE164India(phoneNumber), Channel: 'sms' });
  if (!result.ok || result.body?.status !== 'pending' || !result.body?.sid) {
    console.error(`Twilio Verify send rejected for ${maskPhone(phoneNumber)}: HTTP ${result.status}, code ${result.body?.code ?? 'n/a'}`);
    throw new SmsProviderError('Twilio did not accept the verification request.', { status: result.status, providerCode: result.body?.code });
  }
  return { verificationSid: result.body.sid };
}

/**
 * Check a code with Twilio. Returns true only for an approved verification for
 * the same phone number and Verification SID that this binding started.
 */
export async function checkTwilioVerification({ purpose, phoneNumber, code, verificationSid }) {
  const result = await twilioRequest(purpose, 'VerificationCheck', { To: toE164India(phoneNumber), Code: code });
  // 404: no pending verification (expired, already approved or too many attempts).
  if (result.status === 404) return false;
  if (!result.ok) {
    console.error(`Twilio Verify check failed for ${maskPhone(phoneNumber)}: HTTP ${result.status}, code ${result.body?.code ?? 'n/a'}`);
    throw new SmsProviderError('Twilio verification check failed.', { status: result.status, providerCode: result.body?.code });
  }
  const { status, valid, to, sid } = result.body ?? {};
  return status === 'approved' && valid === true && to === toE164India(phoneNumber) && sid === verificationSid;
}

/** Generate a dev-only local code. Never used in production. */
export function createLocalCode() {
  if (isProduction()) throw new SmsProviderError('Local OTP codes are disabled in production.', { status: 503 });
  return crypto.randomInt(0, 1_000_000).toString().padStart(6, '0');
}
