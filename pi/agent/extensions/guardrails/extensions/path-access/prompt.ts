import {
  Container,
  Key,
  matchesKey,
  Spacer,
  Text,
  visibleWidth,
} from "@earendil-works/pi-tui";

export type PromptResult =
  | "allow-once"
  | "allow-session"
  | "allow-global"
  | "deny";

export function createPathAccessPromptComponent(
  toolName: string,
  displayPath: string,
  grantDirDisplay: string,
) {
  return (
    tui: { terminal: { columns: number }; requestRender(): void },
    theme: {
      fg(color: string, text: string): string;
      bg(color: string, text: string): string;
      bold(text: string): string;
    },
    _kb: unknown,
    done: (result: PromptResult) => void,
  ) => {
    const options = [
      { label: "Allow once", result: "allow-once" as const },
      { label: "Allow this session", result: "allow-session" as const },
      { label: "Allow globally", result: "allow-global" as const },
      { label: "Deny", result: "deny" as const },
    ];

    let selectedIndex = 0;

    const container = new Container();
    const border = (s: string) => theme.fg("warning", s);

    container.addChild(
      new Text(
        theme.fg("warning", theme.bold("Outside Workspace Access")),
        1,
        0,
      ),
    );
    container.addChild(new Spacer(1));
    container.addChild(
      new Text(
        theme.fg(
          "text",
          `\`${toolName}\` targets a path outside the working directory.`,
        ),
        1,
        0,
      ),
    );
    container.addChild(new Spacer(1));
    container.addChild(
      new Text(theme.fg("text", displayPath), 1, 0),
    );
    container.addChild(new Spacer(1));
    container.addChild(
      new Text(
        theme.fg("text", `Grant access to "${grantDirDisplay}"?`),
        1,
        0,
      ),
    );
    container.addChild(new Spacer(1));

    const optionLines: Text[] = options.map(() => new Text("", 1, 0));
    for (const line of optionLines) {
      container.addChild(line);
    }

    container.addChild(new Spacer(1));
    container.addChild(
      new Text(
        theme.fg("dim", "↑/↓/Tab select · Enter select · Esc deny"),
        1,
        0,
      ),
    );

    const renderOptions = () => {
      for (let i = 0; i < options.length; i++) {
        const label = options[i].label;
        if (i === selectedIndex) {
          optionLines[i].setText(
            theme.bg("selectedBg", theme.fg("accent", ` ${label} `)),
          );
        } else {
          optionLines[i].setText(theme.fg("dim", ` ${label} `));
        }
      }
    };

    renderOptions();

    const moveSelection = (direction: number) => {
      selectedIndex =
        (selectedIndex + direction + options.length) % options.length;
      renderOptions();
      tui.requestRender();
    };

    return {
      render: (width: number) => {
        const innerWidth = Math.max(1, width - 2);
        const contentWidth = Math.max(1, width - 4);
        const raw = container.render(contentWidth);
        const top = border(`╭${"─".repeat(innerWidth)}╮`);
        const bottom = border(`╰${"─".repeat(innerWidth)}╯`);
        const left = border("│");
        const right = border("│");
        const lines = raw.map((line) => {
          const visible = visibleWidth(line);
          const pad = Math.max(0, contentWidth - visible);
          return `${left} ${line}${" ".repeat(pad)} ${right}`;
        });
        return [top, ...lines, bottom];
      },
      invalidate: () => container.invalidate(),
      handleInput: (data: string) => {
        if (
          matchesKey(data, Key.up) ||
          data === "k" ||
          matchesKey(data, Key.shift("tab"))
        ) {
          moveSelection(-1);
          return;
        }
        if (
          matchesKey(data, Key.down) ||
          data === "j" ||
          matchesKey(data, Key.tab)
        ) {
          moveSelection(1);
          return;
        }
        if (matchesKey(data, Key.enter) || data === " ") {
          done(options[selectedIndex].result);
          return;
        }
        if (matchesKey(data, Key.escape) || data === "\u001b") {
          done("deny");
        }
      },
    };
  };
}
