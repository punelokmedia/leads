import { Fragment, type ReactNode } from 'react'
import terms from './terms-and-conditions.md?raw'
import './legal.css'

function inline(text: string): ReactNode[] {
  return text.split(/(\*\*[^*]+\*\*|\[[^\]]+\]\(https?:\/\/[^)]+\))/g).map((part, index) => {
    if (part.startsWith('**') && part.endsWith('**')) return <strong key={index}>{part.slice(2,-2)}</strong>
    const link = part.match(/^\[([^\]]+)\]\((https?:\/\/[^)]+)\)$/)
    return link ? <a key={index} href={link[2]}>{link[1]}</a> : <Fragment key={index}>{part}</Fragment>
  })
}
export function TermsServicePage() {
  const blocks = terms.replace(/\r/g, '').trim().split(/\n\s*\n/)
  return <div className="legal-page"><header className="legal-page-heading"><span>LEGAL</span><h1>Terms &amp; Conditions</h1><p>Please read these terms carefully before using NEXTLEADS.</p></header><article className="legal-document">{blocks.map((block,index) => {
    if (block.startsWith('# ')) return null
    if (block.startsWith('## ')) return <h2 id={`terms-section-${block.match(/^## (\d+)/)?.[1] || index}`} key={index}>{block.slice(3)}</h2>
    if (block === '---') return <hr key={index}/>
    const lines = block.split('\n')
    if (lines.every(line => /^- /.test(line))) return <ul key={index}>{lines.map((line,i) => <li key={i}>{inline(line.slice(2))}</li>)}</ul>
    if (lines.every(line => /^\d+\. /.test(line))) return <ol key={index}>{lines.map((line,i) => <li key={i}>{inline(line.replace(/^\d+\. /,''))}</li>)}</ol>
    return <p key={index}>{lines.map((line,i) => <Fragment key={i}>{i>0 && <br/>}{inline(line.trim())}</Fragment>)}</p>
  })}</article></div>
}
