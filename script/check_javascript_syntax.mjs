import { spawnSync } from "node:child_process"
import { existsSync, readFileSync } from "node:fs"
import path from "node:path"
import { fileURLToPath } from "node:url"

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..")
const copiedController = "app/javascript/controllers/rails_table_preferences_controller.js"

function normalizePackageTarget(target) {
  return target.replace(/^\.\//, "")
}

function collectExportTargets(value, targets = new Set()) {
  if (typeof value === "string") {
    const target = normalizePackageTarget(value)
    if (target.endsWith(".js")) targets.add(target)
    return targets
  }

  if (value && typeof value === "object" && !Array.isArray(value)) {
    Object.values(value).forEach((nestedValue) => collectExportTargets(nestedValue, targets))
  }

  return targets
}

const packageJson = JSON.parse(readFileSync(path.join(repoRoot, "package.json"), "utf8"))
const syntaxTargets = [copiedController, ...collectExportTargets(packageJson.exports)].sort()

syntaxTargets.forEach((target) => {
  const absoluteTarget = path.join(repoRoot, target)
  if (!existsSync(absoluteTarget)) {
    throw new Error(`JavaScript syntax target is missing: ${target}`)
  }

  const result = spawnSync(process.execPath, ["--check", absoluteTarget], {
    cwd: repoRoot,
    encoding: "utf8"
  })

  if (result.status !== 0) {
    process.stdout.write(result.stdout || "")
    process.stderr.write(result.stderr || "")
    throw new Error(`JavaScript syntax check failed: ${target}`)
  }

  console.log(`JavaScript syntax ok: ${target}`)
})
