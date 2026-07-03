include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/live/_envcommon/gcs-bucket.hcl"
  expose = true
}

inputs = {
  name = "${include.envcommon.locals.project_id}-app-assets"
}
