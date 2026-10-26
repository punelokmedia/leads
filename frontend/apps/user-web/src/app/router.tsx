import { createBrowserRouter, Navigate } from 'react-router-dom'
import { PublicLayout } from '@/components/layout/PublicLayout'

export const router = createBrowserRouter([
  { path: '/login', lazy: async () => ({ Component: (await import('@/features/auth/pages/LoginPage')).LoginPage }) },
  {
    path: '/',
    element: <PublicLayout />,
    children: [
      { index: true, lazy: async () => ({ Component: (await import('@/features/home/pages/HomePage')).HomePage }) },
      { path: 'categories', lazy: async () => ({ Component: (await import('@/features/home/pages/CategoriesPage')).CategoriesPage }) },
      { path: 'leads/:leadId', lazy: async () => ({ Component: (await import('@/features/home/pages/LeadDetailsPage')).LeadDetailsPage }) },
      ...['cart', 'my-leads', 'signup', 'forgot-password', 'forgot-password/verify', 'forgot-password/reset'].map(path => ({ path, element: null })),
      { path: 'history', element: <Navigate to="/my-leads" replace /> },
      { path: 'profile', lazy: async () => ({ Component: (await import('@/features/profile/pages/ProfilePage')).ProfilePage }) },
      { path: 'wallet', lazy: async () => ({ Component: (await import('@/features/wallet/pages/WalletPage')).WalletPage }) },
      { path: 'wallet/success/:topupId', lazy: async () => ({ Component: (await import('@/features/wallet/pages/WalletSuccessPage')).WalletSuccessPage }) },
      { path: 'referrals', lazy: async () => ({ Component: (await import('@/features/profile/pages/ReferralPage')).ReferralPage }) },
      { path: 'pricing', lazy: async () => ({ Component: (await import('@/features/pricing/pages/PricingPage')).PricingPage }) },
      { path: 'membership/success', lazy: async () => ({ Component: (await import('@/features/pricing/pages/MembershipSuccessPage')).MembershipSuccessPage }) },
      { path: 'contact', lazy: async () => ({ Component: (await import('@/features/contact/pages/ContactPage')).ContactPage }) },
      { path: 'download', lazy: async () => ({ Component: (await import('@/features/download/pages/DownloadAppPage')).DownloadAppPage }) },
      { path: 'privacy-policy', lazy: async () => ({ Component: (await import('@/features/legal/pages/PrivacyPolicyPage')).PrivacyPolicyPage }) },
      { path: 'account-deletion', lazy: async () => ({ Component: (await import('@/features/legal/pages/AccountDeletionPage')).AccountDeletionPage }) },
      { path: 'terms-service', lazy: async () => ({ Component: (await import('@/features/legal/pages/TermsServicePage')).TermsServicePage }) },
      { path: 'cookie-policy', lazy: async () => ({ Component: (await import('@/features/legal/pages/CookiePolicyPage')).CookiePolicyPage }) },
      { path: 'contact-support', lazy: async () => ({ Component: (await import('@/features/legal/pages/ContactSupportPage')).ContactSupportPage }) },
      { path: 'auth/mobile', lazy: async () => ({ Component: (await import('@/features/auth/pages/AuthEntryPage')).AuthEntryPage }) },
    ],
  },
  { path: '*', lazy: async () => ({ Component: (await import('@/pages/NotFoundPage')).NotFoundPage }) },
])
