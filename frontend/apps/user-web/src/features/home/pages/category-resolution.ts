export type ApiCategory = { _id: string; name: string; displayName?: string }
const normalize = (value: string) => value.toLowerCase().replace(/[^a-z0-9]/g, '')
const aliases: Record<string, string[]> = {
  popfalseceilingwork: ['falseceilingpop', 'popfalseceiling', 'falseceiling'],
  civilwork: ['homerenovationcivilwork', 'homerenovation'],
  waterproofing: ['waterproofingservices'],
  aluminiumwindows: ['aluminumwindows', 'aluminiumandwindows'],
}
export function resolveCategory(name: string, items: ApiCategory[]) {
  const key = normalize(name)
  const accepted = [key, ...(aliases[key] || [])]
  return items.find(item => accepted.includes(normalize(item.name)) || (item.displayName && accepted.includes(normalize(item.displayName))))
}
export function categoryLeadUrl(id: string) {
  return `/?browse=1&category=${encodeURIComponent(id)}`
}
