include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/live/_envcommon/network.hcl"
  expose = true
}

# Unit-specific overrides (if any) go here; the base config lives in _envcommon/network.hcl.
