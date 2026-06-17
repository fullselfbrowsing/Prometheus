// Prometheus — side panel: Agent / Explorer / Tabs / Tools
const { useState, useRef, useEffect } = React;

const PANEL_MODES = [
  { id: "agent",    icon: "fa-bolt",        label: "FSB Agent" },
  { id: "explorer", icon: "fa-compass",     label: "Explorer" },
  { id: "tabs",     icon: "fa-layer-group", label: "Tabs" },
  { id: "tools",    icon: "fa-wand-magic-sparkles", label: "Tools" },
];

/* ---------------- Agent (FSB automation chat) ---------------- */
const AgentMode = ({ seed }) => {
  const [msgs, setMsgs] = useState([
    { who: "system", text: "Welcome to FSB. Tell me what to automate, or pick a suggestion." },
  ]);
  const [running, setRunning] = useState(false);
  const [draft, setDraft] = useState("");
  const endRef = useRef(null);

  useEffect(() => { endRef.current && endRef.current.scrollIntoView({ block: "nearest" }); }, [msgs]);
  useEffect(() => { if (seed) send(seed); /* eslint-disable-next-line */ }, [seed]);

  const send = (val) => {
    const text = (val || draft).trim();
    if (!text) return;
    setDraft("");
    setMsgs((m) => [...m, { who: "user", text }]);
    setRunning(true);
    setTimeout(() => setMsgs((m) => [...m, { who: "tool", text: "navigating · resolving page actions" }]), 700);
    setTimeout(() => { setMsgs((m) => [...m, { who: "system", text: "On it — I’ll take it from here and report back when it’s done." }]); setRunning(false); }, 1900);
  };

  return (
    <div className="pm-agent">
      <div style={{ padding: "4px 4px 0" }}>
        <span className="pm-status"><span className="pdot"></span>{running ? "Working" : "Ready"}</span>
      </div>
      <div className="pm-msgs">
        {msgs.map((m, i) => (
          m.who === "tool"
            ? <div key={i} className="pm-msg tool"><i className="fa fa-circle-nodes"></i>{m.text}</div>
            : <div key={i} className={`pm-msg ${m.who}`}>{m.text}</div>
        ))}
        {running && <div className="pm-typing"><span></span><span></span><span></span></div>}
        <div ref={endRef}></div>
      </div>
      {msgs.length <= 1 && (
        <div className="pm-suggest">
          {["Summarize this page", "Fill this form", "Watch for price drops"].map((s) => (
            <button key={s} className="pm-chip" onClick={() => send(s)}><i className="fa fa-bolt"></i>{s}</button>
          ))}
        </div>
      )}
      <div className="pm-composer">
        <input
          value={draft}
          placeholder="Ask me to automate something…"
          onChange={(e) => setDraft(e.target.value)}
          onKeyDown={(e) => { if (e.key === "Enter") send(); }}
        />
        <button className="pm-mic" title="Voice"><i className="fa fa-microphone"></i></button>
        <button className="pm-send" onClick={() => send()} title="Send"><i className="fa fa-arrow-up"></i></button>
      </div>
    </div>
  );
};

/* ---------------- Explorer (bookmarks / reading list / history) ---------------- */
const ExplorerMode = ({ onNavigate }) => (
  <div>
    <div className="pm-sec-label"><i className="fa fa-star" style={{ fontSize: 11 }}></i> Bookmarks <span className="count">{BOOKMARKS.length}</span></div>
    {BOOKMARKS.map((b) => (
      <button key={b.id} className="pm-row" onClick={() => onNavigate(b)} style={{ width: "100%", textAlign: "left" }}>
        <div className="pm-fav" style={{ background: b.color }}>{b.mono}</div>
        <div className="pm-row-main"><div className="pm-row-title">{b.name}</div><div className="pm-row-sub">{b.url}</div></div>
      </button>
    ))}

    <div className="pm-sec-label"><i className="fa fa-glasses" style={{ fontSize: 11 }}></i> Reading list <span className="count">{READING.length}</span></div>
    {READING.map((b) => (
      <div key={b.id} className="pm-row">
        <div className="pm-fav" style={{ background: b.color }}>{b.mono}</div>
        <div className="pm-row-main"><div className="pm-row-title">{b.name}</div><div className="pm-row-sub">{b.read}</div></div>
        {b.unread && <span className="pm-group-dot" style={{ background: "var(--accent)" }}></span>}
      </div>
    ))}

    <div className="pm-sec-label"><i className="fa fa-clock-rotate-left" style={{ fontSize: 11 }}></i> History · today</div>
    {HISTORY.map((b) => (
      <button key={b.id} className="pm-row" onClick={() => onNavigate(b)} style={{ width: "100%", textAlign: "left" }}>
        <div className="pm-fav" style={{ background: b.color }}>{b.mono}</div>
        <div className="pm-row-main"><div className="pm-row-title">{b.name}</div><div className="pm-row-sub">{b.url}</div></div>
        <div className="pm-row-meta">{b.time}</div>
      </button>
    ))}
  </div>
);

/* ---------------- Tabs (groups & open tabs overview) ---------------- */
const TabsMode = ({ tabs, activeId, onSelect, pinned }) => (
  <div>
    <div className="pm-sec-label">Pinned <span className="count">{pinned.length}</span></div>
    {pinned.map((t) => (
      <button key={t.id} className={`pm-row ${t.id === activeId ? "" : ""}`} onClick={() => onSelect(t.id)} style={{ width: "100%", textAlign: "left" }}>
        <div className="pm-fav" style={{ background: t.color }}>{t.mono}</div>
        <div className="pm-row-main"><div className="pm-row-title">{t.name}</div></div>
        <i className="fa fa-thumbtack" style={{ fontSize: 10, color: "var(--text-3)" }}></i>
      </button>
    ))}

    {TAB_GROUPS.map((g) => (
      <div key={g.name} className="pm-group">
        <div className="pm-group-head">
          <span className="pm-group-dot" style={{ background: g.color }}></span>{g.name}
          <span className="pm-group-count">{g.tabs.length}</span>
        </div>
        {g.tabs.map((t) => (
          <div key={t.id} className="pm-row">
            <div className="pm-fav" style={{ background: t.color }}>{t.mono}</div>
            <div className="pm-row-main"><div className="pm-row-title">{t.name}</div><div className="pm-row-sub">{t.url}</div></div>
          </div>
        ))}
      </div>
    ))}

    <div className="pm-sec-label">Open now <span className="count">{tabs.length}</span></div>
    {tabs.map((t) => (
      <button key={t.id} className="pm-row" onClick={() => onSelect(t.id)} style={{ width: "100%", textAlign: "left", background: t.id === activeId ? "var(--accent-soft)" : undefined }}>
        <div className="pm-fav" style={{ background: t.color }}>{t.mono}</div>
        <div className="pm-row-main"><div className="pm-row-title">{t.title}</div><div className="pm-row-sub">{t.host}</div></div>
        {t.id === activeId && <i className="fa fa-circle" style={{ fontSize: 7, color: "var(--accent)" }}></i>}
      </button>
    ))}
  </div>
);

/* ---------------- Tools (page tools / annotations) ---------------- */
const ToolsMode = ({ activeTab }) => {
  const [toggles, setToggles] = useState({ reader: false, focus: true, dark: false });
  const flip = (k) => setToggles((t) => ({ ...t, [k]: !t[k] }));
  return (
    <div>
      <div className="pm-sec-label">Current page</div>
      <div className="pm-row" style={{ marginBottom: 6 }}>
        <div className="pm-fav" style={{ background: activeTab.color }}>{activeTab.mono}</div>
        <div className="pm-row-main"><div className="pm-row-title">{activeTab.title}</div><div className="pm-row-sub">{activeTab.host}</div></div>
      </div>

      {[
        { k: "reader", icon: "fa-book-open", title: "Reader mode", sub: "Strip clutter, focus on text" },
        { k: "focus",  icon: "fa-bullseye",  title: "Focus highlight", sub: "Dim everything but selection" },
        { k: "dark",   icon: "fa-moon",      title: "Force dark site", sub: "Recolor this page to dark" },
      ].map((t) => (
        <div key={t.k} className="pm-tool" onClick={() => flip(t.k)} style={{ cursor: "pointer" }}>
          <div className="ic"><i className={`fa ${t.icon}`}></i></div>
          <div className="pm-tool-main"><div className="pm-tool-title">{t.title}</div><div className="pm-tool-sub">{t.sub}</div></div>
          <div className={`pm-switch ${toggles[t.k] ? "on" : ""}`}></div>
        </div>
      ))}

      <div className="pm-sec-label"><i className="fa fa-highlighter" style={{ fontSize: 11 }}></i> Annotate</div>
      <div className="pm-chips">
        {[
          { i: "fa-highlighter", t: "Highlight" },
          { i: "fa-pen", t: "Draw" },
          { i: "fa-note-sticky", t: "Note" },
          { i: "fa-camera", t: "Snapshot" },
          { i: "fa-link", t: "Copy link" },
        ].map((c) => <button key={c.t} className="pm-chip"><i className={`fa ${c.i}`}></i>{c.t}</button>)}
      </div>

      <div className="pm-sec-label"><i className="fa fa-bolt" style={{ fontSize: 11 }}></i> FSB on this page</div>
      <div className="pm-chips">
        {["Summarize", "Extract table", "Translate", "Find prices"].map((c) =>
          <button key={c} className="pm-chip" style={{ borderColor: "var(--accent-soft-2)" }}><i className="fa fa-bolt"></i>{c}</button>)}
      </div>
    </div>
  );
};

/* ---------------- shell ---------------- */
const SidePanel = ({ mode, setMode, seed, tabs, activeId, onSelect, pinned, onNavigate }) => {
  const activeTab = tabs.find((t) => t.id === activeId) || tabs[0];
  return (
    <aside className="pm-panel">
      <div className="pm-panel-head">
        <div className="pm-brand">
          <div className="pm-mark">PM</div>
          <span className="pm-wordmark">Prometheus</span>
          <span className="pm-ver">v0.9</span>
        </div>
        <div className="pm-seg">
          {PANEL_MODES.map((m) => (
            <button key={m.id} className={mode === m.id ? "active" : ""} onClick={() => setMode(m.id)} title={m.label}>
              <i className={`fa ${m.icon}`}></i>
            </button>
          ))}
        </div>
      </div>
      <div className="pm-panel-body">
        {mode === "agent"    && <AgentMode seed={seed} />}
        {mode === "explorer" && <ExplorerMode onNavigate={onNavigate} />}
        {mode === "tabs"     && <TabsMode tabs={tabs} activeId={activeId} onSelect={onSelect} pinned={pinned} />}
        {mode === "tools"    && <ToolsMode activeTab={activeTab} />}
      </div>
    </aside>
  );
};

/* ---------------- data ---------------- */
const BOOKMARKS = [
  { id: "b1", name: "FSB Control Panel", url: "fsb://dashboard", mono: "F", color: "#ff6b35" },
  { id: "b2", name: "Anthropic", url: "anthropic.com", mono: "A", color: "#c2603f" },
  { id: "b3", name: "Linear — Roadmap", url: "linear.app/prometheus", mono: "L", color: "#5b67d8" },
  { id: "b4", name: "Figma — Prometheus UI", url: "figma.com/file/pm-ui", mono: "Fi", color: "#9b51e0" },
];
const READING = [
  { id: "r1", name: "The case for agentic browsers", read: "12 min · unread", mono: "¶", color: "#0891b2", unread: true },
  { id: "r2", name: "Designing for compact tabs", read: "6 min · unread", mono: "¶", color: "#10b981", unread: true },
  { id: "r3", name: "Warm dark UI palettes", read: "8 min · read", mono: "¶", color: "#7c6859" },
];
const HISTORY = [
  { id: "h1", name: "Hacker News", url: "news.ycombinator.com", mono: "Y", color: "#ff6600", time: "11:48" },
  { id: "h2", name: "GitHub · prometheus/browser", url: "github.com", mono: "GH", color: "#2d2522", time: "11:21" },
  { id: "h3", name: "MDN — Web Components", url: "developer.mozilla.org", mono: "M", color: "#0b5fa5", time: "10:55" },
];
const TAB_GROUPS = [
  { name: "Research", color: "#0891b2", tabs: [
    { id: "g1", name: "arXiv — browsing agents", url: "arxiv.org", mono: "X", color: "#b31b1b" },
    { id: "g2", name: "Papers we love", url: "paperswelove.org", mono: "P", color: "#10b981" },
  ]},
  { name: "Shopping", color: "#f59e0b", tabs: [
    { id: "g3", name: "Cart · checkout", url: "shop.example.com", mono: "S", color: "#f59e0b" },
  ]},
];

window.SidePanel = SidePanel;
