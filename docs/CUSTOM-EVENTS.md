# Custom events: make your own event in two minutes

Only the **rewritten game** (the browser version at `/play/`) shows these. The phone app does not know them.

## How to add one

1. Open the folder where your server's save is (the one with `hellobro.db` and `START-SERVER.bat`).
2. Make a folder there named `custom-events` (once).
3. Copy `server\custom-events-examples\weekend-gift.json` into it and open the copy with Notepad.
4. Change the words and numbers, save. **Done: it is live at once, no restart.**

Players see a "Special" button on Home while at least one event is running. It has a red dot when there is something to take.

To stop an event: delete its file (or move it out of the folder).

## What the lines mean

```json
{
  "id": "weekend-gift",
  "title": "Weekend gift",
  "text": "Log in this weekend and take your gift.",
  "icon": "activity1",
  "from": "2026-11-21",
  "to": "2026-11-30",
  "repeat": "daily",
  "need": { "level": 5 },
  "give": { "gold": 20, "silver": 5000, "items": { "11": 1 } }
}
```

| Line | What it does |
|---|---|
| `id` | A short name with letters, digits, `-` or `_`. **Never change it after players claimed**: the game remembers "taken" by this name. Two files must not share one. |
| `title`, `text` | What players read. |
| `icon` | Optional picture. `activity1` to `activity44` are the game's event icons; an item's picture name works too. Leave it out for the default. |
| `from`, `to` | Optional first and last day, written `2026-11-30` (your server's clock). Leave both out and the event runs until you delete the file. |
| `repeat` | `"once"` = each player takes it one time. `"daily"` = once every day. Leave it out for once. |
| `need` | Optional: `"level": 10` and / or `"vip": 3` = who may take it. Others see it as Locked. |
| `give` | What they get. `gold`, `silver`, `items` (item number: how many) and `drop` (one of the game's gift packs, by its number). At least one. |
| `cost` | Optional. What it costs: `gold`, `silver`, `items`, written like `give`. With a cost the event is an **offer**: the button reads Buy and asks first. |
| `limit` | Optional. How many times each player may take it (per day when `repeat` is daily). 1 if left out. |

Item numbers and gift pack numbers: the wiki lists items; the control panel's item page shows the same numbers.

## An offer instead of a gift

Add a `cost` and the event becomes something players buy or trade for:

```json
{
  "id": "pill-deal",
  "title": "Pill deal",
  "text": "Three Reincarnation Pills for 100 gold. Twice a day.",
  "repeat": "daily",
  "limit": 2,
  "cost": { "gold": 100 },
  "give": { "items": { "11": 3 } }
}
```

## If it does not show

- The server writes one line in its log when a file is wrong, with the reason (for example `custom event x.json skipped: item 999 does not exist`).
- A comma too many or a missing `"` is the usual cause. Compare with the example.
- The event is outside its `from` / `to` days.

## Good to know

- Every server has its own folder: your play server, the dev server and the public server do not share events. An update never touches the folder.
- These gifts are real: they change the balance like any other free gift. Nothing is in the folder by default.
- For the public server the folder is `/opt/hellobro/custom-events` (owner `hellobro`).
