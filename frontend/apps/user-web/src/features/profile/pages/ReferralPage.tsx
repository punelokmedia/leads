import { useEffect } from 'react'
import { ReferralSection } from '@/features/profile/components/ReferralSection'

export function ReferralPage() {
  useEffect(() => { window.scrollTo(0, 0) }, [])
  return (
    <section className="bg-[#efefef] px-4 py-10 sm:py-14">
      <div className="mx-auto max-w-xl">
        <ReferralSection initiallyOpen />
      </div>
    </section>
  )
}
