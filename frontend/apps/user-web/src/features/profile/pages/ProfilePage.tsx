import { useUserToken } from '@/features/auth/useUserToken'
import { apiFetch } from '@/features/auth/session'
import { RowsSkeleton } from '@/components/loading/Skeleton'
import { useEffect, useState, type FormEvent, type ChangeEvent } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { API_BASE_URL } from '@/config/api'
import './profile.css'

export function ProfilePage() {
  const navigate = useNavigate()
  const [isLoading, setIsLoading] = useState(false)
  const [authError, setAuthError] = useState('')
  const [authSuccess, setAuthSuccess] = useState('')
  const [isProfileLoading, setIsProfileLoading] = useState(true)
  const [accountForm, setAccountForm] = useState({
    firstname: '',
    lastname: '',
    phoneNumber: '',
    email: '',
  })
  const [savedAccountForm, setSavedAccountForm] = useState(accountForm)
  const [addressForm, setAddressForm] = useState({
    label: 'HOME',
    street: '',
    landmark: '',
    city: '',
    state: '',
    country: '',
    zipcode: '',
  })
  const [isAddressFormOpen, setIsAddressFormOpen] = useState(false)
  const [isEditingProfile, setIsEditingProfile] = useState(false)
  const [profilePic, setProfilePic] = useState('')
  const [photoBusy, setPhotoBusy] = useState(false)
  const [photoOptionsOpen, setPhotoOptionsOpen] = useState(false)
  const userToken = useUserToken()
  const uploadPhoto = async (file: File) => {
    if (!userToken || photoBusy) return
    resetAuthMessages()
    if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type) || file.size > 2 * 1024 * 1024) {
      setAuthError('Choose a JPEG, PNG or WebP image smaller than 2 MB.'); return
    }
    setPhotoBusy(true)
    try {
      const body = new FormData(); body.append('profilePic', file)
      const response = await requestAuth('/profile-picture', { method: 'PUT', headers: { Authorization: `Bearer ${userToken}` }, body })
      const payload = await response.json()
      if (!response.ok || !payload.success) throw new Error(payload.message || 'Unable to upload picture.')
      setProfilePic(payload.data.profilePic)
      const cached = JSON.parse(localStorage.getItem('user_profile') || '{}')
      localStorage.setItem('user_profile', JSON.stringify({ ...cached, profilePic: payload.data.profilePic }))
      setAuthSuccess('Profile picture updated.'); setPhotoOptionsOpen(false)
    } catch (failure) { setAuthError(failure instanceof Error ? failure.message : 'Unable to upload picture.') }
    finally { setPhotoBusy(false) }
  }
  const choosePhoto = (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (file) void uploadPhoto(file)
    event.target.value = ''
  }
  const chooseAvatar = (color: string) => {
    const canvas = document.createElement('canvas'); canvas.width = 256; canvas.height = 256
    const context = canvas.getContext('2d'); if (!context) return
    context.fillStyle = color; context.fillRect(0, 0, 256, 256)
    context.fillStyle = '#ffffff'; context.beginPath(); context.arc(128, 88, 44, 0, Math.PI * 2); context.fill()
    context.beginPath(); context.arc(128, 238, 88, Math.PI, 0); context.fill()
    canvas.toBlob(blob => { if (blob) void uploadPhoto(new File([blob], 'avatar.png', { type: 'image/png' })) }, 'image/png')
  }
  const hasSavedAddress = Boolean(
    addressForm.street || addressForm.city || addressForm.state || addressForm.zipcode,
  )
  const primaryAddressParts = [addressForm.street, addressForm.landmark].filter(Boolean)
  const secondaryAddressParts = [
    addressForm.city,
    addressForm.state,
    addressForm.country,
  ].filter(Boolean)
  const addressSummary = `${primaryAddressParts.join(', ')}${
    primaryAddressParts.length > 0 && secondaryAddressParts.length > 0 ? ', ' : ''
  }${secondaryAddressParts.join(', ')}${addressForm.zipcode ? ` - ${addressForm.zipcode}` : ''}`


  const resetAuthMessages = () => { setAuthError(''); setAuthSuccess('') }
  const requestAuth = (path: string, init?: RequestInit) => apiFetch(`${API_BASE_URL}/api/v1/auth${path}`, init)
  const fetchProfile = async () => {
    if (!userToken) return

    try {
      setIsProfileLoading(true)
      resetAuthMessages()
      const response = await requestAuth('/profile', {
        method: 'GET',
        signal: AbortSignal.timeout(15000),
        headers: {
          Authorization: `Bearer ${userToken}`,
        },
      })
      const payload = await response.json()

      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'Unable to fetch profile.')
      }

      const data = payload?.data ?? {}
      setAccountForm({
        firstname: data.firstname ?? '',
        lastname: data.lastname ?? '',
        phoneNumber: data.phoneNumber ?? '',
        email: data.email ?? '',
      })
      setSavedAccountForm({
        firstname: data.firstname ?? '',
        lastname: data.lastname ?? '',
        phoneNumber: data.phoneNumber ?? '',
        email: data.email ?? '',
      })
      setProfilePic(data.profilePic ?? '')

      const address = data.address ?? {}
      setAddressForm({
        label: address.label ?? 'HOME',
        street: address.street ?? '',
        landmark: address.landmark ?? '',
        city: address.city ?? '',
        state: address.state ?? '',
        country: address.country ?? '',
        zipcode: address.zipcode ?? '',
      })
      setIsEditingProfile(false)
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Unable to fetch profile.')
    } finally {
      setIsProfileLoading(false)
    }
  }

  const handleProfileUpdate = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    resetAuthMessages()

    if (!isEditingProfile) {
      setAuthError('Click "Edit Profile" first.')
      return
    }

    if (!userToken) {
      setAuthError('Please login first.')
      navigate('/auth/mobile')
      return
    }

    try {
      setIsLoading(true)
      const response = await requestAuth('/update-profile', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${userToken}`,
        },
        body: JSON.stringify({
          firstname: accountForm.firstname,
          lastname: accountForm.lastname,
          phoneNumber: accountForm.phoneNumber,
        }),
      })
      const payload = await response.json()

      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'Unable to update profile.')
      }

      setAuthSuccess(payload?.message ?? 'Profile updated successfully.')
      setSavedAccountForm(accountForm)
      setIsEditingProfile(false)
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Profile update failed.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleAddAddress = async (event?: FormEvent<HTMLFormElement>) => {
    event?.preventDefault()
    resetAuthMessages()

    if (!userToken) {
      setAuthError('Please login first.')
      navigate('/auth/mobile')
      return
    }

    try {
      setIsLoading(true)
      const response = await requestAuth('/add-address', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${userToken}`,
        },
        body: JSON.stringify({
          ...addressForm,
          label: addressForm.label || 'HOME',
          country: addressForm.country || 'India',
        }),
      })
      const payload = await response.json()

      if (!response.ok || !payload?.success) {
        throw new Error(payload?.message ?? 'Unable to save address.')
      }

      setAuthSuccess(payload?.message ?? 'Address saved successfully.')
      setIsAddressFormOpen(false)
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : 'Address save failed.')
    } finally {
      setIsLoading(false)
    }
  }


  const handleLogout = async () => {
    try {
      await requestAuth('/logout', { headers: { Authorization: `Bearer ${userToken}` } })
    } catch {
      // Clear the local session even if the logout endpoint is unavailable.
    } finally {
      localStorage.removeItem('user_token')
      localStorage.removeItem('user_profile')
      navigate('/')
    }
  }
  useEffect(() => {
    window.scrollTo(0, 0)
    void fetchProfile()
    // Fetch on entry and when the signed-in account changes.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [userToken])
  return (
    <section className="account-profile-page px-4 py-10 sm:py-14">
      <div className="account-profile-container">
        <Link to="/" className="text-sm font-semibold text-stone-600 hover:text-stone-900">← Back to marketplace</Link>
        <div className="px-4 py-6 sm:px-6">
          <span className="rounded-full bg-[#0066ff] px-3 py-1 text-xs font-bold text-white">YOUR ACCOUNT</span>
          <h1 className="mt-3 text-4xl font-black tracking-tight text-stone-900">My Profile</h1>
          <nav className="account-profile-shortcuts" aria-label="Account shortcuts"><Link to="/wallet">▣ My Wallet <span>Balance &amp; transactions →</span></Link><Link to="/pricing">♛ Membership <span>View lifetime plan →</span></Link><Link to="/referrals">♧ Refer &amp; Earn <span>Invite your network →</span></Link><Link to="/my-leads">▤ My Leads <span>View purchased leads →</span></Link></nav>
          <p className="mt-2 text-sm text-stone-600">Manage your personal details and saved address.</p>
        </div>
        {authError && <p role="alert" className="mb-4 rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-700">{authError}</p>}
        {authSuccess && <p role="status" className="mb-4 rounded-xl border border-green-200 bg-green-50 p-3 text-sm text-green-700">{authSuccess}</p>}
            <div className="mx-4 mb-8 overflow-hidden rounded-2xl border border-stone-200 bg-white shadow-sm sm:mx-6">
              <div className="border-b border-stone-200 px-6 py-4 text-stone-900">
                <div className="flex items-center gap-2 text-base font-bold">
                  <button
                    type="button"
                    onClick={() => navigate('/')}
                    className="rounded-full p-1.5 text-stone-600 hover:bg-stone-100"
                    aria-label="Back"
                  >
                    <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
                      <path d="m15 18-6-6 6-6" />
                    </svg>
                  </button>
                  Personal details
                </div>
                <p className="mt-2 text-sm text-stone-600">
                  {userToken
                    ? 'Manage your profile details'
                    : 'Log in or sign up to view your complete profile'}
                </p>
                {!userToken ? (
                  <button
                    type="button"
                    onClick={() => navigate('/auth/mobile')}
                    className="mt-4 w-full rounded-2xl border border-stone-300 bg-white py-3 text-lg font-semibold text-stone-500 shadow-[0_5px_12px_rgba(0,0,0,0.14)] transition hover:bg-stone-50"
                  >
                    Continue to sign in
                  </button>
                ) : null}
              </div>

              {userToken ? (
                <form
                  className="w-full space-y-4 bg-white px-4 pt-6 pb-8 sm:px-6 [&_input]:rounded-xl [&_input]:shadow-none [&_select]:rounded-xl [&_select]:shadow-none [&_button]:text-sm [&_button]:shadow-none [&_button:disabled]:cursor-not-allowed [&_button:disabled]:opacity-50"
                  onSubmit={handleProfileUpdate}
                >
                  {isProfileLoading ? (
                    <RowsSkeleton count={6} />
                  ) : (
                    <>
                      {isAddressFormOpen ? (
                        <div className="space-y-4 bg-white">
                          <div className="flex items-center gap-2">
                            <button
                              type="button"
                              onClick={() => setIsAddressFormOpen(false)}
                              className="rounded-full p-1 text-stone-700 hover:bg-stone-200"
                              aria-label="Back to account"
                            >
                              <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
                                <path d="m15 18-6-6 6-6" />
                              </svg>
                            </button>
                            <h3 className="text-2xl font-black text-stone-900">Add Address</h3>
                          </div>

                          <label className="block text-sm font-semibold text-stone-700">
                            Flat no. / Street Name
                            <input
                              type="text"
                              placeholder="Flat 203, Sai Residency"
                              value={addressForm.street}
                              onChange={(event) =>
                                setAddressForm((prev) => ({ ...prev, street: event.target.value }))
                              }
                              className="mt-1.5 h-12 w-full rounded-2xl border border-stone-300 bg-white px-3 text-sm text-stone-800 shadow-md outline-none focus:border-[#0066ff] focus:ring-1 focus:ring-[#0066ff]"
                            />
                          </label>

                          <label className="block text-sm font-semibold text-stone-700">
                            Landmark
                            <input
                              type="text"
                              placeholder="Near Hospital"
                              value={addressForm.landmark}
                              onChange={(event) =>
                                setAddressForm((prev) => ({ ...prev, landmark: event.target.value }))
                              }
                              className="mt-1.5 h-12 w-full rounded-2xl border border-stone-300 bg-white px-3 text-sm text-stone-800 shadow-md outline-none focus:border-[#0066ff] focus:ring-1 focus:ring-[#0066ff]"
                            />
                          </label>

                          <label className="block text-sm font-semibold text-stone-700">
                            City
                            <select
                              value={addressForm.city}
                              onChange={(event) =>
                                setAddressForm((prev) => ({ ...prev, city: event.target.value }))
                              }
                              className="mt-1.5 h-12 w-full rounded-2xl border border-stone-300 bg-white px-3 text-sm text-stone-800 shadow-md outline-none focus:border-[#0066ff] focus:ring-1 focus:ring-[#0066ff]"
                            >
                              <option value="">Select City</option>
                              <option value="Nashik">Nashik</option>
                              <option value="Mumbai">Mumbai</option>
                              <option value="Pune">Pune</option>
                              <option value="Bengaluru">Bengaluru</option>
                              <option value="Delhi">Delhi</option>
                            </select>
                          </label>

                          <label className="block text-sm font-semibold text-stone-700">
                            State
                            <input
                              type="text"
                              placeholder="Maharashtra"
                              value={addressForm.state}
                              onChange={(event) =>
                                setAddressForm((prev) => ({ ...prev, state: event.target.value }))
                              }
                              className="mt-1.5 h-12 w-full rounded-2xl border border-stone-300 bg-white px-3 text-sm text-stone-800 shadow-md outline-none focus:border-[#0066ff] focus:ring-1 focus:ring-[#0066ff]"
                            />
                          </label>

                          <label className="block text-sm font-semibold text-stone-700">
                            Zipcode
                            <input
                              type="text"
                              placeholder="411 853"
                              value={addressForm.zipcode}
                              onChange={(event) =>
                                setAddressForm((prev) => ({ ...prev, zipcode: event.target.value }))
                              }
                              className="mt-1.5 h-12 w-full rounded-2xl border border-stone-300 bg-white px-3 text-sm text-stone-800 shadow-md outline-none focus:border-[#0066ff] focus:ring-1 focus:ring-[#0066ff]"
                            />
                          </label>

                          <div>
                            <p className="text-sm font-semibold text-stone-600">Save address as</p>
                            <div className="mt-2 flex items-center gap-2">
                              <button
                                type="button"
                                onClick={() =>
                                  setAddressForm((prev) => ({ ...prev, label: 'HOME' }))
                                }
                                className={`rounded-lg border px-4 py-1.5 text-xs font-semibold ${
                                  addressForm.label === 'HOME'
                                    ? 'border-[#0066ff] bg-[#0066ff] text-white'
                                    : 'border-stone-300 bg-white text-stone-600'
                                }`}
                              >
                                Home
                              </button>
                              <button
                                type="button"
                                onClick={() =>
                                  setAddressForm((prev) => ({ ...prev, label: 'OFFICE' }))
                                }
                                className={`rounded-lg border px-4 py-1.5 text-xs font-semibold ${
                                  addressForm.label === 'OFFICE'
                                    ? 'border-[#0066ff] bg-[#0066ff] text-white'
                                    : 'border-stone-300 bg-white text-stone-600'
                                }`}
                              >
                                Office
                              </button>
                            </div>
                          </div>

                          <button
                            type="button"
                            disabled={isLoading}
                            onClick={() => {
                              void handleAddAddress()
                            }}
                            className="mt-3 w-full rounded-2xl bg-[#0066ff] py-3 text-lg font-bold text-white shadow-md transition hover:bg-[#0050cb]"
                          >
                            {isLoading ? 'Please wait...' : 'Save'}
                          </button>
                        </div>
                      ) : (
                        <>
                          <div className="account-profile-photo">
                            <button type="button" className="account-avatar-trigger" aria-label="Change profile photo" aria-expanded={photoOptionsOpen} aria-controls="profile-photo-options" disabled={photoBusy} onClick={() => setPhotoOptionsOpen(value => !value)}><span className="account-avatar-preview">{profilePic ? <img src={profilePic} alt="Your profile" onError={() => setProfilePic('')} /> : <span aria-label="Default profile avatar">{(accountForm.firstname[0] || 'N').toUpperCase()}{(accountForm.lastname[0] || '').toUpperCase()}</span>}</span><span className="account-avatar-edit" aria-hidden="true">✎</span></button>
                            <div><h2>{[accountForm.firstname,accountForm.lastname].filter(Boolean).join(' ') || 'Your profile'}</h2><p>Click your profile picture to change it.</p>
                              {photoOptionsOpen && <div id="profile-photo-options" className="account-photo-options"><label className="account-photo-upload">{photoBusy ? 'Uploading…' : 'Upload photo'}<input type="file" accept="image/jpeg,image/png,image/webp" disabled={photoBusy || isLoading} onChange={choosePhoto} /></label><p className="account-photo-hint">JPEG, PNG or WebP · Up to 2 MB</p><div className="account-avatar-choices" role="group" aria-label="Choose a profile avatar">{[['#0066ff','Blue'],['#7c3aed','Purple'],['#059669','Green'],['#e87923','Orange']].map(([color,label]) => <button key={color} type="button" disabled={photoBusy || isLoading} style={{ backgroundColor:color }} aria-label={`Use ${label.toLowerCase()} avatar`} title={`${label} avatar`} onClick={() => chooseAvatar(color)}><svg viewBox="0 0 32 32" fill="white" aria-hidden="true"><circle cx="16" cy="11" r="6"/><path d="M4 31a12 12 0 0 1 24 0Z"/></svg></button>)}</div></div>}
                            </div>
                          </div>
                          <div className="grid grid-cols-2 gap-3">
                            <label className="block text-sm font-semibold text-stone-700">
                              First Name
                              <input
                                type="text"
                                value={accountForm.firstname}
                                readOnly={!isEditingProfile}
                                onChange={(event) =>
                                  setAccountForm((prev) => ({ ...prev, firstname: event.target.value }))
                                }
                                className={`mt-1.5 h-12 w-full rounded-2xl border border-stone-300 bg-white px-3 text-sm shadow-md outline-none ${
                                  isEditingProfile
                                    ? 'text-stone-800 focus:border-[#0066ff] focus:ring-1 focus:ring-[#0066ff]'
                                    : 'text-stone-500'
                                }`}
                              />
                            </label>
                            <label className="block text-sm font-semibold text-stone-700">
                              Last Name
                              <input
                                type="text"
                                value={accountForm.lastname}
                                readOnly={!isEditingProfile}
                                onChange={(event) =>
                                  setAccountForm((prev) => ({ ...prev, lastname: event.target.value }))
                                }
                                className={`mt-1.5 h-12 w-full rounded-2xl border border-stone-300 bg-white px-3 text-sm shadow-md outline-none ${
                                  isEditingProfile
                                    ? 'text-stone-800 focus:border-[#0066ff] focus:ring-1 focus:ring-[#0066ff]'
                                    : 'text-stone-500'
                                }`}
                              />
                            </label>
                          </div>

                          <label className="block text-sm font-semibold text-stone-700">
                            Mobile Number
                            <input
                              type="tel"
                              value={accountForm.phoneNumber}
                              readOnly={!isEditingProfile}
                              onChange={(event) =>
                                setAccountForm((prev) => ({ ...prev, phoneNumber: event.target.value }))
                              }
                              className={`mt-1.5 h-12 w-full rounded-2xl border border-stone-300 bg-white px-3 text-sm shadow-md outline-none ${
                                isEditingProfile
                                  ? 'text-stone-800 focus:border-[#0066ff] focus:ring-1 focus:ring-[#0066ff]'
                                  : 'text-stone-500'
                              }`}
                            />
                          </label>

                          <label className="block text-sm font-semibold text-stone-700">
                            Email ID
                            <input
                              type="email"
                              value={accountForm.email}
                              readOnly
                              className="mt-1.5 h-12 w-full rounded-2xl border border-stone-300 bg-white px-3 text-sm text-stone-500 shadow-md outline-none"
                            />
                          </label>

                          <button
                            type="button"
                            onClick={() => setIsAddressFormOpen(true)}
                            className="flex w-full items-center justify-between rounded-2xl border border-stone-300 bg-white px-4 py-3 text-sm font-semibold text-stone-700 shadow-md"
                          >
                            {hasSavedAddress ? 'Edit Address' : 'Add Address'}
                            <span>›</span>
                          </button>

                          {hasSavedAddress ? (
                            <div className="rounded-2xl border border-stone-300 bg-white px-4 py-3 text-sm text-stone-700 shadow-sm">
                              <p className="font-semibold text-stone-800">
                                {addressForm.label || 'HOME'} Address
                              </p>
                              <p className="mt-1 text-xs leading-relaxed text-stone-600">
                                {addressSummary}
                              </p>
                            </div>
                          ) : null}

                          {!isEditingProfile ? <button
                        type="button"
                        onClick={() => {
                          resetAuthMessages()
                          setIsEditingProfile(true)
                        }}
                        className="w-full rounded-2xl border border-[#0066ff] bg-white py-3 text-base font-semibold text-[#0066ff] shadow-sm transition hover:bg-[#edf5ff]"
                      >
                        Edit Profile
                      </button> : <div className="flex gap-3">
                      <button type="button" disabled={isLoading} onClick={() => {
                        setAccountForm(savedAccountForm)
                        setIsEditingProfile(false)
                        resetAuthMessages()
                      }} className="w-full rounded-xl border border-stone-300 bg-white py-3 font-semibold text-stone-700">Cancel</button>
                      <button
                            type="submit"
                        disabled={isLoading || isProfileLoading || !isEditingProfile}
                            className="mt-2 w-full rounded-2xl bg-[#0066ff] py-3 text-lg font-bold text-white shadow-md transition hover:bg-[#0050cb]"
                          >
                        {isLoading ? 'Please wait...' : 'Update Profile'}
                          </button>
                      </div>}


                          <button
                            type="button"
                            onClick={handleLogout}
                            className="w-full rounded-2xl border border-red-300 bg-white py-3 text-base font-semibold text-red-500 shadow-sm"
                          >
                            Log Out
                          </button>
                        </>
                      )}
                    </>
                  )}
                </form>
              ) : (
                <div className="min-h-[58vh] rounded-t-3xl bg-[#f8fafc] px-4 pt-6 pb-10">
                  <div className="mt-4 flex justify-center">
                    <img
                      src="/trust-team.jpg"
                      alt=""
                      className="h-44 w-52 rounded-2xl object-cover opacity-95"
                    />
                  </div>
                </div>
              )}
            </div>

      </div>
    </section>
  )
}
