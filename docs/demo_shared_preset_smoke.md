# Shared preset browser smoke coverage

The demo browser smoke suite includes a focused shared preset regression check for the read-only fallback path.

Covered behavior:

- the preset selector can load a shared preset label such as `共有ビュー [shared]`
- shared presets render the editor as read-only for destructive actions
- delete is disabled for a non-editable shared preset
- save remains available as an owner-scoped fallback instead of patching the shared preset
- edited column visibility is posted to the collection fallback payload

This document intentionally describes the automated smoke coverage only. It does not change the runtime preset contract, UI wording, authorization model, or shared preset lifecycle.
