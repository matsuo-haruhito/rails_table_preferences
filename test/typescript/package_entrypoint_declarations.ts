import PackageRootController, {
  RailsTablePreferencesController as NamedPackageRootController,
  type RailsTablePreferencesEventDetail,
  type RailsTablePreferencesEventName
} from "rails_table_preferences"
import ControllerEntry from "rails_table_preferences/controller"

const controllers: Array<typeof PackageRootController> = [
  PackageRootController,
  NamedPackageRootController,
  ControllerEntry
]

const lifecycleEventName: RailsTablePreferencesEventName = "rails-table-preferences:saved"

document.addEventListener(lifecycleEventName, (event) => {
  const detail = (event as CustomEvent<RailsTablePreferencesEventDetail>).detail
  const tableKey: string = detail.tableKey
  const preferenceName: string = detail.name
  const action: string = detail.action

  void [tableKey, preferenceName, action]
})

void controllers
