import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { createWriteToolDefinition } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";

export default function (pi: ExtensionAPI) {
	const writeDef = createWriteToolDefinition(process.cwd());
	const nativeRenderCall = writeDef.renderCall;
	const nativeProps =
		writeDef.parameters &&
		typeof writeDef.parameters === "object" &&
		"properties" in writeDef.parameters
			? (writeDef.parameters.properties as Record<string, unknown>)
			: {};

	pi.registerTool({
		// Inherit everything from native def — renames/new fields flow through
		...writeDef,

		// Only override what we touch:

		// Extend native schema with mandatory description field
		parameters: Type.Object({
			description: Type.String({
				description:
					"What this write does and why. Shown as a # comment in the UI above the command.",
				minLength: 1,
			}),
			...nativeProps,
		}),
		promptGuidelines: [
			...(writeDef.promptGuidelines ?? []),
			"Every write call must include a 'description' field explaining what the change is and why.",
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
		// Strip description param, delegate to native execute
		async execute(id, params, signal, onUpdate) {
			const { description: _description, ...nativeParams } = params as any;
			return writeDef.execute(id, nativeParams, signal, onUpdate);
		},
	});
}
