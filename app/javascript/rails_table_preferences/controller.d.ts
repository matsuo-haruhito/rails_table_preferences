import { Controller } from "@hotwired/stimulus"

export type RailsTablePreferencesLifecycleEvent = "applied" | "saved" | "loaded" | "deleted" | "error"
export type RailsTablePreferencesEventName = `rails-table-preferences:${RailsTablePreferencesLifecycleEvent}`

export type RailsTablePreferencesSuccessAction = "apply" | "reset" | "save" | "create" | "load" | "delete"
export type RailsTablePreferencesErrorAction = RailsTablePreferencesSuccessAction | "load-presets" | "operation"
export type RailsTablePreferencesLifecycleAction = RailsTablePreferencesSuccessAction | RailsTablePreferencesErrorAction

export interface RailsTablePreferencesSettingsSnapshot {
  columns?: Array<Record<string, unknown>>
  filters?: Record<string, unknown>
  sorts?: Array<Record<string, unknown>>
  [key: string]: unknown
}

export interface RailsTablePreferencesEventDetailBase {
  tableKey: string
  name: string
  settings: RailsTablePreferencesSettingsSnapshot
}

export type RailsTablePreferencesSuccessEventDetail = RailsTablePreferencesEventDetailBase & {
  action: RailsTablePreferencesSuccessAction
}

export type RailsTablePreferencesErrorEventDetail = RailsTablePreferencesEventDetailBase & {
  action: RailsTablePreferencesErrorAction
  message: string
}

export type RailsTablePreferencesEventDetail = RailsTablePreferencesSuccessEventDetail | RailsTablePreferencesErrorEventDetail

declare const RailsTablePreferencesController: typeof Controller
export default RailsTablePreferencesController
