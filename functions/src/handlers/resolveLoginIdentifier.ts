import { HttpsError, onCall } from "firebase-functions/v2/https";
import { callableOptions } from "../config";
import { guarded } from "../errors";
import { consumeLoginLookupAttempt } from "../firestore/rateLimit";
import { aliasCol } from "../firestore/userStore";
import { asBag, reqString } from "../util/input";
import { classifyIdentifier } from "../util/identifiers";

const GENERIC_FAILURE = "Invalid username or password.";

/**
 * resolveLoginIdentifier (callable, asia-south1) - unauthenticated.
 * Request:  { identifier }  (username, email or phone)
 * Response: { email }
 * Unknown identifiers return the same `unauthenticated` error the client
 * shows for a wrong password. Rate limited per IP; set ENFORCE_APP_CHECK=true
 * to additionally require App Check.
 */
export const resolveLoginIdentifier = onCall(callableOptions, (request) =>
  guarded(async () => {
    const bag = asBag(request.data);
    const identifier = reqString(bag, "identifier", 1, 120);
    await consumeLoginLookupAttempt(request.rawRequest?.ip);

    const classified = classifyIdentifier(identifier);
    if (!classified) throw new HttpsError("unauthenticated", GENERIC_FAILURE);

    const snap = await aliasCol().doc(classified.key).get();
    const email = snap.get("email");
    if (!snap.exists || typeof email !== "string") {
      throw new HttpsError("unauthenticated", GENERIC_FAILURE);
    }
    return { email };
  }),
);
