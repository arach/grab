### Key Decisions

Decision            Recommendation
-------------------------------------------------------------------
Hotkey              Cmd+Shift+V, user-configurable
Log detection       Regex timestamps, known prefixes
Prompt detection    Heuristics (length + style)
Auto-dismiss        5s default, cancel-on-hover, Esc support
UI Slots            3 max: prompt, log, image
Cursor position     Bottom-left/right of pointer, not fixed
Drag support        Image draggable, text click-to-copy


### Categorization Logic

// Clipboard item representation
type ClipboardItem = {
  content: string | Blob;
  mimeType: string;
  timestamp: number;
};

function categorizeClipboard(items: ClipboardItem[]) {
  const lastPrompt = items.findLast(isPrompt);
  const lastLog = items.findLast(isLog);
  const lastImage = items.findLast(isImage);
  
  return compact([lastPrompt, lastLog, lastImage]).slice(0, 3);
}

function isPrompt(item: ClipboardItem): boolean {
  if (item.mimeType !== 'text/plain') return false;
  const text = item.content as string;
  return text.length > 50 &&
         (text.trim().endsWith('?') || /^(write|generate|create|build)\b/i.test(text));
}

function isLog(item: ClipboardItem): boolean {
  if (item.mimeType !== 'text/plain') return false;
  const text = item.content as string;
  return /\b(INFO|WARN|ERROR|DEBUG)\b/.test(text) ||
         /\d{2}:\d{2}:\d{2}/.test(text) ||
         /^\s*{.*}\s*$/s.test(text); // JSON heuristic
}

function isImage(item: ClipboardItem): boolean {
  return ['image/png', 'image/jpeg'].includes(item.mimeType);
}

function compact(arr) {
  return arr.filter(Boolean);
}

### Visual Layout

┌───────────────┬───────────────┬───────────────┐
│     Logs      │    Prompts    │     Images    │
├───────────────┼───────────────┼───────────────┤
│ Log item #1   │ Prompt #1     │ Image #1 🖼   │
│ Log item #2   │ Prompt #2     │ Image #2 🖼   │
│ ...           │ ...           │ ...           │
│ Log item #N   │ Prompt #N     │ Image #N 🖼   │
└───────────────┴───────────────┴───────────────┘

🖼️ Visual Considerations:
	•	Compact grid cells:
	•	~150px width per column, scalable vertically.
	•	Design accents:
	•	Slightly translucent dark/light background to avoid visual clutter.
	•	Rounded corners & shadow for overlay aesthetic.
	•	Time-based Auto-dismiss Indicator:
	•	Progress bar subtly beneath grid, spanning full width.
	•	Cancel-on-hover stops progress temporarily.


🧩 Advantages of This Layout:
	•	Efficient scanability: immediately know what’s available.
	•	Clear structure: minimizes cognitive load.
	•	Flexibility: expands gracefully if more history is introduced later.
	•	Drag-friendly: intuitive UX for quick LLM-context workflows.