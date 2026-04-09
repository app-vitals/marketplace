# HTML Template Reference

Copy the CSS block verbatim into every report's `<style>` tag. Copy individual component snippets
as needed. Do not abbreviate the CSS — all styles are required for components to render correctly.

---

## Complete CSS Block

```css
:root {
  --bg:          #0f1117;
  --surface:     #1a1d27;
  --surface2:    #222636;
  --border:      #2e3352;
  --accent:      #4f8ef7;
  --accent-soft: #1e2d52;
  --green:       #34c77b;
  --green-soft:  #0f2d1e;
  --red:         #f75f5f;
  --red-soft:    #2d0f0f;
  --yellow:      #f7c948;
  --yellow-soft: #2d2510;
  --text:        #e2e6f0;
  --text-muted:  #8892a4;
  --mono:        "JetBrains Mono", "Fira Code", "Cascadia Code", monospace;
}

* { box-sizing: border-box; margin: 0; padding: 0; }

body {
  background: var(--bg);
  color: var(--text);
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  font-size: 15px;
  line-height: 1.7;
}

/* Layout */
.page { max-width: 960px; margin: 0 auto; padding: 48px 32px 80px; }

/* Header */
.report-header {
  border-bottom: 1px solid var(--border);
  padding-bottom: 32px;
  margin-bottom: 48px;
}
.report-header .tag {
  display: inline-block;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: .12em;
  text-transform: uppercase;
  color: var(--accent);
  border: 1px solid var(--accent);
  border-radius: 4px;
  padding: 2px 8px;
  margin-bottom: 16px;
}
.report-header h1 {
  font-size: 32px;
  font-weight: 700;
  line-height: 1.25;
  margin-bottom: 12px;
}
.report-header p { color: var(--text-muted); font-size: 14px; }
.report-header .meta {
  display: flex;
  gap: 24px;
  margin-top: 16px;
  flex-wrap: wrap;
}
.report-header .meta span { font-size: 13px; color: var(--text-muted); }
.report-header .meta strong { color: var(--text); }

/* Sections */
section { margin-bottom: 56px; }
h2 {
  font-size: 20px;
  font-weight: 700;
  margin-bottom: 20px;
  padding-bottom: 10px;
  border-bottom: 1px solid var(--border);
  display: flex;
  align-items: center;
  gap: 10px;
}
h2 .num {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px; height: 28px;
  border-radius: 50%;
  background: var(--accent-soft);
  color: var(--accent);
  font-size: 13px;
  font-weight: 700;
  flex-shrink: 0;
}
h3 {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: .08em;
  margin: 28px 0 12px;
}
p { margin-bottom: 14px; }

/* Callout */
.callout {
  border-radius: 8px;
  padding: 20px 24px;
  margin: 20px 0;
  border-left: 4px solid;
}
.callout.red    { background: var(--red-soft);    border-color: var(--red); }
.callout.green  { background: var(--green-soft);  border-color: var(--green); }
.callout.blue   { background: var(--accent-soft); border-color: var(--accent); }
.callout.yellow { background: var(--yellow-soft); border-color: var(--yellow); }
.callout .callout-title {
  font-weight: 700;
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: .08em;
  margin-bottom: 8px;
}
.callout.red    .callout-title { color: var(--red); }
.callout.green  .callout-title { color: var(--green); }
.callout.blue   .callout-title { color: var(--accent); }
.callout.yellow .callout-title { color: var(--yellow); }

/* Stat cards */
.stats-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
  gap: 16px;
  margin: 24px 0;
}
.stat-card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 20px 18px;
  text-align: center;
}
.stat-card .value {
  font-size: 30px;
  font-weight: 800;
  line-height: 1;
  margin-bottom: 6px;
}
.stat-card .label {
  font-size: 12px;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: .08em;
}
.stat-card.bad  .value { color: var(--red); }
.stat-card.good .value { color: var(--green); }
.stat-card.info .value { color: var(--accent); }
.stat-card.warn .value { color: var(--yellow); }

/* Before / After */
.before-after {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  margin: 24px 0;
}
@media (max-width: 600px) { .before-after { grid-template-columns: 1fr; } }
.ba-card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 24px 20px;
}
.ba-card .ba-title {
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: .1em;
  margin-bottom: 16px;
  display: flex;
  align-items: center;
  gap: 8px;
}
.ba-card.before .ba-title { color: var(--red); }
.ba-card.after  .ba-title { color: var(--green); }
.ba-card ul {
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.ba-card ul li {
  font-size: 14px;
  display: flex;
  gap: 10px;
  align-items: flex-start;
}
.ba-card ul li .icon { flex-shrink: 0; margin-top: 2px; }
.ba-card.before ul li .icon { color: var(--red); }
.ba-card.after  ul li .icon { color: var(--green); }

/* Code blocks */
pre {
  background: var(--surface2);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 18px 20px;
  overflow-x: auto;
  margin: 16px 0;
  font-size: 13px;
  font-family: var(--mono);
  line-height: 1.6;
}
code {
  font-family: var(--mono);
  font-size: 13px;
  background: var(--surface2);
  border: 1px solid var(--border);
  border-radius: 4px;
  padding: 1px 6px;
  color: #c9d1e0;
}
pre code { background: none; border: none; padding: 0; font-size: inherit; }
.comment { color: #5a6680; }
.keyword { color: #7eb8f7; }
.string  { color: #7ecdaa; }
.number  { color: #f7c948; }
.diff-add { color: var(--green); background: rgba(52,199,123,.08); display: block; border-radius: 3px; }
.diff-ctx { color: var(--text-muted); display: block; }

/* Timeline */
.timeline { position: relative; padding-left: 28px; }
.timeline::before {
  content: "";
  position: absolute;
  left: 9px; top: 6px; bottom: 6px;
  width: 2px;
  background: var(--border);
}
.tl-item { position: relative; margin-bottom: 28px; }
.tl-item::before {
  content: "";
  position: absolute;
  left: -24px; top: 8px;
  width: 10px; height: 10px;
  border-radius: 50%;
  background: var(--accent);
  border: 2px solid var(--bg);
}
.tl-item.dead-end::before { background: var(--red); }
.tl-item.success::before  { background: var(--green); }
.tl-label {
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: .1em;
  color: var(--text-muted);
  margin-bottom: 4px;
}
.tl-item h4 { font-size: 14px; font-weight: 600; margin-bottom: 6px; }
.tl-item p  { font-size: 13px; color: var(--text-muted); margin: 0; }

/* Table */
table { width: 100%; border-collapse: collapse; margin: 20px 0; }
th {
  text-align: left;
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: .1em;
  color: var(--text-muted);
  border-bottom: 1px solid var(--border);
  padding: 8px 12px;
}
td {
  padding: 12px 12px;
  border-bottom: 1px solid var(--border);
  font-size: 14px;
  vertical-align: top;
}
tr:last-child td { border-bottom: none; }
tbody tr:hover { background: var(--surface); }
.badge {
  display: inline-block;
  font-size: 11px;
  font-weight: 700;
  border-radius: 4px;
  padding: 2px 7px;
}
.badge.fix  { background: rgba(247,95,95,.15);  color: var(--red); }
.badge.skip { background: rgba(138,146,164,.1); color: var(--text-muted); }
.badge.done { background: rgba(52,199,123,.12); color: var(--green); }

/* Architecture flow */
.arch-flow {
  display: flex;
  align-items: center;
  gap: 0;
  flex-wrap: wrap;
  margin: 24px 0;
}
.arch-box {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 14px 16px;
  font-size: 13px;
  text-align: center;
  min-width: 130px;
}
.arch-box .arch-label {
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: .1em;
  color: var(--text-muted);
  margin-bottom: 4px;
}
.arch-box .arch-name { font-weight: 600; }
.arch-box.primary { border-color: var(--accent); }
.arch-box.problem { border-color: var(--red); }
.arch-arrow {
  font-size: 20px;
  color: var(--text-muted);
  padding: 0 6px;
  flex-shrink: 0;
}
.arch-lag {
  font-size: 11px;
  color: var(--red);
  font-weight: 700;
  text-align: center;
  padding: 2px 0;
}

/* Formula box */
.formula {
  background: var(--surface2);
  border: 1px solid var(--accent);
  border-radius: 8px;
  padding: 20px 24px;
  margin: 20px 0;
  font-family: var(--mono);
  font-size: 14px;
  line-height: 2;
}
.formula .result {
  color: var(--green);
  font-size: 18px;
  font-weight: 700;
  margin-top: 8px;
}

/* Phase list */
.phase-list { display: flex; flex-direction: column; gap: 12px; margin: 20px 0; }
.phase-item {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 16px 20px;
  display: flex;
  gap: 16px;
  align-items: flex-start;
}
.phase-num {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 32px; height: 32px;
  border-radius: 6px;
  background: var(--accent-soft);
  color: var(--accent);
  font-weight: 800;
  font-size: 14px;
  flex-shrink: 0;
}
.phase-content h4 { font-size: 14px; font-weight: 600; margin-bottom: 4px; }
.phase-content p  { font-size: 13px; color: var(--text-muted); margin: 0; }
.phase-content code { font-size: 12px; }

/* Footer */
.report-footer {
  border-top: 1px solid var(--border);
  padding-top: 24px;
  margin-top: 64px;
  font-size: 13px;
  color: var(--text-muted);
}
```

---

## Page Skeleton

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>TITLE — Discovery Report</title>
  <style>
    <!-- PASTE COMPLETE CSS HERE -->
  </style>
</head>
<body>
<div class="page">

  <!-- Header -->
  <header class="report-header">
    <div class="tag">Discovery Report</div>
    <h1>TITLE</h1>
    <p>SUBTITLE</p>
    <div class="meta">
      <span><strong>Date completed:</strong> DATE</span>
      <span><strong>Status:</strong> STATUS</span>
      <!-- add additional meta fields as needed -->
    </div>
  </header>

  <!-- Sections 1–8 go here -->

  <footer class="report-footer">
    Generated with Claude Code &middot; <em>discovery-report</em> skill &middot; DATE
  </footer>

</div>
</body>
</html>
```

---

## Component Snippets

### Section heading

```html
<section>
  <h2><span class="num">N</span> Section Title</h2>
  <!-- content -->
</section>
```

---

### Callout

```html
<!-- red = critical problem, yellow = warning, blue = info/explanation, green = resolution -->
<div class="callout red">
  <div class="callout-title">Title</div>
  Body text here.
</div>
```

---

### Stat Cards Row

```html
<!-- bad=red, good=green, info=blue, warn=yellow -->
<div class="stats-row">
  <div class="stat-card bad">
    <div class="value">25.7s</div>
    <div class="label">Max Aurora lag observed</div>
  </div>
  <div class="stat-card warn">
    <div class="value">30+</div>
    <div class="label">Manual retries per week</div>
  </div>
  <div class="stat-card good">
    <div class="value">60s</div>
    <div class="label">initialDelay applied</div>
  </div>
  <div class="stat-card info">
    <div class="value">3</div>
    <div class="label">Files changed</div>
  </div>
</div>
```

---

### Timeline

```html
<!-- default dot = blue, dead-end = red dot, success = green dot -->
<div class="timeline">

  <div class="tl-item dead-end">
    <div class="tl-label">Dead End</div>
    <h4>First Hypothesis: Title</h4>
    <p>What was tried and why it failed to explain the problem.</p>
  </div>

  <div class="tl-item">
    <div class="tl-label">Step</div>
    <h4>Neutral investigation step</h4>
    <p>What was done and what was learned.</p>
  </div>

  <div class="tl-item success">
    <div class="tl-label">Breakthrough</div>
    <h4>Root cause identified</h4>
    <p>What the data showed and why this was definitive.</p>
  </div>

</div>
```

---

### Architecture Flow

```html
<!-- primary = blue border, problem = red border, default = grey border -->
<div class="arch-flow">
  <div class="arch-box primary">
    <div class="arch-label">Primary</div>
    <div class="arch-name">us-east-1</div>
  </div>
  <div class="arch-arrow">&#8594;</div>
  <div style="display:flex;flex-direction:column;align-items:center;gap:4px;">
    <div class="arch-lag">up to 25.7s lag</div>
    <div class="arch-box problem">
      <div class="arch-label">Secondary</div>
      <div class="arch-name">us-east-2</div>
    </div>
  </div>
  <div class="arch-arrow">&#8594;</div>
  <div class="arch-box">
    <div class="arch-label">Secondary</div>
    <div class="arch-name">eu-central-1</div>
  </div>
</div>
```

Use `.arch-lag` above an arch-box to annotate a connection with latency or a status note.
Use `flex-direction:column` wrapper when you need to stack the annotation + box vertically.

---

### Before / After Cards

```html
<div class="before-after">
  <div class="ba-card before">
    <div class="ba-title">&#10007; Before</div>
    <ul>
      <li><span class="icon">&#10005;</span><span>Smoke tests start immediately at T=0</span></li>
      <li><span class="icon">&#10005;</span><span>Aurora replication still in flight</span></li>
      <li><span class="icon">&#10005;</span><span>False failure, manual retry required</span></li>
    </ul>
  </div>
  <div class="ba-card after">
    <div class="ba-title">&#10003; After</div>
    <ul>
      <li><span class="icon">&#10003;</span><span>Smoke tests delayed by 60s</span></li>
      <li><span class="icon">&#10003;</span><span>Aurora replication completes during delay</span></li>
      <li><span class="icon">&#10003;</span><span>Tests pass on first attempt, zero retries</span></li>
    </ul>
  </div>
</div>
```

---

### Formula Box

```html
<div class="formula">
  <span class="comment">// Formula: round up to next 30s boundary + 30s safety buffer</span>
  <br>
  max_lag = 25,735ms = <span class="number">25.7s</span>
  <br>
  next_boundary = ceil(<span class="number">25.7</span> / 30) &times; 30 = <span class="number">30s</span>
  <br>
  result = <span class="number">30s</span> + 30s buffer
  <br>
  <div class="result">&rarr; initialDelay: "60s"</div>
</div>
```

---

### Code Block — Diff Style

```html
<pre><code><span class="comment"># path/to/file.yaml</span>
spec:
  metrics:
  - name: smoke-tests
<span class="diff-add">    initialDelay: {{ .Values.canary.analysis.tests.initialDelay }}</span>
<span class="diff-ctx">    provider:</span>
<span class="diff-ctx">      job:</span>
<span class="diff-ctx">        ...</span></code></pre>
```

`.diff-add` = green (new lines). `.diff-ctx` = muted (unchanged context lines).

---

### Code Block — Command Style

```html
<pre><code><span class="comment"># Run against each secondary region datasource</span>
curl -s --cookie <span class="string">"grafana_session=$GRAFANA_SESSION"</span> \
  -H <span class="string">"Content-Type: application/json"</span> -X POST \
  https://grafana.apps.verygood.systems/api/ds/query \
  -d <span class="string">'{...}'</span> | jq <span class="string">'...'</span></code></pre>
```

Available spans: `.comment` (grey), `.keyword` (blue), `.string` (green), `.number` (yellow).

---

### Phase List

```html
<div class="phase-list">
  <div class="phase-item">
    <div class="phase-num">1</div>
    <div class="phase-content">
      <h4>Step Title</h4>
      <p>Description. File: <code>path/to/file.yaml</code></p>
    </div>
  </div>
  <div class="phase-item">
    <div class="phase-num">2</div>
    <div class="phase-content">
      <h4>Next Step</h4>
      <p>Description of what this step involves.</p>
    </div>
  </div>
</div>
```

---

### Table with Badges

```html
<table>
  <thead>
    <tr>
      <th>Environment</th>
      <th>Cluster</th>
      <th>Max Lag</th>
      <th>Action</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>us-east-2</strong> live</td>
      <td><code>cluster-name</code></td>
      <td style="color: var(--red); font-weight: 700;">25,735ms</td>
      <td><span class="badge fix">Fix</span></td>
    </tr>
    <tr>
      <td>eu-central-1</td>
      <td>&mdash;</td>
      <td style="color: var(--text-muted);">No data</td>
      <td><span class="badge skip">Skip</span></td>
    </tr>
    <tr>
      <td>us-east-1</td>
      <td><code>primary-cluster</code></td>
      <td style="color: var(--green);">0ms</td>
      <td><span class="badge done">Done</span></td>
    </tr>
  </tbody>
</table>
```

Badge variants: `.badge.fix` (red), `.badge.skip` (muted grey), `.badge.done` (green).

---

### Sources & Evidence Table (Section 8)

```html
<section>
  <h2><span class="num">8</span> Sources &amp; Evidence</h2>
  <p>Every factual claim in this report traces to one of the following sources.</p>
  <table>
    <thead>
      <tr>
        <th>Source Type</th>
        <th>Name / URL / Query</th>
        <th>What It Proved</th>
        <th>Used In</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>CloudWatch query</td>
        <td><code>AWS/RDS · AuroraGlobalDBReplicationLag · uid: f4adeb02-...</code></td>
        <td>Max 14-day replication lag in us-east-2 is 25,735ms</td>
        <td>§2, §4</td>
      </tr>
      <tr>
        <td>Source file</td>
        <td><code>helm-charts/product/app-sync/templates/analysis-smoke-tests.yaml</code></td>
        <td>Confirmed absence of <code>initialDelay</code> field in AnalysisTemplate</td>
        <td>§1, §5, §6</td>
      </tr>
      <tr>
        <td>Verbal</td>
        <td>Dave Odell</td>
        <td>Confirmed 30+ manual retries per week from operational experience</td>
        <td>§2</td>
      </tr>
    </tbody>
  </table>
</section>
```
