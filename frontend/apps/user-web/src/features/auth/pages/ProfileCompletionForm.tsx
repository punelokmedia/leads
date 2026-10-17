import { Link } from 'react-router-dom'
import './profile-completion.css'

type ProfileDetails = {
  fullName: string
  businessName: string
  email: string
  city: string
  workType: string
}

type Props = {
  details: ProfileDetails
  onChange: (field: keyof ProfileDetails, value: string) => void
  workTypes: { id: string; label: string }[]
  isWorkTypeLoading: boolean
  referralCode: string
  onReferralChange: (value: string) => void
  onContinue: () => Promise<void>
  isLoading: boolean
  error: string
  success: string
}

export function ProfileCompletionForm({
  details, onChange, workTypes, isWorkTypeLoading, referralCode,
  onReferralChange, onContinue, isLoading, error, success,
}: Props) {
  return (
    <div className="profile-setup-page">
      <img className="profile-setup-background" src="/NextLead Arrow only.png" alt="" aria-hidden="true" />
      <section className="profile-setup-card" aria-labelledby="profile-setup-title">
        <Link className="profile-setup-close" to="/">Close</Link>
        <h1 id="profile-setup-title">Complete your profile</h1>
        <p className="profile-setup-subtitle">Tell us about yourself and your business.</p>
        <form onSubmit={event => { event.preventDefault(); void onContinue() }}>
          <fieldset disabled={isLoading}>
            <label htmlFor="setup-full-name">Full name <span>*</span></label>
            <input id="setup-full-name" name="fullName" autoComplete="name" required value={details.fullName} onChange={event => onChange('fullName', event.target.value)} placeholder="Enter your full name" />

            <label htmlFor="setup-business">Business/Company Name <span>*</span></label>
            <input id="setup-business" name="businessName" autoComplete="organization" required value={details.businessName} onChange={event => onChange('businessName', event.target.value)} placeholder="Enter your business name" />

            <label htmlFor="setup-email">Email address <span>*</span></label>
            <input id="setup-email" name="email" type="email" autoComplete="email" required value={details.email} onChange={event => onChange('email', event.target.value)} placeholder="you@company.com" />

            <label htmlFor="setup-city">City <span>*</span></label>
            <input id="setup-city" name="city" autoComplete="address-level2" required value={details.city} onChange={event => onChange('city', event.target.value)} placeholder="Enter your city" />

            <label htmlFor="setup-work-type">Work type <span>*</span></label>
            <select id="setup-work-type" name="workType" required disabled={isWorkTypeLoading} value={details.workType} onChange={event => onChange('workType', event.target.value)}>
              <option value="">{isWorkTypeLoading ? 'Loading service categories...' : 'Select your service category'}</option>
              {workTypes.map(option => <option key={option.id} value={option.label}>{option.label}</option>)}
            </select>

            <label className="profile-setup-referral-label" htmlFor="setup-referral">Referral code <small>Optional</small></label>
            <input id="setup-referral" name="referralCode" value={referralCode} onChange={event => onReferralChange(event.target.value)} maxLength={26} autoCapitalize="characters" autoComplete="off" spellCheck={false} placeholder="Enter referral code if you have one" />

            {error && <p className="profile-setup-error" role="alert">{error}</p>}
            {success && <p className="profile-setup-success" role="status">{success}</p>}
            <button type="submit" disabled={isLoading || isWorkTypeLoading}>{isLoading ? 'Saving...' : 'Continue'}</button>
          </fieldset>
        </form>
        <p className="profile-setup-note">This helps us connect you with relevant leads.</p>
      </section>
    </div>
  )
}
