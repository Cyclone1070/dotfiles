import { buildSchemaUrl, ConfigLoader } from "@aliou/pi-utils-settings";
import { DEFAULT_CONFIG } from "./defaults";
import type { GuardrailsConfig, PolicyRule, ResolvedConfig } from "./types";

export const configLoader = new ConfigLoader<GuardrailsConfig, ResolvedConfig>(
  "guardrails",
  DEFAULT_CONFIG,
  {
    scopes: ["global", "memory"],
    schemaUrl: buildSchemaUrl("guardrails", "0.1.0"),
    afterMerge: (resolved, global, _local, memory) => {
      const ruleMap = new Map<string, PolicyRule>();

      if (resolved.applyBuiltinDefaults) {
        for (const rule of DEFAULT_CONFIG.policies.rules) {
          ruleMap.set(rule.id, rule);
        }
      }
      if (global?.policies?.rules) {
        for (const rule of global.policies.rules) {
          ruleMap.set(rule.id, rule);
        }
      }
      if (memory?.policies?.rules) {
        for (const rule of memory.policies.rules) {
          ruleMap.set(rule.id, rule);
        }
      }
      resolved.policies.rules = [...ruleMap.values()];

      const customPatterns =
        memory?.permissionGate?.customPatterns ??
        global?.permissionGate?.customPatterns;
      if (customPatterns) {
        resolved.permissionGate.patterns = customPatterns;
        resolved.permissionGate.useBuiltinMatchers = false;
      }

      const mergedPaths = new Set<string>();
      for (const paths of [
        global?.pathAccess?.allowedPaths,
        memory?.pathAccess?.allowedPaths,
      ]) {
        for (const path of paths ?? []) {
          const trimmed = path.trim();
          if (trimmed) mergedPaths.add(trimmed);
        }
      }
      resolved.pathAccess.allowedPaths = [...mergedPaths];

      return resolved;
    },
  },
);
