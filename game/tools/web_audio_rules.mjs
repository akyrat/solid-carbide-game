// The pass rule of web_audio_check.mjs (T-476), apart so a test can run it without a browser.
// Music must be logged and a Web Audio context must be running. The engine line is required
// only when the sound effects are on; with the board's switch off (sfx_enabled false in
// data/sfx.json, T-388) the engine never plays, and that is not a failure.
export function verdict(logText, states, sfxOn) {
  const music = /\[audio\] music playing=true/.test(logText);
  const engine = /\[audio\] engine playing=true/.test(logText);
  const running = states.includes("running");
  const ok = music && running && (!sfxOn || engine);
  const notes = [];
  if (!music) notes.push("no '[audio] music playing=true' line");
  if (!running) notes.push("no running audio context");
  if (sfxOn && !engine) notes.push("sfx_enabled is true but no '[audio] engine playing=true' line");
  if (!sfxOn) notes.push("SFX are off by the board's switch (sfx_enabled false in data/sfx.json, T-388): the engine line is not required");
  return { ok, notes };
}

// sfx_enabled from the text of data/sfx.json; missing or not a boolean counts as true (like the game).
export function sfxEnabledFrom(jsonText) {
  try { const v = JSON.parse(jsonText).sfx_enabled; return typeof v === "boolean" ? v : true; } catch { return true; }
}
