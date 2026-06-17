// Prometheus — New Tab start page
const StartPage = ({ favorites, onOpenAgent, onNavigate }) => {
  return (
    <div className="pm-start">
      <div className="pm-hero">
        <div className="pm-hero-mark">PM</div>
        <h1>Prometheus<span className="dim">.</span></h1>
        <div className="pm-hero-sub">Search the web, or ask FSB to do it for you.</div>

        <div className="pm-omni">
          <i className="fa fa-magnifying-glass q"></i>
          <input
            placeholder="Search or enter address — try “book me a flight to Tokyo”"
            onKeyDown={(e) => { if (e.key === "Enter" && e.target.value.trim()) onOpenAgent(e.target.value.trim()); }}
          />
          <button className="ask" onClick={onOpenAgent} title="Hand this to the FSB agent">
            <i className="fa fa-bolt"></i> Ask FSB
          </button>
        </div>
      </div>

      <div className="pm-fav-wrap">
        <div className="pm-sec-label">Favorites <span className="count">{favorites.length}</span></div>
        <div className="pm-fav-grid">
          {favorites.map((f) => (
            <button key={f.id} className="pm-fav-tile" onClick={() => onNavigate(f)} title={f.url}>
              <div className="pm-fav-ico" style={{ background: f.color }}>{f.mono}</div>
              <div className="pm-fav-name">{f.name}</div>
            </button>
          ))}
        </div>
      </div>

      <div className="pm-fsb-strip">
        <div className="pm-fsb-strip-head">
          <div className="fsbmk">FSB</div>
          <h3>Suggested automations</h3>
          <span className="ai-label">agent</span>
        </div>
        <div className="pm-fsb-cards">
          {FSB_SUGGESTIONS.map((s, i) => (
            <button key={i} className="pm-fsb-card" onClick={() => onOpenAgent(s.prompt)}>
              <i className={`fa ${s.icon}`}></i>
              <div className="t">{s.title}</div>
              <div className="s">{s.sub}</div>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
};

const FSB_SUGGESTIONS = [
  { icon: "fa-inbox", title: "Triage my inbox", sub: "Archive, label & draft replies", prompt: "Triage my inbox — archive newsletters and draft replies to anything from my team." },
  { icon: "fa-cart-shopping", title: "Reorder groceries", sub: "From last week’s cart", prompt: "Reorder the groceries from my cart last week and check out." },
  { icon: "fa-calendar-check", title: "Find a meeting slot", sub: "Across 3 calendars", prompt: "Find a 45-min slot next week that works for me, Priya and Dana." },
];

window.StartPage = StartPage;
