import type { Action, Rule, Safety } from "./types";

export type { Action, Rule, Safety };

export async function checkAction<TMeta = null>(
  action: Action,
  rules: Rule<TMeta>[],
): Promise<Safety<TMeta>> {
  for (const rule of rules) {
    const result = await rule.check(action);
    if (result.kind === "match") {
      return {
        kind: "dangerous",
        action,
        key: rule.key,
        reason: result.reason,
        metadata: result.metadata as TMeta,
      };
    }
  }
  return { kind: "safe" };
}
