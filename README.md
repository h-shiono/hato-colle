# ハトコレ 🕊️

> *A GNSS-tagged pigeon collection by hato.gnss*

私の出会った鳩(と、たまにそれ以外の鳥)を、撮影時の **測位機材** と **精度** とともに記録するコレクションです。

🔗 **Live**: https://h-shiono.github.io/hato-colle/

---

## What this is

野鳥写真と GNSS の精度を紐づけた (実験的) コレクション。
今はスマートフォンのジオタグのみですが、将来的にもっと高精度なジオタグをつけられないか？
撮影時の測位方式の変遷を残していくことで、ハトコレ自体が個人の測位機材史になっていく ── そうなったら面白いなと思っています。

カテゴリは2つ:
- **ハト目 (Columbiformes)** — 本編
- **番外編 (Off-topic)** — 他の鳥だって好きです。

---

## Folder structure

```
hato-colle/
├── index.html          # The app (single-file static)
├── entries.json        # Data: list of entries (source of truth)
├── photos/             # Photos referenced from entries.json
│   └── 001.jpg, 002.jpg, ...
├── scripts/
│   └── strip-exif.sh   # Strip GPS metadata before commit
├── .github/workflows/
│   └── check-exif.yml  # CI: block PRs containing photos with GPS
├── README.md
└── .gitignore
```

---

## Local preview

The app uses `fetch('./entries.json')`, so it needs a local HTTP server (not `file://`).

```bash
# Python
python3 -m http.server 8000

# Or Node
npx serve .
```

Open http://localhost:8000.

---

## Adding a new entry

1. **Take a photo** with whatever device you have. Pixel for casual, mosaic-G5 + MRTKLIB for serious.

2. **Resize & strip GPS:**
   ```bash
   # Resize to max 1600px wide, JPEG quality 85
   mogrify -resize '1600x1600>' -quality 85 your-photo.jpg

   # Strip GPS EXIF (camera/lens/exposure data is preserved)
   ./scripts/strip-exif.sh your-photo.jpg
   ```

3. **Save it as the next available number:**
   ```bash
   mv your-photo.jpg photos/007.jpg
   ```

4. **Add an entry to `entries.json`:**
   ```jsonc
   {
     "no": 7,
     "name": "...",
     "species": "Columba livia",        // Latin name
     "category": "hato",                 // "hato" or "other"
     "date": "2026-MM-DD",
     "lat": 35.xxxx,                     // round to your preferred precision
     "lon": 139.xxxx,
     "device": "Google Pixel 8",
     "positioning": "SPP",               // SPP / DGNSS / RTK Float / RTK Fix / CLAS / PPP
     "photo": "photos/007.jpg",
     "usedAs": [],                       // optional: ["github", "zenn", "x"]
     "notes": "..."
   }
   ```

5. **Commit and push.** GitHub Pages picks it up automatically.

> **Note**: If the `species` Latin name is new (not seen before in this collection), add it to the `SPECIES` lookup table in `index.html` so the Japanese name displays. The console will log a warning if a Latin name isn't found.
>
> ```js
> const SPECIES = {
>   'Streptopelia decaocto': { jp: 'シラコバト', en: 'Eurasian Collared-Dove' },
>   // ... add new species here
> };
> ```

---

## EXIF policy

Photos in this repo have **GPS coordinates stripped** from EXIF. Reasons:

- Location is curated in `entries.json` where we choose the precision (you may want to round, e.g., to a public landmark instead of leaking the exact home spot).
- Avoids double-source-of-truth between EXIF and JSON.
- Removes accidental privacy leaks.

**Camera / lens / exposure metadata is kept on purpose** — those are part of the field-log aesthetic and don't reveal location.

Tooling:
- Local: `./scripts/strip-exif.sh photos/*.jpg`
- CI: `.github/workflows/check-exif.yml` blocks PRs that contain photos with GPS tags.

Requires [exiftool](https://exiftool.org/):
```bash
brew install exiftool                       # macOS
sudo apt install libimage-exiftool-perl     # Debian / Ubuntu / Pi
```

---

## Positioning methods reference

| Method     | Typical accuracy | Notes                                  |
| ---------- | ---------------- | -------------------------------------- |
| SPP        | ~5 m             | Single-point GPS (Pixel default)       |
| DGNSS      | ~1 m             | Code-based differential                |
| RTK Float  | ~30 cm           | Carrier-phase, ambiguities float        |
| RTK Fix    | ~1 cm            | Carrier-phase, ambiguities fixed        |
| CLAS       | ~10 cm           | QZSS PPP-RTK via L6                     |
| PPP        | ~10 cm (after convergence) | MADOCA / Galileo HAS etc.    |

---

## Deploying to GitHub Pages

This repo uses **GitHub Actions** to deploy to Pages (workflow: `.github/workflows/deploy.yml`). Steps to enable it on a fresh repo:

1. Push to `main`.
2. Repo → **Settings** → **Pages**.
3. Under **Build and deployment** → **Source**, choose **GitHub Actions**.
4. The first push to `main` (or a manual run via Actions → "Deploy to GitHub Pages" → Run workflow) deploys the site.

The URL appears at the top of the Pages settings once the deploy succeeds. Subsequent pushes to `main` redeploy automatically.

### What the workflow does

- Runs `python3 -c "json.load(open('entries.json'))"` to verify the data file is valid JSON before deploying (catches typos in PRs that touch entries).
- Uploads the entire repo root as the Pages artifact (the site is a single-file static app, so no build step needed yet).
- Calls the official `actions/deploy-pages@v4` to publish.

### Related workflows

- `.github/workflows/check-exif.yml` runs on PRs that touch `photos/**` and fails the check if any photo still contains GPS metadata. This catches accidental leaks **before** they hit `main`.

### Going to a custom domain (optional)

If you want `hato-colle.hatognss.com` or similar instead of `hatognss.github.io/hato-colle`, add a `CNAME` file at the repo root containing the bare domain, and configure DNS per [GitHub's docs](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site).

---

## License

TBD. Plan:
- Code (HTML/CSS/JS, scripts, workflows): MIT
- Photos: All rights reserved unless otherwise marked
- Entries text (notes, names): CC BY-NC 4.0

---

*hato.gnss · [github.com/h-shiono](https://github.com/h-shiono)*
