import { dirname } from "node:path";
import { stat } from "node:fs/promises";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { checkAction } from "../../src/core";
import {
  normalizeForDisplay,
  type PathAccessState,
} from "../../src/core/paths";
import { configLoader } from "../../src/shared/config";
import {
  createFeatureRegisterPayload,
  emitActionBlocked,
  emitActionPrompted,
  GUARDRAILS_FEATURE_REGISTER_EVENT,
  GUARDRAILS_FEATURE_REQUEST_EVENT,
} from "../../src/shared/events";
import {
  createPendingGrant,
  isGrantTooBroad,
  type PendingPathGrant,
  pendingAllowedPaths,
  persistGrant,
  resolveAllowedPaths,
} from "./grants";
import { createPathAccessPromptComponent, type PromptResult } from "./prompt";
import { createPathAccessRule } from "./rules";
import { targetsForTool } from "./targets";

export default async function pathAccess(pi: ExtensionAPI) {
  await configLoader.load();

  pi.events.on(GUARDRAILS_FEATURE_REQUEST_EVENT, () => {
    pi.events.emit(
      GUARDRAILS_FEATURE_REGISTER_EVENT,
      createFeatureRegisterPayload("pathAccess"),
    );
  });

  pi.on("tool_call", async (event, ctx) => {
    const config = configLoader.getConfig();
    if (
      !config.enabled ||
      !config.features.pathAccess ||
      config.pathAccess.mode === "allow"
    ) {
      return;
    }

    const input = event.input as Record<string, unknown>;
    const targets = [
      ...new Set(await targetsForTool(event.toolName, input, ctx.cwd)),
    ];
    const acceptedGrants: PendingPathGrant[] = [];

    for (const absolutePath of targets) {
      const action = {
        kind: "file" as const,
        path: absolutePath,
        origin: event.toolName,
      };
      const state: PathAccessState = {
        cwd: ctx.cwd,
        mode: config.pathAccess.mode,
        allowedPaths: [
          ...resolveAllowedPaths(config.pathAccess.allowedPaths, ctx.cwd),
          ...pendingAllowedPaths(acceptedGrants),
        ],
        hasUI: ctx.hasUI,
      };
      const safety = await checkAction(action, [createPathAccessRule(state)]);
      if (safety.kind === "safe") continue;

      if (config.pathAccess.mode === "block" || !ctx.hasUI) {
        emitActionBlocked(pi, {
          feature: "pathAccess",
          action: safety.action,
          reason: safety.reason,
          block: {
            source: ctx.hasUI ? "policy" : "nonInteractive",
            metadata: safety.metadata,
          },
          context: { toolName: event.toolName, input },
        });
        return { block: true, reason: safety.reason };
      }

      // Determine the directory to grant access to:
      // if the path is already a directory, grant that directory;
      // otherwise grant its parent (the containing directory).
      let dirGrantPath: string;
      try {
        const stats = await stat(absolutePath);
        dirGrantPath = stats.isDirectory() ? absolutePath : dirname(absolutePath);
      } catch {
        dirGrantPath = dirname(absolutePath);
      }

      emitActionPrompted(pi, {
        feature: "pathAccess",
        action: safety.action,
        reason: safety.reason,
        prompt: {
          kind: "confirmation",
          metadata: safety.metadata,
        },
        context: { toolName: event.toolName, input },
      });

      const result = await ctx.ui.custom<PromptResult>(
        createPathAccessPromptComponent(
          event.toolName,
          safety.metadata.displayPath,
          normalizeForDisplay(dirGrantPath, ctx.cwd),
        ),
      );

      if (result === "allow-once") continue;

      if (result === "allow-session") {
        const grant = createPendingGrant(dirGrantPath, true, "memory");
        acceptedGrants.push(grant);
        await persistGrant(grant);
        continue;
      }

      if (result === "allow-global") {
        if (isGrantTooBroad(dirGrantPath)) {
          ctx.ui.notify(
            `Cannot grant access to ${normalizeForDisplay(dirGrantPath, ctx.cwd)}/ — too broad. Treating as allow once.`,
            "warning",
          );
          continue;
        }
        const grant = createPendingGrant(dirGrantPath, true, "global");
        acceptedGrants.push(grant);
        await persistGrant(grant);
        continue;
      }

      const reason = "User denied access outside working directory";
      emitActionBlocked(pi, {
        feature: "pathAccess",
        action: safety.action,
        reason,
        block: { source: "user", metadata: safety.metadata },
        context: { toolName: event.toolName, input },
      });
      return { block: true, reason };
    }
  });
}
