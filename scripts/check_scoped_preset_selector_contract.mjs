import fs from "node:fs"

const source = fs.readFileSync("app/javascript/rails_table_preferences/controller.js", "utf8")

const requiredSignals = [
  "renderPresetOptions()",
  "buildPresetOption(preset)",
  "async selectPreset(event)",
  "selectedOption?.dataset.presetName",
  "this.preferenceUrl(name, scope)",
  "params.set(\"scope_type\", scopeType)",
  "params.set(\"scope_key\", scopeKey)",
  "presetOptionValue({ name, scopeType = \"owner\", scopeKey = \"\" })",
  "get currentPresetOptionValue()"
]

const missingSignals = requiredSignals.filter((signal) => !source.includes(signal))

if (missingSignals.length > 0) {
  console.error("Scoped preset selector contract signals are missing:")
  missingSignals.forEach((signal) => console.error(`- ${signal}`))
  process.exit(1)
}

console.log("Scoped preset selector contract signals are present.")
