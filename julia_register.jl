using Pkg
Pkg.add(Pkg.PackageSpec(;name="LocalRegistry", version="0.3.2"))
using LocalRegistry

registry_name = ARGS[1]
registry_url = ARGS[2]

Pkg.Registry.add(RegistrySpec(url=registry_url))
pkg"develop ."

proj_path = pwd()
run(`ls /home/runner/.julia/registries/`)
cd("/home/runner/.julia/registries/$(registry_name)/")
run(`git config user.name "GitHub Actions Bot"`)
run(`git config user.email "<>"`)
run(`git fetch --all`)
run(`git checkout test`)
register(proj_path, registry_name; push = true)