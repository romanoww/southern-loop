# The Southern Loop — trip planner

Interactive itinerary for the 2027 Singapore → New Zealand → Australia → Japan trip.
A single self-contained HTML file plus one small data file. No build step, no server, no dependencies.

---

## Repository contents

| File | Purpose |
|---|---|
| `index.html` | The whole application — map library, trip data, photos and all logic are inlined |
| `picks.json` | Your shortlist and bookings. The **only** file that changes as you plan |
| `README.md` | This file |

---

## One-time setup

1. Create the repo and upload `index.html` and `picks.json` to the root.
2. **Settings → Pages → Source:** `Deploy from a branch`, branch `main`, folder `/ (root)`.
3. Wait about a minute. The site appears at `https://<username>.github.io/<repo>/`.

### Enabling "Save to GitHub" (optional but recommended)

Without this you can still use **Export** and commit the file by hand. With it, saving is one tap.

1. GitHub → **Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token**
2. Configure it as narrowly as possible:
   - **Repository access:** Only select repositories → this repo alone
   - **Permissions → Repository permissions → Contents:** `Read and write`
   - Leave every other permission at `No access`
   - **Expiration:** set a date past the end of the trip (e.g. Aug 2027)
3. Open the site → **Bookings** tab → **Set up GitHub** and fill in:
   - Owner: your GitHub username
   - Repository: this repo's name
   - Branch: `main`
   - Token: the `github_pat_…` string

The token is stored **only in that browser's local storage**. It is never written into
`index.html`, never committed, and never sent anywhere except `api.github.com`.
Setting it up again on a second device just means pasting it again.

---

## Two modes: viewer and planner

The same `index.html` serves both. There is no second file to keep in sync.

**Viewer** — what everyone else gets. The full itinerary, maps, temperatures,
campsites, activities and every Google Maps link, plus your shortlist shown as
read-only ★ and ✓ badges. No edit buttons, no save bar. Nothing they do can
affect the repo.

**Planner** — what you get. Edit buttons, the save bar and GitHub sync appear.

It switches automatically once a GitHub token is configured on that device. To
unlock it on a fresh device *before* pasting the token, either:

- open the site with `?edit=1` appended to the URL, or
- **tap the page title three times** — handy on a phone.

`?edit=0` (or tapping the title three times again) returns to viewer mode.

This is a presentation choice, not a security boundary — the real protection is
that writing to the repo requires the token, which only ever lives in your
browser. A viewer who forces planner mode can shuffle badges in their own
browser and change nothing else.

---

## Updating picks — the daily workflow

Every campsite, activity and flight has a button that cycles through three states:

| Button | State | Meaning |
|---|---|---|
| **＋** | *unset* | Not considered yet |
| **★** | *shortlisted* | The one you're leaning towards for this stop |
| **✓** | *booked* | Reserved and paid — it's locked in |

Tapping cycles forward: `＋ → ★ → ✓ → ＋`. Tapping a third time clears it, which is
how you undo a mistake.

### Shortlisting a campsite or activity

1. Open the leg tab (**Singapore**, **New Zealand**, **Australia** or **Japan**).
2. Tap the stop you're planning — the map flies to it.
3. Expand **"Where to stay & what to do"** on that card.
4. Tap **＋** beside the option you want → it turns **★** and the name goes amber.

Shortlist freely. Several options per stop is fine and useful — it's a comparison list,
not a commitment.

### Confirming a booking

Once you've actually reserved something:

1. Find the same entry (or use the **Bookings** tab, which lists everything shortlisted).
2. Tap **★** once more → it becomes **✓** and turns green.

Only mark **✓** when the reservation genuinely exists. The point of the distinction is that
`★` means "still deciding" and `✓` means "do not rebook this" — if they blur together the
list stops being useful in the last weeks before departure.

### Flights

Same mechanism, on the **Flights** tab. The two Singapore Airlines flights have real
schedules; the other four are marked `TBC` until booked. Mark each **✓** as you confirm it.

---

## Saving your changes

> These steps apply in **planner mode**. In viewer mode the buttons are not shown.

Picks are written to your browser immediately, so nothing is lost if you close the tab.
To make them visible on **other devices**, they have to reach the repo.

A bar appears at the bottom of the screen whenever there are unsaved changes:

```
3 picks · unsaved        [ ⬇ Export ]  [ Save to GitHub ]
```

### Option A — Save to GitHub (one tap)

Press **Save to GitHub**. It commits `picks.json` directly. The bar changes to `saved`.
Allow about a minute for GitHub Pages to rebuild before the new state appears elsewhere.

### Option B — Export and commit manually

Press **⬇ Export** → `picks.json` downloads → upload it to the repo root, replacing the
existing file. Same result, no token needed.

### Importing

**Bookings → ⬆ Import** loads a `picks.json` from disk. Useful for moving state to a new
device or rolling back to an earlier version pulled from the commit history.

---

## How syncing behaves

- On load, the app fetches `picks.json` and compares its `updated` timestamp with the
  local copy. **The newer one wins.**
- Local edits always take precedence over a stale remote file, so pressing a button
  offline is never lost — it syncs next time you save.
- **You are the only writer.** Your wife's phone loads the site and sees your shortlist
  read-only; she needs no token and no setup. This is the intended arrangement — two
  people saving would risk one overwriting the other.

---

## Notes and limits

- **Public repo means public `picks.json`.** Campsite names and activities are harmless,
  but don't put booking references, passport numbers or payment details in there.
- **Photos and map tiles need a connection.** The itinerary text, temperatures, campsites,
  activities and all Google Maps links work without one; the map background will not.
- **Editing `picks.json` by hand** is fine — it's plain JSON, keyed
  `leg|stop|kind|item` with a value of `pick` or `booked`. Bump `updated` to the current
  epoch milliseconds so the app treats your edit as newer than its local copy.
- **Temperatures are 5-year averages (2022–2026)**, not forecasts. Drive times are
  routed distances with a speed model, validated to about 7% against known real
  durations — accurate enough for planning, but check live times before a long day.
- **Nothing here is a booking.** Availability, prices, seasonal closures and track
  conditions all change. Verify before relying on any of it — particularly the ballot
  sites (Milford Sound Lodge, Totaranui, Wilsons Prom Tidal River) and anything marked
  with a red booking flag.
