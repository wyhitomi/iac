include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path   = "${get_repo_root()}/env/_envcommon/external-bucket.hcl"
  expose = true
}

inputs = {
  name = "${include.envcommon.locals.project_id}-external-demo"
}
