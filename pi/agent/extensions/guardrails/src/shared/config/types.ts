import type { GuardrailsFeatureId } from "../events";

export interface PatternConfig {
  pattern: string;
  description?: string;
  regex?: boolean;
}

export interface DangerousPattern extends PatternConfig {
  description: string;
}

export type Protection = "none" | "readOnly" | "noAccess";

export interface PolicyRule {
  id: string;
  name?: string;
  description?: string;
  patterns: PatternConfig[];
  allowedPatterns?: PatternConfig[];
  protection: Protection;
  onlyIfExists?: boolean;
  blockMessage?: string;
  enabled?: boolean;
}

export type PathAccessMode = "allow" | "ask" | "block";

export interface PathAccessConfig {
  mode?: PathAccessMode;
  allowedPaths?: string[];
}

export interface GuardrailsConfig {
  $schema?: string;
  version?: string;
  enabled?: boolean;
  applyBuiltinDefaults?: boolean;
  onboarding?: {
    completed?: boolean;
    completedAt?: string;
    version?: string;
  };
  features?: Partial<Record<GuardrailsFeatureId, boolean>>;
  policies?: {
    rules?: PolicyRule[];
  };
  pathAccess?: PathAccessConfig;
  permissionGate?: {
    patterns?: DangerousPattern[];
    customPatterns?: DangerousPattern[];
    requireConfirmation?: boolean;
    allowedPatterns?: PatternConfig[];
    autoDenyPatterns?: PatternConfig[];
  };
}

export interface ResolvedConfig {
  version: string;
  enabled: boolean;
  applyBuiltinDefaults: boolean;
  features: Record<GuardrailsFeatureId, boolean>;
  policies: {
    rules: PolicyRule[];
  };
  pathAccess: {
    mode: PathAccessMode;
    allowedPaths: string[];
  };
  permissionGate: {
    patterns: DangerousPattern[];
    useBuiltinMatchers: boolean;
    requireConfirmation: boolean;
    allowedPatterns: PatternConfig[];
    autoDenyPatterns: PatternConfig[];
  };
}
