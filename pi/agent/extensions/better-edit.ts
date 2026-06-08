import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { createEditToolDefinition } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";

export default function (pi: ExtensionAPI) {
	const editDef = createEditToolDefinition(process.cwd());
	const nativeRenderCall = editDef.renderCall;
	const nativeProps =
		editDef.parameters &&
		typeof editDef.parameters === "object" &&
		"properties" in editDef.parameters
			? (editDef.parameters.properties as Record<string, unknown>)
			: {};

	pi.registerTool({
		// Inherit everything from native def — renames/new fields flow through
		...editDef,

		// Only override what we touch:

		// Extend native schema with mandatory description field.
		// Note: native edit schema has additionalProperties: false, but we
		// can't use that since we inject the description field.
		parameters: Type.Object({
			description: Type.String({
				description:
					"What this edit does and why. Shown as a # comment in the UI above the command.",
				minLength: 1,
			}),
			...nativeProps,
		}),
		promptGuidelines: [
			...(editDef.promptGuidelines ?? []),
			"Every edit call must include a 'description' field explaining what the change is and why.",
		],
		// Compose with native renderCall to add description line.
		// Native edit renderCall returns a Box. Modify its first child
		// (header text) directly to prepend the description — keeps
		// everything inside the same colored background.
		renderCall(args, theme, context) {
			const nativeComponent = nativeRenderCall?.(args, theme, context);
			if (args.description && nativeComponent) {
				const firstChild = (nativeComponent as any).children?.[0];
				if (firstChild) {
					const existing = firstChild.text ?? "";
					firstChild.setText(
						`${theme.fg("dim", `# ${args.description}`)}\n\n${existing}`,
					);
				}
			}
			return nativeComponent ?? new Text("", 0, 0);
		},
		// Strip description param, delegate to native execute
		async execute(id, params, signal, onUpdate) {
			const { description: _description, ...nativeParams } = params as any;
			return editDef.execute(id, nativeParams, signal, onUpdate);
		},
	});
}
