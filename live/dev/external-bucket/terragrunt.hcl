include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/live/_envcommon/external-bucket.hcl"
  expose = true
}

inputs = {
  name = "${include.envcommon.locals.project_id}-external-demo"
}
