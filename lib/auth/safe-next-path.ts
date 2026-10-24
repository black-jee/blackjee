/**
 * Accept only same-origin redirect destinations from auth callback query parameters.
 * URL parsing normalizes backslashes, so checking only for a leading slash is insufficient.
 */
export function safeInternalRedirectPath(requestedNext: string | null, origin: string): string {
  if (!requestedNext?.startsWith("/")) return "/";

  try {
    const base = new URL(origin);
    const target = new URL(requestedNext, base);
    if (target.origin !== base.origin) return "/";
    return `${target.pathname}${target.search}${target.hash}`;
  } catch {
    return "/";
  }
}
