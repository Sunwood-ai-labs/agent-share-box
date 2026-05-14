const state = {
  path: normalizePath(new URLSearchParams(location.search).get("path") || "/"),
};

const crumbsEl = document.querySelector("#crumbs");
const storageEl = document.querySelector("#storage");
const itemsEl = document.querySelector("#items");
const itemCountEl = document.querySelector("#item-count");
const pathInputEl = document.querySelector("#path-input");
const folderInputEl = document.querySelector("#folder-input");
const fileInputEl = document.querySelector("#file-input");
const messageEl = document.querySelector("#message");
const rowTemplate = document.querySelector("#row-template");

document.querySelector("#open-folder").addEventListener("click", () => {
  state.path = normalizePath(pathInputEl.value || "/");
  history.replaceState(null, "", `/manage?path=${encodeURIComponent(state.path)}`);
  render();
});

document.querySelector("#refresh").addEventListener("click", render);
document.querySelector("#upload").addEventListener("click", uploadFile);
document.querySelector("#create-folder").addEventListener("click", createFolder);

render();

async function render() {
  pathInputEl.value = state.path;
  renderCrumbs();
  setMessage("loading...");
  itemsEl.textContent = "";

  try {
    const data = await listFolder(state.path);
    const entries = [
      ...(data.dirs || []).map((item) => ({ ...item, type: "dir" })),
      ...(data.files || []).map((item) => ({ ...item, type: "file" })),
    ];

    itemCountEl.textContent = String(entries.length);
    storageEl.textContent = stripHtml(data.srvinf || "ready");
    entries.forEach((item) => itemsEl.append(row(item)));
    setMessage("ready");
  } catch (error) {
    itemCountEl.textContent = "0";
    storageEl.textContent = "unavailable";
    setMessage(error.message, true);
  }
}

async function uploadFile() {
  const file = fileInputEl.files[0];
  if (!file) {
    setMessage("choose a file first", true);
    return;
  }

  const url = `${state.path}${encodeURIComponent(file.name)}`.replace("//", "/");
  setMessage(`uploading ${file.name}...`);
  const res = await fetch(url, { method: "PUT", body: file });
  if (!res.ok) {
    setMessage(`upload failed: HTTP ${res.status}`, true);
    return;
  }

  fileInputEl.value = "";
  setMessage(`uploaded ${file.name}`);
  render();
}

async function createFolder() {
  const name = folderInputEl.value.trim();
  if (!name) {
    setMessage("enter a folder name", true);
    return;
  }

  const url = normalizePath(`${state.path}${name}`);
  setMessage(`creating ${url}...`);
  const res = await fetch(url, { method: "MKCOL" });
  if (!res.ok && res.status !== 405) {
    setMessage(`create failed: HTTP ${res.status}`, true);
    return;
  }

  folderInputEl.value = "";
  setMessage(`created ${url}`);
  render();
}

async function listFolder(path) {
  const res = await fetch(`/browse${path === "/" ? "/" : path}?ls`, {
    headers: { Accept: "application/json" },
    cache: "no-store",
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

function row(item) {
  const node = rowTemplate.content.firstElementChild.cloneNode(true);
  const name = decodeURIComponent((item.href || "").replace(/\/$/, ""));
  const isDir = item.type === "dir";
  const nextPath = normalizePath(`${state.path}${name}/`);
  node.classList.add(isDir ? "folder" : "file");
  node.href = isDir ? `/manage?path=${encodeURIComponent(nextPath)}` : fileHref(state.path, name);
  node.querySelector(".kind").textContent = isDir ? "dir" : (item.ext || "file");
  node.querySelector(".name").textContent = isDir ? `${name}/` : name;
  node.querySelector(".meta").textContent = formatSize(item.sz);
  return node;
}

function fileHref(path, name) {
  if (name.toLowerCase().endsWith(".md")) return `/view${path}${encodeURIComponent(name)}`;
  return `/browse${path}${encodeURIComponent(name)}?v`;
}

function renderCrumbs() {
  crumbsEl.textContent = "";
  crumbsEl.append(crumbLink("/", "root"));
  let current = "/";
  for (const part of state.path.split("/").filter(Boolean)) {
    crumbsEl.append(document.createTextNode("/"));
    current += `${part}/`;
    crumbsEl.append(crumbLink(current, part));
  }
}

function crumbLink(path, label) {
  const a = document.createElement("a");
  a.href = `/manage?path=${encodeURIComponent(path)}`;
  a.textContent = label;
  return a;
}

function normalizePath(path) {
  const clean = decodeURIComponent(path || "/").replace(/^\/+/, "").replace(/\/+$/, "");
  return clean ? `/${clean}/` : "/";
}

function setMessage(value, isError = false) {
  messageEl.textContent = value;
  messageEl.classList.toggle("error", isError);
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
