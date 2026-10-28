// Imports cannot be aborted, but a stalled download must still offer recovery.
export async function loadWithTimeout<T>(load: () => Promise<T>, timeoutMs = 20000): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | undefined
  try {
    return await Promise.race([
      load(),
      new Promise<never>((_, reject) => { timer = setTimeout(() => reject(new Error('Page loading timed out')), timeoutMs) }),
    ])
  } finally { clearTimeout(timer) }
}
