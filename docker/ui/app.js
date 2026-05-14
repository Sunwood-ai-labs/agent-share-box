const state = {
  path: normalizePath(location.hash.slice(1) || "/"),
};

stripUrlCredentials();

const foldersEl = document.querySelector("#folders");
const filesEl = document.querySelector("#files");
const folderCountEl = document.querySelector("#folder-count");
const fileCountEl = document.querySelector("#file-count");
const storageEl = document.querySelector("#storage");
const crumbsEl = document.querySelector("#crumbs");
const rowTemplate = document.querySelector("#row-template");

window.addEventListener("hashchange", () => {
  state.path = normalizePath(location.hash.slice(1) || "/");
  render();
});

render();

function normalizePath(path) {
  const clean = decodeURIComponent(path || "/").replace(/^\/+/, "").replace(/\/+$/, "");
  return clean ? `/${clean}/` : "/";
}

function browsePath(path) {
  return `/browse${path === "/" ? "/" : path}`;
}

async function render() {
  setLoading();
  renderCrumbs();

  try {
    const res = await fetch(sameOriginUrl(`${browsePath(state.path)}?ls`), {
      headers: { Accept: "application/json" },
      cache: "no-store",
    });

    if (!res.ok) {
      throw new Error(`HTTP ${res.status}`);
    }

    const data = await res.json();
    renderRows(data);
    storageEl.textContent = stripHtml(data.srvinf || "ready");
  } catch (error) {
    foldersEl.innerHTML = "";
    filesEl.innerHTML = `<div class="error">Could not load files. ${escapeHtml(error.message)}</div>`;
    folderCountEl.textContent = "0";
    fileCountEl.textContent = "0";
    storageEl.textContent = "unavailable";
  }
}

function stripUrlCredentials() {
  const current = new URL(location.href);
  if (!current.username && !current.password) return;

  current.username = "";
  current.password = "";
  history.replaceState(null, "", current.toString());
}

function sameOriginUrl(path) {
  return `${location.protocol}//${location.host}${path}`;
}

function setLoading() {
  foldersEl.textContent = "";
  filesEl.textContent = "";
  storageEl.textContent = "loading...";
}

function renderCrumbs() {
  crumbsEl.textContent = "";
  const root = crumbLink("/", "root");
  crumbsEl.append(root);

  const parts = state.path.split("/").filter(Boolean);
  let current = "/";
  for (const part of parts) {
    crumbsEl.append(document.createTextNode("/"));
    current += `${part}/`;
    crumbsEl.append(crumbLink(current, part));
  }
}

function crumbLink(path, label) {
  const a = document.createElement("a");
  a.href = `#${encodeURIComponent(path)}`;
  a.textContent = label;
  return a;
}

function renderRows(data) {
  foldersEl.textContent = "";
  filesEl.textContent = "";

  const dirs = data.dirs || [];
  const files = data.files || [];
  folderCountEl.textContent = String(dirs.length);
  fileCountEl.textContent = String(files.length);

  dirs.forEach((item) => {
    const name = decodeURIComponent((item.href || "").replace(/\/$/, ""));
    const nextPath = normalizePath(`${state.path}${name}/`);
    foldersEl.append(row({
      className: "folder",
      kind: "dir",
      name: `${name}/`,
      meta: formatSize(item.sz),
      href: `#${encodeURIComponent(nextPath)}`,
    }));
  });

  files.forEach((item) => {
    const name = decodeURIComponent(item.href || "");
    const href = fileHref(state.path, name);
    filesEl.append(row({
      className: "file",
      kind: item.ext || "file",
      name,
      meta: formatSize(item.sz),
      href,
    }));
  });
}

function fileHref(path, name) {
  const encodedName = encodeURIComponent(name);
  const encodedPath = path === "/" ? "/" : path;
  if (name.toLowerCase().endsWith(".md")) {
    return `/view${encodedPath}${encodedName}`;
  }

  return `${browsePath(path)}${encodedName}?v`;
}

function row({ className, kind, name, meta, href }) {
  const node = rowTemplate.content.firstElementChild.cloneNode(true);
  node.classList.add(className);
  node.href = href;
  node.querySelector(".kind").textContent = kind;
  node.querySelector(".name").textContent = name;
  node.querySelector(".meta").textContent = meta;
  return node;
}

function formatSize(value) {
  const size = Number(value || 0);
  if (size < 1024) return `${size} B`;
  if (size < 1024 * 1024) return `${(size / 1024).toFixed(size < 10240 ? 1 : 0)} KB`;
  if (size < 1024 * 1024 * 1024) return `${(size / 1024 / 1024).toFixed(1)} MB`;
  return `${(size / 1024 / 1024 / 1024).toFixed(1)} GB`;
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
