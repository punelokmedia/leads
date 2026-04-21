import { createBrowserRouter } from 'react-router-dom'
import { AdminLayout } from '@/components/layout/AdminLayout'
import { LoginPage } from '@/features/auth/pages/LoginPage'
import {
  ProtectedAdminRoute,
  PublicOnlyRoute,
} from '@/features/auth/components/AuthRouteGuards'
import { DashboardPage } from '@/features/dashboard/pages/DashboardPage'
import { LeadsPage } from '@/features/leads/pages/LeadsPage'
import { CreateLeadPage } from '@/features/leads/pages/CreateLeadPage'
import { CategoriesPage } from '@/features/categories/pages/CategoriesPage'
import { AddAdminPage } from '@/features/admins/pages/AddAdminPage'
import { PaymentHistoryPage } from '@/features/payments/pages/PaymentHistoryPage'
import { WebAnalyticsPage } from '@/features/analytics/pages/WebAnalyticsPage'
import { SettingsPage } from '@/features/settings/pages/SettingsPage'
import { NotFoundPage } from '@/pages/NotFoundPage'

export const router = createBrowserRouter([
  {
    element: <PublicOnlyRoute />,
    children: [{ path: '/login', element: <LoginPage /> }],
  },
  {
    element: <ProtectedAdminRoute />,
    children: [
      {
        path: '/',
        element: <AdminLayout />,
        children: [
          { index: true, element: <DashboardPage /> },
          { path: 'leads', element: <LeadsPage /> },
          { path: 'leads/create', element: <CreateLeadPage /> },
          { path: 'categories', element: <CategoriesPage /> },
          { path: 'admins/add', element: <AddAdminPage /> },
          { path: 'payments', element: <PaymentHistoryPage /> },
          { path: 'web-analytics', element: <WebAnalyticsPage /> },
          { path: 'settings', element: <SettingsPage /> },
        ],
      },
    ],
  },
  { path: '*', element: <NotFoundPage /> },
])
