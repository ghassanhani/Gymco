// The shape of a training plan as the model reports it, and the rules it
// plans by. Shared by routine-ai (from the user's words) and iron (from the
// user's numbers), so the app reads both the same way.

export const routinesSchema = {
  type: "array",
  description: "One routine per training day type, in the order they run. Empty if there is nothing to plan.",
  items: {
    type: "object",
    properties: {
      name: { type: "string", description: "Short name in the user's language, e.g. 'Push', 'Upper A', 'Full body'." },
      days: {
        type: "array",
        description: "Weekdays it runs on, 0 = Monday to 6 = Sunday. Empty when it is for any time.",
        items: { type: "integer" },
      },
      items: {
        type: "array",
        items: {
          type: "object",
          properties: {
            exercise: { type: "string", description: "Exactly one name copied from the exercise list." },
            sets: { type: "integer" },
            rep_low: { type: "integer" },
            rep_high: { type: "integer" },
            rest_seconds: { type: "integer" },
          },
          required: ["exercise", "sets", "rep_low", "rep_high", "rest_seconds"],
          additionalProperties: false,
        },
      },
    },
    required: ["name", "days", "items"],
    additionalProperties: false,
  },
} as const;

export const PLAN_RULES =
  "If a number of days is given but not which, spread them out (3 days: Monday, Wednesday, Friday). " +
  "Fit each session in the time given, counting about 2.5 minutes per set with rest. " +
  "Use 4 to 7 exercises a session, compound lifts first, 2 to 4 sets each, " +
  "rep ranges such as 5-8, 8-12 or 12-15, and 60 to 180 seconds of rest.";

/** The system block that carries the exercise list; it is the same for every user of a build, so it caches. */
export const exerciseSystem = (intro: string, names: string[]) => ({
  type: "text" as const,
  text: intro + " Use only exercises from this list, copying each name exactly:\n<exercises>\n" + names.join("\n") +
    "\n</exercises>",
  cache_control: { type: "ephemeral" as const },
});

const MAX_EXERCISES = 1500;
const MAX_NAME_CHARS = 80;

/** The exercise names the app sent, deduplicated and capped. */
export function exerciseNames(v: unknown): string[] {
  if (!Array.isArray(v)) return [];
  return [...new Set(v.filter((n): n is string => typeof n === "string" && n.length > 0 && n.length <= MAX_NAME_CHARS))]
    .slice(0, MAX_EXERCISES);
}
