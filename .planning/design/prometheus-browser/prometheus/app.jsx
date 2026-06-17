// Prometheus — app shell (chrome toolbar, tab pills, theme, tweaks)
const { useState, useEffect } = React;

const LS = (k, d) => { try { const v = localStorage.getItem("pm_" + k); return v === null ? d : JSON.parse(v); } catch { return d; } };
const save = (k, v) => { try { localStorage.setItem("pm_" + k, JSON.stringify(v)); } catch {} };

// pinned tabs (icon-only pills)
const PINNED = [
  { id: "p_fsb", name: "FSB Control Panel", mono: "F", color: "#ff6b35", host: "fsb://dashboard", title: "FSB — Control Panel", kind: "fsb" },
  { id: "p_mail", name: "Mail", mono: "M", color: "#c2603f", host: "mail.prometheus.app", title: "Inbox — Mail", kind: "page" },
  { id: "p_gh", name: "GitHub", mono: "GH", color: "#2d2522", host: "github.com", title: "GitHub", kind: "page" },
  { id: "p_cal", name: "Calendar", mono: "C", color: "#0891b2", host: "cal.prometheus.app", title: "June 2026 — Calendar", kind: "page" },
];

const initialTabs = () => [
  { id: "t1", title: "New Tab", host: "", mono: "PM", color: "linear-gradient(135deg,#ff6b35,#ff8c42)", kind: "start" },
  { id: "t2", title: "Anthropic", host: "anthropic.com", mono: "A", color: "#c2603f", kind: "page" },
  { id: "t3", title: "Hacker News", host: "news.ycombinator.com", mono: "Y", color: "#ff6600", kind: "page" },
  { id: "t4", title: "Figma — Prometheus UI", host: "figma.com", mono: "Fi", color: "#9b51e0", kind: "page" },
];

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "accent": "#ff6b35",
  "panelSide": "left",
  "density": "regular"
}/*EDITMODE-END*/;

const App = () => {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const [theme, setTheme] = useState(() => LS("theme", "dark"));
  const [tabs, setTabs] = useState(initialTabs);
  const [activeId, setActiveId] = useState(() => LS("active", "t1"));
  const [collapsed, setCollapsed] = useState(() => LS("collapsed", false));
  const [panelMode, setPanelMode] = useState(() => LS("pmode", "agent"));
  const [seed, setSeed] = useState(null);

  useEffect(() => { document.documentElement.setAttribute("data-theme", theme); save("theme", theme); }, [theme]);
  useEffect(() => { document.documentElement.style.setProperty("--accent", t.accent);
    document.documentElement.style.setProperty("--accent-2", lighten(t.accent)); }, [t.accent]);
  useEffect(() => save("active", activeId), [activeId]);
  useEffect(() => save("collapsed", collapsed), [collapsed]);
  useEffect(() => save("pmode", panelMode), [panelMode]);

  const active = tabs.find((x) => x.id === activeId) || PINNED.find((x) => x.id === activeId) || tabs[0];
  const allOpen = [...PINNED.filter((p) => p.id === activeId).map(toOpen), ...tabs];

  function selectPinned(id) { setActiveId(id); }
  function selectTab(id) { setActiveId(id); }
  function closeTab(e, id) {
    e.stopPropagation();
    setTabs((prev) => {
      const next = prev.filter((x) => x.id !== id);
      if (id === activeId && next.length) setActiveId(next[Math.max(0, next.findIndex((x) => x.id === id) - 0)]?.id || next[0].id);
      return next.length ? next : initialTabs();
    });
  }
  function newTab() {
    const id = "t" + Date.now();
    setTabs((p) => [...p, { id, title: "New Tab", host: "", mono: "PM", color: "linear-gradient(135deg,#ff6b35,#ff8c42)", kind: "start" }]);
    setActiveId(id);
  }
  function navigate(item) {
    // turn a bookmark/history entry into the active tab
    setTabs((prev) => prev.map((x) => x.id === activeId
      ? { ...x, title: item.name, host: item.url, mono: item.mono, color: item.color, kind: "page" } : x));
  }
  function askFSB(prompt) {
    setSeed(typeof prompt === "string" ? prompt : "Help me with what’s on screen.");
    setPanelMode("agent");
    if (collapsed) setCollapsed(false);
  }

  const activeForTools = active.kind === "fsb"
    ? { title: "FSB — Control Panel", host: "fsb://dashboard", mono: "F", color: "#ff6b35" }
    : { title: active.title, host: active.host || "prometheus://newtab", mono: active.mono, color: active.color };

  return (
    <div className={`pm-window ${collapsed ? "panel-collapsed" : ""} ${t.panelSide === "right" ? "panel-right" : ""} density-${t.density}`}>
      {/* ---------- CHROME ---------- */}
      <div className="pm-chrome">
        <div className="pm-lights">
          <span className="dot red"><i className="fa fa-xmark"></i></span>
          <span className="dot yellow"><i className="fa fa-minus"></i></span>
          <span className="dot green"><i className="fa fa-expand"></i></span>
        </div>

        <div className="pm-navgrp">
          <button className="pm-iconbtn" title="Back"><i className="fa fa-chevron-left"></i></button>
          <button className="pm-iconbtn disabled" title="Forward"><i className="fa fa-chevron-right"></i></button>
          <button className={`pm-iconbtn ${!collapsed ? "on" : ""}`} title="Toggle sidebar" onClick={() => setCollapsed((c) => !c)}>
            <i className="fa fa-table-columns"></i>
          </button>
        </div>

        {/* tab strip */}
        <div className="pm-tabs">
          {PINNED.map((p) => (
            <button key={p.id} className={`pm-pin ${activeId === p.id ? "active" : ""}`} title={p.name} onClick={() => selectPinned(p.id)}>
              {p.mono}
            </button>
          ))}
          <span className="pm-pin-divider"></span>

          {tabs.map((tab) => {
            const isActive = tab.id === activeId;
            return (
              <div key={tab.id} className={`pm-tab ${isActive ? "active" : ""}`} onClick={() => selectTab(tab.id)} title={tab.title}>
                {!(isActive) && <div className="pm-fav" style={{ background: tab.color }}>{tab.mono}</div>}
                <span className="pm-tab-title">{tab.title}</span>
                <div className="pm-addr">
                  <i className={`fa ${tab.kind === "start" ? "fa-magnifying-glass" : "fa-lock"} lock`}></i>
                  <span className="pm-url">
                    {tab.kind === "start"
                      ? <span style={{ color: "var(--text-3)" }}>Search or enter address</span>
                      : <><span className="scheme">https://</span>{tab.host}</>}
                  </span>
                  <i className="fa fa-rotate-right" style={{ fontSize: 11, color: "var(--text-3)" }}></i>
                </div>
                <button className="pm-tab-close" onClick={(e) => closeTab(e, tab.id)} title="Close"><i className="fa fa-xmark"></i></button>
              </div>
            );
          })}
          <button className="pm-iconbtn pm-newtab" title="New tab" onClick={newTab}><i className="fa fa-plus"></i></button>
        </div>

        {/* right tools */}
        <div className="pm-tools">
          <button className="pm-iconbtn" title="Share"><i className="fa fa-arrow-up-from-bracket"></i></button>
          <button className={`pm-iconbtn ${!collapsed && panelMode === "agent" ? "on" : ""}`} title="FSB Agent" onClick={() => askFSB(null)}>
            <i className="fa fa-bolt"></i>
          </button>
          <button className="pm-iconbtn" title="All tabs" onClick={() => { setPanelMode("tabs"); setCollapsed(false); }}><i className="fa fa-copy"></i></button>
          <span className="sep"></span>
          <button className="pm-iconbtn" title="Toggle theme" onClick={() => setTheme((th) => th === "dark" ? "light" : "dark")}>
            <i className={`fa ${theme === "dark" ? "fa-sun" : "fa-moon"}`}></i>
          </button>
          <button className="pm-iconbtn" title="Menu"><i className="fa fa-ellipsis"></i></button>
        </div>
      </div>

      {/* ---------- BODY ---------- */}
      <div className="pm-body">
        <SidePanel
          mode={panelMode} setMode={setPanelMode} seed={seed}
          tabs={tabs} activeId={activeId} onSelect={selectTab} pinned={PINNED} onNavigate={navigate}
        />
        <main className="pm-content">
          {active.kind === "start"
            ? <StartPage favorites={FAVORITES} onOpenAgent={askFSB} onNavigate={navigate} />
            : <PagePlaceholder tab={activeForTools} kind={active.kind} />}
        </main>
      </div>

      {/* ---------- TWEAKS ---------- */}
      <TweaksPanel>
        <TweakSection label="Accent" />
        <TweakColor label="FSB accent" value={t.accent}
          options={["#ff6b35", "#e8553d", "#d98324", "#c2603f", "#0891b2"]}
          onChange={(v) => setTweak("accent", v)} />
        <TweakSection label="Layout" />
        <TweakRadio label="Side panel" value={t.panelSide} options={["left", "right"]} onChange={(v) => setTweak("panelSide", v)} />
        <TweakRadio label="Tab density" value={t.density} options={["compact", "regular", "comfy"]} onChange={(v) => setTweak("density", v)} />
      </TweaksPanel>
    </div>
  );
};

const FAVORITES = [
  { id: "f1", name: "FSB", url: "fsb://dashboard", mono: "F", color: "#ff6b35" },
  { id: "f2", name: "Mail", url: "mail.prometheus.app", mono: "M", color: "#c2603f" },
  { id: "f3", name: "GitHub", url: "github.com", mono: "GH", color: "#2d2522" },
  { id: "f4", name: "Figma", url: "figma.com", mono: "Fi", color: "#9b51e0" },
  { id: "f5", name: "Linear", url: "linear.app", mono: "L", color: "#5b67d8" },
  { id: "f6", name: "Notion", url: "notion.so", mono: "N", color: "#2d2522" },
  { id: "f7", name: "Calendar", url: "cal.prometheus.app", mono: "C", color: "#0891b2" },
  { id: "f8", name: "YouTube", url: "youtube.com", mono: "Y", color: "#c0392b" },
];

const PagePlaceholder = ({ tab, kind }) => (
  <div className="pm-page-ph">
    <div className="badge">
      <div className="pm-fav" style={{ background: tab.color }}>{tab.mono}</div>
      <span className="label">{tab.host}</span>
    </div>
    <span className="hint">{kind === "fsb" ? "// FSB control panel renders here" : "// rendered web content"}</span>
  </div>
);

function toOpen(p) { return { id: p.id, title: p.title, host: p.host, mono: p.mono, color: p.color, kind: p.kind }; }
function lighten(hex) {
  try {
    const n = parseInt(hex.slice(1), 16);
    let r = (n >> 16) + 22, g = ((n >> 8) & 255) + 24, b = (n & 255) + 18;
    r = Math.min(255, r); g = Math.min(255, g); b = Math.min(255, b);
    return "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
  } catch { return hex; }
}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
