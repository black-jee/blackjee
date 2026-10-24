/** Validate an HTML datetime-local value without allowing Date.parse to normalize invalid dates. */
export function isValidIstLocalDateTime(value: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(value)) return false;

  const [datePart, timePart] = value.split("T");
  if (!datePart || !timePart) return false;

  const [year, month, day] = datePart.split("-").map(Number);
  const [hour, minute] = timePart.split(":").map(Number);
  if ([year, month, day, hour, minute].some((part) => !Number.isInteger(part))) {
    return false;
  }
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return false;

  const date = new Date(Date.UTC(year, month - 1, day));
  return (
    date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 && date.getUTCDate() === day
  );
}

/** Convert a validated India-local datetime to an unambiguous UTC ISO timestamp. */
export function istLocalDateTimeToIso(value: string): string {
  if (!isValidIstLocalDateTime(value)) {
    throw new Error("Invalid India-local date and time.");
  }
  return new Date(`${value}:00+05:30`).toISOString();
}
