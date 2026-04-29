import { createBrowserRouter } from 'react-router-dom'
import { PublicLayout } from '@/components/layout/PublicLayout'
import { HomePage } from '@/features/home/pages/HomePage'
import { PricingPage } from '@/features/pricing/pages/PricingPage'
import { ContactPage } from '@/features/contact/pages/ContactPage'
import { PrivacyPolicyPage } from '@/features/legal/pages/PrivacyPolicyPage'
import { TermsServicePage } from '@/features/legal/pages/TermsServicePage'
import { CookiePolicyPage } from '@/features/legal/pages/CookiePolicyPage'
import { ContactSupportPage } from '@/features/legal/pages/ContactSupportPage'
import { MobileAuthDrawerPage } from '@/features/auth/pages/MobileAuthDrawerPage'
import { NotFoundPage } from '@/pages/NotFoundPage'

export const router = createBrowserRouter([
  {
    path: '/',
    element: <PublicLayout />,
    children: [
      { index: true, element: <HomePage /> },
      { path: 'pricing', element: <PricingPage /> },
      { path: 'contact', element: <ContactPage /> },
      { path: 'privacy-policy', element: <PrivacyPolicyPage /> },
      { path: 'terms-service', element: <TermsServicePage /> },
      { path: 'cookie-policy', element: <CookiePolicyPage /> },
      { path: 'contact-support', element: <ContactSupportPage /> },
      { path: 'auth/mobile', element: <MobileAuthDrawerPage /> },
    ],
  },
  { path: '*', element: <NotFoundPage /> },
])
