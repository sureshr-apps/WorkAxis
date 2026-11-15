import { invalid } from "../../errors";
import { calendarDayNumber } from "../../licenses/calendarDate";
import { reqNumber } from "../../util/input";
import { reqDate } from "../vars";

type Bag = Record<string, unknown>;

/** Largest accepted one-time or yearly price, in INR. */
export const MAX_LICENSE_PRICE = 1e12;

/** A non-negative INR amount. */
export const reqPrice = (bag: Bag, key: string): number =>
  reqNumber(bag, key, 0, MAX_LICENSE_PRICE);

/** Reads `startDate` and `expiryDate` (real YYYY-MM-DD dates) and requires the expiry after the start. */
export function reqLicenseTerm(bag: Bag): { startDate: string; expiryDate: string } {
  const startDate = reqDate(bag, "startDate");
  const expiryDate = reqDate(bag, "expiryDate");
  if (calendarDayNumber(expiryDate) <= calendarDayNumber(startDate)) {
    throw invalid("The expiry date must be after the start date.");
  }
  return { startDate, expiryDate };
}
