// Output in 'smmarkets_pantry_full.csv' (Name, Net weight, Price)

const fs = require("fs");
const path = require("path");
const { chromium } = require("playwright");

const START_URL = "https://smmarkets.ph/pantry.html";
const OUT_CSV = path.resolve("smmarkets_pantry_full.csv");

// Weight like 198g, 1 kg, 360 ml, 1.5 L, 6 pcs, 8 g x 12, 12 x 8 g
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
    for (const sel of LOAD_MORE_SEL) {
      const btn = await page.$(sel);
      if (btn) {
        try {
          await btn.click({ timeout: 1500 });
          await page.waitForTimeout(1500);
        } catch {}
      }
    }


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
    if (newHeight <= lastHeight) {
      stableCycles++;
    } else {
      stableCycles = 0;
      lastHeight = newHeight;
    }
  }

  await page.evaluate(() => window.scrollTo(0, 0));
}

(async () => {
  console.log("Opening pantry page…");
  const browser = await chromium.launch({ headless: false, channel: "chrome" });
  const page = await browser.newPage({ viewport: { width: 1366, height: 900 } });

  await page.goto(START_URL, { waitUntil: "domcontentloaded", timeout: 60000 });
  await page.waitForLoadState("networkidle").catch(() => {});

  for (const text of ["Accept", "I Agree", "Got it"]) {
    try { await page.getByText(text, { exact: false }).click({ timeout: 1200 }); } catch {}
  }

  await autoScrollToEnd(page);

  const rows = await page.evaluate((WEIGHT_RE_SOURCE) => {
    const WEIGHT_RE = new RegExp(WEIGHT_RE_SOURCE, "i");

    const visibleText = (el) => {
      if (!el) return "";
      const s = window.getComputedStyle(el);
      if (!s || s.display === "none" || s.visibility === "hidden") return "";
      return (el.innerText || el.textContent || "").trim();
    };

    const findContainerWithPrice = (node, hops = 6) => {
      let cur = node;
      for (let i = 0; i < hops && cur && cur !== document.body; i++) {
        const txt = visibleText(cur);
        if (txt && /₱\s*\d/.test(txt)) return cur;
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
      if (!name) continue;
      if (!WEIGHT_RE.test(name)) continue; 

      const container = findContainerWithPrice(a);
      const price = findPrice(container);

      const cleanName = name.replace(/\s+/g, " ").trim();

      const key = `${cleanName}|${price ?? ""}`;
      if (seen.has(key)) continue;
      seen.add(key);

      out.push({ name: cleanName, price });
    }

    return out;
  }, WEIGHT_RE.source);

  const finalized = rows.map((r) => ({
    name: r.name,
    netWeight: extractNetWeightNumber(r.name),
    price: r.price,
  })).filter((r) => r.name && r.netWeight && (r.price ?? null) !== null);

  console.log(`Items extracted: ${finalized.length}`);

  fs.writeFileSync(OUT_CSV, "Name,Net weight,Price\n");
  const out = fs.createWriteStream(OUT_CSV, { flags: "a" });
  for (const r of finalized) {
    out.write(`${csvEscape(r.name)},${csvEscape(r.netWeight)},${r.price}\n`);
  }
  out.end();

  console.log("Done. Wrote:", finalized.length, "rows to", OUT_CSV);
  await browser.close();
})();
