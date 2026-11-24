const HOUR_MS = 60 * 60 * 1000;

export interface TimedBreak {
  startAt: Date;
  endAt?: Date | null;
}

export interface ClosedSession {
  id: string;
  checkInAt: Date;
  checkOutAt: Date;
  breaks: readonly TimedBreak[];
}

/** Hours from check-in to [end], less breaks (an open break ends at [end]). */
export function workedHours(checkInAt: Date, end: Date, breaks: readonly TimedBreak[]): number {
  let ms = Math.max(0, end.getTime() - checkInAt.getTime());
  for (const pause of breaks) {
    const pauseEnd = Math.min((pause.endAt ?? end).getTime(), end.getTime());
    ms -= Math.max(0, pauseEnd - pause.startAt.getTime());
  }
  return Math.max(0, ms) / HOUR_MS;
}

/**
 * Potential overtime of each closed session of one shift date: hours worked
 * beyond [scheduledHours], taken in check-in order, so the sessions' shares
 * add up to the day's overtime. Rounded to two decimals.
 */
export function potentialOvertimeBySession(
  sessions: readonly ClosedSession[],
  scheduledHours: number,
): Map<string, number> {
  const result = new Map<string, number>();
  let worked = 0;
  for (const session of [...sessions].sort((a, b) => a.checkInAt.getTime() - b.checkInAt.getTime())) {
    const before = Math.max(0, worked - scheduledHours);
    worked += workedHours(session.checkInAt, session.checkOutAt, session.breaks);
    const after = Math.max(0, worked - scheduledHours);
    result.set(session.id, Math.round((after - before) * 100) / 100);
  }
  return result;
}
