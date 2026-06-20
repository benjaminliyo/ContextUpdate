import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const NUDGE_MARKER = "CONTEXT-UPDATE-REMINDER";

const extensionDir = dirname(fileURLToPath(import.meta.url));
const packageRoot = resolve(extensionDir, "../..");
const skillsDir = resolve(packageRoot, "skills");
const nudgePath = resolve(packageRoot, "hooks", "nudge.txt");

let cachedNudge: string | null | undefined;

function getNudge(): string | null {
	if (cachedNudge !== undefined) return cachedNudge;
	try {
		cachedNudge = readFileSync(nudgePath, "utf8").trim();
	} catch {
		cachedNudge = null;
	}
	return cachedNudge;
}

export default function contextUpdatePiExtension(pi: ExtensionAPI) {
	let injectNudge = true;

	pi.on("resources_discover", async () => ({
		skillPaths: [skillsDir],
	}));

	pi.on("session_start", async () => {
		injectNudge = true;
	});

	pi.on("session_compact", async () => {
		injectNudge = true;
	});

	pi.on("agent_end", async () => {
		injectNudge = false;
	});

	pi.on("context", async (event) => {
		if (!injectNudge) return;
		if (event.messages.some(messageContainsNudge)) return;

		const nudge = getNudge();
		if (!nudge) return;

		const nudgeMessage = {
			role: "user" as const,
			content: [{ type: "text" as const, text: nudge }],
			timestamp: Date.now(),
		};

		const insertAt = firstNonCompactionSummaryIndex(event.messages);
		return {
			messages: [
				...event.messages.slice(0, insertAt),
				nudgeMessage,
				...event.messages.slice(insertAt),
			],
		};
	});
}

function messageContainsNudge(message: unknown): boolean {
	const content = (message as { content?: unknown }).content;
	if (typeof content === "string") return content.includes(NUDGE_MARKER);
	if (!Array.isArray(content)) return false;
	return content.some((part) => {
		return (
			part &&
			typeof part === "object" &&
			(part as { type?: unknown }).type === "text" &&
			typeof (part as { text?: unknown }).text === "string" &&
			(part as { text: string }).text.includes(NUDGE_MARKER)
		);
	});
}

function firstNonCompactionSummaryIndex(messages: unknown[]): number {
	let index = 0;
	while ((messages[index] as { role?: unknown } | undefined)?.role === "compactionSummary") {
		index += 1;
	}
	return index;
}
