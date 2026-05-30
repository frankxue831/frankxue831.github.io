# Self-hosted fonts

These fonts are served from this origin so the site has **no third-party
(Google Fonts) runtime dependency** — visitors never contact `fonts.googleapis.com`
or `fonts.gstatic.com`. See the `@font-face` block at the top of
`assets/css/style.css` and the `<link rel="preload">` hints in `_includes/head.html`.

## What is hosted

Only the **Latin** faces are self-hosted — they are small and cover the
dominant typography (display + technical labels):

| Family | Styles / weights | Files |
|--------|------------------|-------|
| EB Garamond (display: site mark, hero title, headings) | roman + italic, variable `wght 400–800` | `eb-garamond-latin.woff2`, `eb-garamond-latin-ext.woff2`, `eb-garamond-italic-latin.woff2`, `eb-garamond-italic-latin-ext.woff2` |
| IBM Plex Mono (technical labels, metadata) | 400 / 500 / 600 | `ibm-plex-mono-{400,500,600}-{latin,latin-ext}.woff2` |

Each face has a `latin` and a `latin-ext` slice; `unicode-range` means the
`latin-ext` file is fetched **only** when an extended-Latin glyph actually
appears, so typical EN/ZH pages download just the `latin` slices.

**CJK is intentionally not hosted.** Chinese text is rendered by the reader's
**system** fonts via the fallback chains in `--sans` / `--serif`
(PingFang SC / Songti SC on Apple, Microsoft YaHei / SimSun on Windows). Bundling
Noto SC would add multiple megabytes for little gain, so it was dropped.

Body copy uses the system sans stack and needs no web font at all.

## Licensing

Both families are under the **SIL Open Font License 1.1** (freely
redistributable when self-hosted). License text:

- `OFL-EBGaramond.txt` — EB Garamond
- `OFL-IBMPlexMono.txt` — IBM Plex Mono

## Provenance / how to reproduce

The `.woff2` files are Google's already-optimized Latin subsets. To refresh them,
request the canonical CSS2 with a modern desktop-Chrome `User-Agent` (so Google
returns `woff2` + variable URLs) for **only** the two Latin families:

```
curl -s -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36" \
  "https://fonts.googleapis.com/css2?family=EB+Garamond:ital,wght@0,400..800;1,400..800&family=IBM+Plex+Mono:wght@400;500;600&display=swap"
```

From that response, keep the `@font-face` blocks whose preceding comment is
`/* latin */` or `/* latin-ext */` (drop cyrillic / greek / vietnamese), then
`curl` each `https://fonts.gstatic.com/...woff2` URL into this directory under
the descriptive names above. The `unicode-range` values copied into
`style.css` are taken verbatim from those same blocks.

If the upstream font version changes (the URL path contains a version segment,
e.g. `ebgaramond/v32`), the `@font-face` `unicode-range` values should be
re-copied from the fresh CSS2 response to stay in sync.
