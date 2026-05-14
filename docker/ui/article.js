const articleEl = document.querySelector("#article");
const pathLabelEl = document.querySelector("#path-label");
const rawLinkEl = document.querySelector("#raw-link");
const manageLinkEl = document.querySelector("#manage-link");
const backLinkEl = document.querySelector("#back-link");

const filePath = getFilePath();
const folderPath = `/${filePath.split("/").slice(0, -1).join("/")}/`.replace("//", "/");
const rawUrl = `/${encodePath(filePath)}`;

pathLabelEl.textContent = `/${filePath}`;
rawLinkEl.href = rawUrl;
manageLinkEl.href = `/party/${encodePath(filePath)}?v`;
backLinkEl.href = `/#${encodeURIComponent(folderPath)}`;

renderArticle();

function getFilePath() {
  const path = decodeURIComponent(location.pathname);
  if (path.startsWith("/browse/")) return path.slice("/browse/".length);
  if (path.startsWith("/view/")) return path.slice("/view/".length);
  return path.replace(/^\/+/, "");
}

async function renderArticle() {
  try {
    const res = await fetch(rawUrl, { cache: "no-store" });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);

    const markdown = await res.text();
    articleEl.innerHTML = markdownToHtml(markdown);
    document.title = `${articleTitle(markdown)} - Agent Share Box`;
  } catch (error) {
    articleEl.innerHTML = `<p class="error">Could not load article. ${escapeHtml(error.message)}</p>`;
  }
}

function markdownToHtml(markdown) {
  const lines = markdown.replace(/\r\n?/g, "\n").split("\n");
  const out = [];
  let paragraph = [];
  let listType = "";
  let inCode = false;
  let codeLines = [];

  const flushParagraph = () => {
    if (!paragraph.length) return;
    out.push(`<p>${inline(paragraph.join(" "))}</p>`);
    paragraph = [];
  };

  const flushList = () => {
    if (!listType) return;
    out.push(`</${listType}>`);
    listType = "";
  };

  const flushCode = () => {
    out.push(`<pre><code>${escapeHtml(codeLines.join("\n"))}</code></pre>`);
    codeLines = [];
  };

  for (const line of lines) {
    if (line.startsWith("```")) {
      if (inCode) {
        flushCode();
        inCode = false;
      } else {
        flushParagraph();
        flushList();
        inCode = true;
      }
      continue;
    }

    if (inCode) {
      codeLines.push(line);
      continue;
    }

    if (!line.trim()) {
      flushParagraph();
      flushList();
      continue;
    }

    const heading = /^(#{1,3})\s+(.+)$/.exec(line);
    if (heading) {
      flushParagraph();
      flushList();
      const level = heading[1].length;
      out.push(`<h${level}>${inline(heading[2])}</h${level}>`);
      continue;
    }

    const quote = /^>\s?(.+)$/.exec(line);
    if (quote) {
      flushParagraph();
      flushList();
      out.push(`<blockquote>${inline(quote[1])}</blockquote>`);
      continue;
    }

    const unordered = /^[-*]\s+(.+)$/.exec(line);
    const ordered = /^\d+\.\s+(.+)$/.exec(line);
    if (unordered || ordered) {
      flushParagraph();
      const nextType = unordered ? "ul" : "ol";
      if (listType && listType !== nextType) flushList();
      if (!listType) {
        listType = nextType;
        out.push(`<${listType}>`);
      }
      out.push(`<li>${inline((unordered || ordered)[1])}</li>`);
      continue;
    }

    paragraph.push(line.trim());
  }

  if (inCode) flushCode();
  flushParagraph();
  flushList();

  return out.join("\n") || "<p class=\"loading\">This Markdown file is empty.</p>";
}

function inline(value) {
  return escapeHtml(value)
    .replace(/!\[([^\]]*)\]\(([^)]+)\)/g, (_match, alt, href) => (
      `<img src="${assetUrl(href)}" alt="${escapeHtml(alt)}">`
    ))
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, (_match, label, href) => (
      `<a href="${assetUrl(href)}">${label}</a>`
    ))
    .replace(/`([^`]+)`/g, "<code>$1</code>")
    .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
    .replace(/\*([^*]+)\*/g, "<em>$1</em>");
}

function assetUrl(href) {
  if (/^(https?:|data:|#|\/)/i.test(href)) return escapeHtml(href);

  const base = filePath.split("/").slice(0, -1);
  const parts = href.split("/");
  for (const part of parts) {
    if (!part || part === ".") continue;
    if (part === "..") base.pop();
    else base.push(part);
  }

  return `/${base.map(encodeURIComponent).join("/")}`;
}

function articleTitle(markdown) {
  const heading = markdown.match(/^#\s+(.+)$/m);
  return heading ? heading[1].trim() : filePath.split("/").pop();
}

function encodePath(path) {
  return path.split("/").map(encodeURIComponent).join("/");
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
