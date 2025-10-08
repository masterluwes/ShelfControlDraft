// scrape_5categories_csv.js
// Collects Name, Net weight, and Price from 5 categories on SM Markets.
// Categories: Snacks, Bakery, Chilled, Dairy items, Beverage
// Output: individual CSVs + one combined sm_5cats_all.csv

const fs = require("fs");
const path = require("path");
const { chromium } = require("playwright");

const CATEGORIES = [
  { name: "Snacks", url: "https://smmarkets.ph/snacks.html" },
  { name: "Bakery", url: "https://smmarkets.ph/bakery.html" },
  { name: "Chilled", url: "https://smmarkets.ph/chilled-dairy-items.html" },
  { name: "Beverage", url: "https://smmarkets.ph/beverage.html" }
];

const OUT_COMBINED = path.resolve("sm_5cats_all.csv");
const SCREEN_DIR = path.resolve("screenshots");
if (!fs.existsSync(SCREEN_DIR)) fs.mkdirSync(SCREEN_DIR, { recursive: true });

const WEIGHT_RE =
  /\b(\d+(?:\.\d+)?)\s?(g|kg|ml|l|L|pcs)\b|\b(\d+)\s?x\s?(\d+)\s?(g|ml|L|l|pcs)\b/i;

function csvEscape(v = "") {
  return `"${String(v).replace(/"/g, '""').replace(/\r?\n/g, " ").trim()}"`;
}
function extractNetWeightNumber(name) {
  if (!name) return null;
  const m = name.match(WEIGHT_RE);
  if (!m) return null;
  if (m[1]) return m[1];
  if (m[3]) return m[3];
  return null;
}

async function autoScrollToEnd(page) {
  const LOAD_MORE_SEL = [
    "text=Load more",
    "text=Show more",
    "text=View more",
    "text=More products",
    "text=Load More Products",
  ];
  let lastHeight = 0;
  let stableCycles = 0;

  while (stableCycles < 4) {
    // click visible "load more" buttons
    for (const sel of LOAD_MORE_SEL) {
      const btn = await page.$(sel);
      if (btn) {
        try {
          await btn.click({ timeout: 1500 });
          await page.waitForTimeout(1500);
        } catch {}
      }
    }

    // scroll down multiple times
    await page.evaluate(async () => {
      const delay = (ms) => new Promise((r) => setTimeout(r, ms));
      for (let i = 0; i < 15; i++) {
        window.scrollBy(0, 1500);
        await delay(120);
      }
    });

    await page.waitForLoadState("networkidle").catch(() => {});
    await page.waitForTimeout(800);

    const newHeight = await page.evaluate(() => document.body.scrollHeight);
    if (newHeight <= lastHeight) stableCycles++;
    else {
      stableCycles = 0;
      lastHeight = newHeight;
    }
  }

  await page.evaluate(() => window.scrollTo(0, 0));
}

async function extractVisibleItems(page) {
  const WEIGHT_RE_SRC = WEIGHT_RE.source;
  const rows = await page.evaluate((WEIGHT_RE_SRC) => {
    const WEIGHT_RE = new RegExp(WEIGHT_RE_SRC, "i");
    const visibleText = (el) => {
      if (!el) return "";
      const s = window.getComputedStyle(el);
      if (!s || s.display === "none" || s.visibility === "hidden") return "";
      return (el.innerText || el.textContent || "").trim();
    };
    const findContainer = (node, hops = 6) => {
      let cur = node;
      for (let i = 0; i < hops && cur && cur !== document.body; i++) {
        const t = visibleText(cur);
        if (t && /₱\s*\d/.test(t)) return cur;
        cur = cur.parentElement;
      }
      return node.parentElement || node;
    };
    const findPrice = (container) => {
      if (!container) return null;
      const withAttr = container.querySelector("[data-price-amount]");
      if (withAttr) {
        const v = parseFloat(withAttr.getAttribute("data-price-amount"));
        if (Number.isFinite(v)) return v;
      }
      const walker = document.createTreeWalker(container, NodeFilter.SHOW_ELEMENT, null);
      let n;
      while ((n = walker.nextNode())) {
        const t = visibleText(n);
        if (t && /₱\s*\d/.test(t)) {
          const val = parseFloat(t.replace(/[^\d.]/g, ""));
          if (Number.isFinite(val)) return val;
        }
      }
      const txt = visibleText(container);
      const m = txt.match(/₱\s*\d[\d,.]*/);
      return m ? parseFloat(m[0].replace(/[^\d.]/g, "")) : null;
    };

    const anchors = Array.from(document.querySelectorAll("a"));
    const seen = new Set();
    const out = [];

    for (const a of anchors) {
      const name = visibleText(a);
      if (!name || !WEIGHT_RE.test(name)) continue;
      const container = findContainer(a);
      const price = findPrice(container);
      const cleanName = name.replace(/\s+/g, " ").trim();
      const key = `${cleanName}|${price ?? ""}`;
      if (seen.has(key)) continue;
      seen.add(key);
      out.push({ name: cleanName, price });
    }
    return out;
  }, WEIGHT_RE_SRC);

  // compute numeric net weight
  return rows.map((r) => ({
    name: r.name,
    netWeight: extractNetWeightNumber(r.name),
    price: r.price,
  })).filter((r) => r.name && r.netWeight && (r.price ?? null) !== null);
}

async function scrapeCategory(category, page) {
  console.log(`\n[${category.name}] Opening ${category.url}`);
  await page.goto(category.url, { waitUntil: "domcontentloaded", timeout: 60000 });
  await page.waitForLoadState("networkidle").catch(() => {});
  for (const txt of ["Accept", "I Agree", "Got it"]) {
    try { await page.getByText(txt, { exact: false }).click({ timeout: 1200 }); } catch {}
  }
  await autoScrollToEnd(page);
  const items = await extractVisibleItems(page);
  console.log(`[${category.name}] Extracted ${items.length} items`);
  return items.map((r) => ({ ...r, category: category.name }));
}

(async () => {
  console.log("Launching Chrome...");
  const browser = await chromium.launch({ headless: false, channel: "chrome" });
  const page = await browser.newPage({ viewport: { width: 1366, height: 900 } });

  fs.writeFileSync(OUT_COMBINED, "Category,Name,Net weight,Price\n");
  const combinedOut = fs.createWriteStream(OUT_COMBINED, { flags: "a" });

  let allItems = [];

  for (const cat of CATEGORIES) {
    const data = await scrapeCategory(cat, page);
    allItems = allItems.concat(data);
    const file = path.resolve(`${cat.name.toLowerCase().replace(/\s+/g, "_")}.csv`);
    fs.writeFileSync(file, "Category,Name,Net weight,Price\n");
    const out = fs.createWriteStream(file, { flags: "a" });
    for (const r of data) {
      out.write(`${csvEscape(cat.name)},${csvEscape(r.name)},${csvEscape(r.netWeight)},${r.price}\n`);
      combinedOut.write(`${csvEscape(cat.name)},${csvEscape(r.name)},${csvEscape(r.netWeight)},${r.price}\n`);
    }
    out.end();
    console.log(`[${cat.name}] Saved to ${file}`);
  }

  // make a dairy-only subset from Chilled
  const dairyKeywords = /milk|cheese|butter|cream|yogurt|margarine/i;
  const chilled = allItems.filter((i) => i.category === "Chilled");
  const dairySubset = chilled.filter((i) => dairyKeywords.test(i.name));
  if (dairySubset.length) {
    const file = path.resolve("dairy_items.csv");
    fs.writeFileSync(file, "Category,Name,Net weight,Price\n");
    const out = fs.createWriteStream(file, { flags: "a" });
    for (const r of dairySubset) {
      out.write(`${csvEscape("Dairy items")},${csvEscape(r.name)},${csvEscape(r.netWeight)},${r.price}\n`);
    }
    out.end();
    console.log(`[Dairy items] Filtered ${dairySubset.length} dairy products -> dairy_items.csv`);
  }

  combinedOut.end();
  await browser.close();
  console.log("\nAll done. Wrote combined CSV and 5 category CSVs.");
})();
