/**
 * Accept only same-origin redirect destinations from auth callback query parameters.
 * URL parsing normalizes backslashes, so checking only for a leading slash is insufficient.
 * The default origin lets client components validate paths during server rendering without
 * reading the browser-only window object.
 */
export function safeInternalRedirectPath(
  requestedNext: string | null,
  origin = "https://blackjee.invalid",
): string {
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
