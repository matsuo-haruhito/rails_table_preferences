import { Controller } from "@hotwired/stimulus"

export type RailsTablePreferencesLifecycleEvent = "applied" | "saved" | "loaded" | "deleted" | "error"
export type RailsTablePreferencesEventName = `rails-table-preferences:${RailsTablePreferencesLifecycleEvent}`

export type RailsTablePreferencesSuccessAction = "apply" | "reset" | "save" | "create" | "load" | "delete"
export type RailsTablePreferencesErrorAction = RailsTablePreferencesSuccessAction | "load-presets" | "operation"
export type RailsTablePreferencesLifecycleAction = RailsTablePreferencesSuccessAction | RailsTablePreferencesErrorAction

export interface RailsTablePreferencesColumnGroupSnapshot {
  key?: string | number | null
  label?: string | null
  [key: string]: unknown
}

export interface RailsTablePreferencesFilterSnapshot {
  type?: string
  param?: string
  from_param?: string
  to_param?: string
  operator?: string
  value?: unknown
  values?: unknown[]
  options?: unknown[]
  [key: string]: unknown
}

export interface RailsTablePreferencesSortSnapshot {
  key: string
  direction?: string
  [key: string]: unknown
}

export interface RailsTablePreferencesColumnSnapshot {
  key: string
  export_key?: string
  label?: string
  visible?: boolean
  order?: number
  width?: number
  truncate?: number | boolean
  overflow?: string
  pinned?: boolean
  group?: string | RailsTablePreferencesColumnGroupSnapshot | null
  ignored?: boolean
  filter?: RailsTablePreferencesFilterSnapshot | null
  sortable?: boolean
  sort_param?: string
  [key: string]: unknown
}

export interface RailsTablePreferencesSettingsSnapshot {
  columns?: RailsTablePreferencesColumnSnapshot[]
  filters?: Record<string, RailsTablePreferencesFilterSnapshot | unknown>
  sorts?: RailsTablePreferencesSortSnapshot[]
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
