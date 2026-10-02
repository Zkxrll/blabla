# Perseus `KeySystem.lua`: deobfuscation findings

Source analysed: `https://raw.githubusercontent.com/laeraz/Perseus/refs/heads/main/General/Library/KeySystem.lua`
(275,481 bytes, one line, obfuscated with the WeAreDevs obfuscator v1.0.0)

Readable result: [`KeySystem.deobfuscated.lua`](KeySystem.deobfuscated.lua)

## What the script is

A Roblox executor script that shows a "Perseus Key System" window and gates a script hub behind a
[Luarmor](https://luarmor.net) key check. In order:

1. Pulls in a UI/notification library (`Severitysvc/Overlay-Library`) and the Luarmor SDK, both with `loadstring(game:HttpGet(...))`.
2. Builds a 74-instance draggable window: guide text, key box, **Check Key**, **Get Key**, a Discord button, a changelog panel, close and minimise buttons.
3. Kicks the player in unsupported games (`game.GameId` must be in a 2-entry table).
4. Restores a saved key from `Perseus/Key.json`, checks it with Luarmor and loads the protected script if it is valid.
5. Otherwise waits for the user to type a key and press **Check Key**.

The key itself is validated by Luarmor's server (`check_key`). This file contains no key, secret or local validation logic.

## Everything it touches outside itself (security-relevant)

| Kind | What | When |
|---|---|---|
| Remote code | `https://raw.githubusercontent.com/Severitysvc/Overlay-Library/refs/heads/main/Library.lua` (`loadstring`) | startup |
| Remote code | `https://sdkapi-public.luarmor.net/library.lua` (`loadstring`), then `script_id` + `script_key` are set and `check_key()` / `load_script()` are called. `load_script()` pulls and runs the real protected payload, which is not part of this file | startup (saved key) / Check Key |
| Local HTTP | `POST http://127.0.0.1:6463/rpc?v=1`, Discord's local RPC, body `{"cmd":"INVITE_BROWSER","nonce":<guid>,"args":{"code":"njZMktNrj6"}}`, `Origin: https://discord.com`. Uses the first available of `syn.request` → `http.request` → `request` | Get Key / Discord buttons |
| Clipboard | `setclipboard("https://discord.gg/b2hbaJHVfF")` (note: a different invite code than the RPC one) | Get Key / Discord buttons |
| Files | folder `Perseus/`, file `Perseus/Key.json` (read, write) | startup / valid key |
| Globals | `getgenv().script_key = <key>`, `shared.Keysystem = <window>`; reads `getgenv().gethui`, `getgenv().protectgui` | |
| Player | `LocalPlayer:Kick("Game not supported.")`, `LocalPlayer:Kick("The key is set to a different HWID")` | see below |

On every path I exercised there is **no webhook, token read, cookie/credential access, or other exfiltration**.
Caveat: that covers executed paths only (see "Limits"), and the two remote libraries plus the Luarmor payload are third-party
code that runs with full executor privileges.

## Facts recovered from the obfuscated data

* Supported games, keyed by `game.GameId` (the universe id, **not** `PlaceId`) and mapped to Luarmor script ids:
  * `6035872082` → `c9596bc6bffaa7ccef69026a5a0df47e` (consistent with the "Rivals Beta Release" changelog entry)
  * `7633926880` → `5ab97c014f9eeb177d62a504bf0a3ce1`
* Saved-key format (`Perseus/Key.json`): JSON array, `stored[i] = (byte(key, i) + 137 + i) % 256` (1-based `i`).
  The sentinel `"none"` encodes to `[248,250,250,242]`. Only the exact lowercase `"none"` and the empty key skip the startup check.
* Typed key is trimmed (`^%s*(.-)%s*$`). Empty or whitespace-only gives "Enter a key first!.".

### Luarmor result handling (branches on `status.code` only)

| `status.code` | Check Key button | Saved key at startup |
|---|---|---|
| `KEY_VALID` | destroy UI, "Key is correct, Loading the script...", save key, `load_script()` | destroy UI, "Loaded Saved Key.", `load_script()` |
| `KEY_HWID_LOCKED` | Kick "The key is set to a different HWID" | same Kick |
| `KEY_INCORRECT` | "Key is invalid!" | "Saved key is invalid or expired." **and** reset file to `"none"` |
| anything else (`KEY_INVALID`, `KEY_EXPIRED`, `KEY_BANNED`, ...) | "Key is invalid" | "Saved key is invalid or expired" (file kept) |

After either path the startup toast "Complete The KeySystems In Order To Unlock The Scripts." is still shown.

### UI behaviour

* GUI parent: Studio → `LocalPlayer.PlayerGui`; otherwise `gethui()` if present, else `CoreGui`. All instance names are blanked right after creation.
* Drag bar (mouse-1 or touch to start/end, mouse-move or touch to move, all guarded by a "dragging" flag): the window eases toward the cursor with `alpha = 1 - exp(-20·dt)` and `Position:Lerp(target, alpha)` on `Heartbeat`.
* Minimise button toggles collapse/expand of the two body panels (0.3 s Sine/Out tweens, waits of 0.31 s / 0.32 s). The window opens with a collapse → expand intro.
* Close button shows a confirm toast; "Unload Interface" calls `Library:DisconnectAllConnections()`, `DisconnectAllSignals()`, `DestroyAll()`.
* Hover tweens (0.25 s) on the buttons, key box and drag bar.

### Anti-tamper / anti-analysis in the original

* Runs ~30 probes that raise `error()` with synthetic `<chunk>:<line>: attempt to perform arithmetic on local 'W' (a string value)` messages and throws
  `error("Tamper Detected!")` if the outcome is off. **Wrapping `error` in a logging function trips it**, which is a practical anti-dumper trick (my first attempt hit it).
* ~40 reads of random-named nonexistent globals (`CDlElokdhPCuP`, `xO5rP6jmtiaCU`, ...) as noise.
* String table of 1,815 entries, 207 plain, the rest encrypted per use with large numeric keys. Control flow is flattened into one `while L do` state machine.

## Method

1. **Online tools first.** Several WeAreDevs deobfuscators exist (listed in the chat reply). They are dynamic dumpers that run the script under a Lua 5.1 mock, so I did not
   upload the 275 KB file to an unknown web tool, and I built a sandboxed equivalent instead, because this script actively detects naive environment loggers.
2. **Static:** extracted and decoded the string table without running the VM (`tools/dump_consts.py`, `evidence/decoded_plain_constants.txt`).
3. **Dynamic, sandboxed** (`tools/sandbox.lua`, driven by `tools/run_trace.py`): Lua 5.1 with a mock Roblox/executor API, **no** `os`/`io`/`debug`/`require`, `loadstring` re-wrapped into the
   sandbox, instruction budget, memory limit and a subprocess timeout. Every API call, property write, file op, HTTP/clipboard/kick and callback is logged.
   Callbacks are driven (button clicks, input, hover, Heartbeat) and `debug.getlocal`-based stack introspection (kept outside the sandbox) recovered the game table.
4. **Reconstruction:** hand-written logic plus a UI block generated from the trace (`tools/gen_ui.py`, `tools/template.lua`, `tools/build_final.py`).
5. **Verification:** `tools/difftest.py` runs the **original** and the **reconstruction** under 40 scenarios (every status code × manual/saved key, corrupt/empty/sentinel
   files, supported/unsupported/second game, GameId vs PlaceId, Studio/gethui, key trimming, drag/touch/right-click, minimise toggle, request fallbacks) and compares all external
   effects in order plus the final property state of all 74 instances: **40/40 identical.**

## Limits (read before relying on this)

* Everything was observed in a **mock**, never in real Roblox or against real Luarmor. The mocks were designed to be non-detectable but I can't prove no branch behaves differently on a real executor.
* Only paths a scenario reached were observed. Unexercised code (for example further anti-tamper conditions) could exist. The remaining ~1,600 encrypted constants were not statically decrypted.
* The two remote libraries and the Luarmor payload were deliberately **not** fetched or analysed.
* Reproduction quirk: `Expand()` tweens to `AbsoluteSize.Y` of a body frame that was just collapsed. I kept it literally; it looks like an upstream quirk, not a transcription error.
* `KeySystem.deobfuscated.lua` is behaviourally equivalent in the sandbox, not byte-for-byte the author's source (names, structure and comments are mine).

## Reproduce

```bash
pip install lupa            # provides Lua 5.1
cd deobfuscated/tools
cp ../KeySystem.deobfuscated.lua .
cp /path/to/original/KeySystem.lua .        # the original obfuscated file (not included here)
python3 dump_consts.py
python3 run_trace.py KeySystem.lua out.log 'CONFIG.lib_patterns={["Overlay-Library"]="Library",["luarmor.net/library.lua"]="Luarmor"} CONFIG.place_id=6035872082 CONFIG.luarmor_code="KEY_VALID"'
python3 difftest.py                         # original vs reconstruction, 40 scenarios
```
Do **not** wrap `error` in the sandbox (it trips the anti-tamper check).
