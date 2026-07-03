include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path   = "${get_repo_root()}/env/_envcommon/network.hcl"
  expose = true
}
