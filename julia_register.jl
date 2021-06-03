using Pkg
Pkg.add(Pkg.PackageSpec(;name="LocalRegistry", version="0.3.2"))
using LocalRegistry
using Git
using TOML

# Read input parameters
registry_name = ARGS[1]
registry_url = ARGS[2]
registry_branch = ARGS[3]
dry_run = ARGS[4]

if lowercase(dry_run) != "true" && lowercase(dry_run) != "yes"
    # Add the private Julia registry
    Pkg.Registry.add(RegistrySpec(url=registry_url))
    pkg"develop ."


    # Read the Project.toml file in the package
    GITHUB_REPOSITORY = ENV["GITHUB_REPOSITORY"]
    TOKEN = ""
    URL = ""
    if haskey(ENV, "GITHUB_TOKEN")
        TOKEN = ENV["GITHUB_TOKEN"]
        URL = "https://x-access-token:$(TOKEN)@github.com/$(GITHUB_REPOSITORY).git"
    end

    fname = "Project.toml";
    dict_project = TOML.parsefile(fname)
    VERSION = dict_project["version"]
    run(`$(git()) tag -a -f "v$(VERSION)" -m "Update version to v$(VERSION)"`)
    if isempty(URL)
        run(`$(git()) push --tags`)
    else
        run(`$(git()) push --tags $(URL)`)
    end

    # Get the package location
    proj_path = pwd()

    # Checkout to the specified branch
    cd("/home/runner/.julia/registries/$(registry_name)/")
    run(`$(git()) fetch --all`)
    run(`$(git()) checkout $(registry_branch)`)

    # Register the new version in the Julia registry
    register(proj_path, registry_name)
    run(`$(git()) push`)
end