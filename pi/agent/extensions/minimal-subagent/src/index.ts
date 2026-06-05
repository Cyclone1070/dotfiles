import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { discoverAgents } from "./agents.ts";
import { renderSubagentCall, renderSubagentResult } from "./render.ts";
import { runSubagent } from "./runner.ts";
import { getResultSummaryText } from "./runner-events.js";
import { resolveSettings } from "./settings.ts";
import {
  type SubagentDetails,
  type SubagentResult,
  emptyUsage,
  isResultError,
} from "./types.ts";

function makeDetails(results: SubagentResult[], extra?: Omit<SubagentDetails, "results">): SubagentDetails {
  return { results, ...extra };
}

function failedResult(agent: string, task: string, message: string): SubagentResult {
  return {
    agent,
    agentSource: "unknown",
    task,
    exitCode: 1,
    messages: [],
    response: "",
    stderr: message,
    usage: emptyUsage(),
    stopReason: "error",
    errorMessage: message,
  };
}

export default function (pi: ExtensionAPI) {
  const _agentDiscovery = discoverAgents(process.cwd());
  const _agentNames = _agentDiscovery.agents
    .map((a) => `${a.name} (${a.description})`)
    .join(", ");
  const _agentNamesShort = _agentDiscovery.agents.map((a) => a.name).join(", ");

  const _params = Type.Object({
    agent: Type.String({
      description: _agentNames
        ? `Name of the subagent. Available: ${_agentNames}.`
        : "Name of the configured agent to run. Agents are loaded from ~/.pi/agent/agents/*.md and project .pi/agents/*.md files.",
    }),
    task: Type.String({
      description: "The focused task for the subagent. Include the expected scope, decision boundary, and return shape.",
    }),
  });

  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description:
      _agentNames
        ? `Run one named subagent. Available agents: ${_agentNames}.`
        : "Run one named subagent on one focused task in an isolated Pi subprocess.",
    promptSnippet:
      _agentNames
        ? `Run a named subagent (${_agentNamesShort})`
        : "Run a named subagent on a focused task",
    parameters: _params,
    renderCall: renderSubagentCall,
    renderResult: renderSubagentResult,

    async execute(_toolCallId, params, signal, onUpdate, ctx) {
      const discovery = discoverAgents(ctx.cwd);
      const agent = discovery.agents.find((candidate) => candidate.name === params.agent);

      if (!agent) {
        const availableAgents = discovery.agents.map((candidate) => candidate.name);
        const message = availableAgents.length > 0
          ? `Unknown subagent "${params.agent}". Available agents: ${availableAgents.join(", ")}.`
          : "No subagents found. Add agent markdown files to ~/.pi/agent/agents or .pi/agents.";
        const result = failedResult(params.agent, params.task, message);
        return {
          content: [{ type: "text" as const, text: message }],
          details: makeDetails([result], {
            availableAgents,
            projectAgentsDir: discovery.projectAgentsDir,
          }),
          isError: true,
        };
      }

      const settings = resolveSettings(ctx.cwd);
      const result = await runSubagent({
        cwd: ctx.cwd,
        agent,
        task: params.task,
        settings,
        signal,
        onUpdate,
        makeDetails: (results) => makeDetails(results, {
          projectAgentsDir: discovery.projectAgentsDir,
        }),
      });

      if (isResultError(result)) {
        return {
          content: [
            {
              type: "text" as const,
              text: `Subagent ${result.stopReason || "failed"}: ${getResultSummaryText(result)}`,
            },
          ],
          details: makeDetails([result], {
            projectAgentsDir: discovery.projectAgentsDir,
          }),
          isError: true,
        };
      }

      return {
        content: [{ type: "text" as const, text: getResultSummaryText(result) }],
        details: makeDetails([result], {
          projectAgentsDir: discovery.projectAgentsDir,
        }),
      };
    },
  });
}
