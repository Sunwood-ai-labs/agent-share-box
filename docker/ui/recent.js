const recentEl = document.querySelector("#recent");
const recentCountEl = document.querySelector("#recent-count");
const storageEl = document.querySelector("#storage");
const rowTemplate = document.querySelector("#row-template");
const MAX_DEPTH = 5;
const MAX_ROWS = 80;

renderRecent();

async function renderRecent() {
  try {
    const files = [];
    const root = await crawl("/", 0, files);
    storageEl.textContent = stripHtml(root.srvinf || "ready");
    files.sort((a, b) => b.ts - a.ts);
    const visible = files.slice(0, MAX_ROWS);
    recentCountEl.textContent = String(visible.length);
    recentEl.textContent = "";
    visible.forEach((file) => recentEl.append(row(file)));
  } catch (error) {
    storageEl.textContent = "unavailable";
    recentCountEl.textContent = "0";
    recentEl.innerHTML = `<div class="error">Could not load recent files. ${escapeHtml(error.message)}</div>`;
  }
}

async function crawl(path, depth, files) {
  const data = await listFolder(path);
  for (const item of data.files || []) {
    const name = decodeURIComponent(item.href || "");
    files.push({
      name,
      path,
      ext: item.ext || "file",
      ts: Number(item.ts || 0),
      size: Number(item.sz || 0),
    });
  }

  if (depth >= MAX_DEPTH) return data;
  for (const dir of data.dirs || []) {
    const name = decodeURIComponent((dir.href || "").replace(/\/$/, ""));
    if (!name || name === "lost+found") continue;
    await crawl(normalizePath(`${path}${name}/`), depth + 1, files);
  }

  return data;
}

async function listFolder(path) {
  const res = await fetch(`/browse${path === "/" ? "/" : path}?ls`, {
    headers: { Accept: "application/json" },
    cache: "no-store",
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

function row(file) {
  const node = rowTemplate.content.firstElementChild.cloneNode(true);
  node.classList.add("file");
  node.href = fileHref(file.path, file.name);
  node.querySelector(".kind").textContent = file.ext;
  node.querySelector(".name").textContent = `${file.path}${file.name}`.replace("//", "/");
  node.querySelector(".meta").textContent = formatDate(file.ts);
  return node;
}

function fileHref(path, name) {
  if (name.toLowerCase().endsWith(".md")) return `/view${path}${encodeURIComponent(name)}`;
  return `/browse${path}${encodeURIComponent(name)}?v`;
}

function normalizePath(path) {
  const clean = decodeURIComponent(path || "/").replace(/^\/+/, "").replace(/\/+$/, "");
  return clean ? `/${clean}/` : "/";
}

function formatDate(ts) {
  if (!ts) return "";
  return new Intl.DateTimeFormat(undefined, {
    month: "short",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date(ts * 1000));
}

function stripHtml(value) {
  const tmp = document.createElement("div");
  tmp.innerHTML = value;
  return tmp.textContent || tmp.innerText || "";
}

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, (ch) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    "\"": "&quot;",
    "'": "&#39;",
  }[ch]));
}
