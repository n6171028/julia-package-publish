using Pkg
Pkg.add(Pkg.PackageSpec(;name="LocalRegistry", version="0.3.2"))
using LocalRegistry
using Git

# Read input parameters
registry_name = ARGS[1]
registry_url = ARGS[2]
registry_branch = ARGS[3]

# Add the private Julia registry
Pkg.Registry.add(RegistrySpec(url=registry_url))
pkg"develop ."

# Get the package location
proj_path = pwd()

# Checkout to the specified branch
cd("/home/runner/.julia/registries/$(registry_name)/")
run(`$(git()) fetch --all`)
run(`$(git()) checkout $(registry_branch)`)

# Register the new version in the Julia registry
register(proj_path, registry_name)
run(`$(git()) push`)