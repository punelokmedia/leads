import { Fragment } from 'react'
import { privacyPolicyBlocks } from '../data/privacyPolicy'

function PolicyText({ text }: { text: string }) {
  return text.split(/(\*\*[^*]+\*\*)/g).map((part, index) =>
    part.startsWith('**') ? <strong key={index} className="font-semibold text-stone-900">{part.slice(2, -2)}</strong> : <Fragment key={index}>{part}</Fragment>,
  )
}

export function PrivacyPolicyPage() {
  return (
    <div className="bg-[#efefef]">
      <section className="mx-auto max-w-5xl px-4 py-14 sm:px-6 sm:py-16">
        <p className="inline-flex rounded-full bg-[#F8B020] px-4 py-1 text-xs font-bold uppercase tracking-wide text-white">NextLeads ? Legal</p>
        <h1 className="mt-3 text-4xl font-black text-stone-900 sm:text-5xl">Privacy Policy ? NextLeads</h1>
      </section>
      <section className="mx-auto max-w-5xl px-4 pb-14 sm:px-6">
        <article className="rounded-2xl border border-stone-300 bg-white p-6 text-sm leading-relaxed text-stone-600 shadow-sm sm:p-10">
          {privacyPolicyBlocks.map((block, index) => {
            switch (block.type) {
              case 'heading':
                return <h2 key={index} className="mb-4 mt-10 text-xl font-bold text-stone-900">{block.text}</h2>
              case 'subheading':
                return <h3 key={index} className="mb-3 mt-6 text-lg font-semibold text-stone-900">{block.text}</h3>
              case 'list':
                return <ul key={index} className="mb-5 list-disc space-y-2 pl-6">{block.items.map(item => <li key={item}><PolicyText text={item} /></li>)}</ul>
              case 'paragraph':
                return <p key={index} className="mb-5 whitespace-pre-line break-words"><PolicyText text={block.text} /></p>
            }
          })}
        </article>
      </section>
    </div>
  )
}
