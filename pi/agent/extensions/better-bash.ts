import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { createBashToolDefinition } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";

const DEFAULT_TIMEOUT = 120;

export default function (pi: ExtensionAPI) {
	const bashDef = createBashToolDefinition(process.cwd());
	const nativeRenderCall = bashDef.renderCall;
	const nativeProps =
		bashDef.parameters &&
		typeof bashDef.parameters === "object" &&
		"properties" in bashDef.parameters
			? (bashDef.parameters.properties as Record<string, unknown>)
			: {};

	pi.registerTool({
		name: bashDef.name,
		label: bashDef.label,
		description: bashDef.description,
		// Extend native schema with mandatory description field
		parameters: Type.Object({
			description: Type.String({
				description:
					"What this command does and why. Shown as a # comment in the UI above the command.",
				minLength: 1,
			}),
			...nativeProps,
		}),
		// Inherit native prompt metadata
		promptSnippet: bashDef.promptSnippet,
		promptGuidelines: [
			...(bashDef.promptGuidelines ?? []),
			"Every bash call must include a 'description' field explaining what the command does and why.",
		],
		// Compose with native renderCall to add description line
		renderCall(args, theme, context) {
			const text =
				nativeRenderCall?.(args, theme, context) ?? new Text("", 0, 0);
			if (args.description) {
				const existing = (text as any).text;
				text.setText(`${theme.fg("dim", `# ${args.description}`)}\n\n${existing}`);
			}
			return text;
		},
		// Inherit native renderResult unchanged
		renderResult: bashDef.renderResult,
		// Strip description param, apply default timeout, delegate to native execute
		async execute(id, params, signal, onUpdate) {
			const { description: _description, command, timeout } = params as any;
			return bashDef.execute(
				id,
				{ command, timeout: timeout ?? DEFAULT_TIMEOUT },
				signal,
				onUpdate,
			);
		},
	});
}
