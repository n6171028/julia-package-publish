# Add dependencies
using Pkg
Pkg.add(Pkg.PackageSpec(;name="Git", version="1.2.1"))
Pkg.add(Pkg.PackageSpec(;name="TOML", version="1.0.0"))
Pkg.add(Pkg.PackageSpec(;name="LocalRegistry", version="0.3.2"))
using TOML
using Git
using Logging
using LocalRegistry

function findmaxversion(julia_path::String, registry_name::String, package_name::String)
    l = package_name[1:1]
    package_path = joinpath(julia_path,"registries", registry_name, l, package_name)
    if isdir(package_path)
        di = Pkg.Operations.load_versions(Pkg.Types.Context(), package_path)
        return maximum(keys(di))
    end
    return v"0.0.0"
end

# Read inputs
registry_url = ARGS[1]
registry_name = ARGS[2]
release_branches = ARGS[3]
strip_v = ARGS[4]

# Read the Project.toml file in the package
fname = "Project.toml";
dict_project = TOML.parsefile(fname)
project_name = dict_project["name"]
version_string_in_project_toml = dict_project["version"]
current_major, current_minor, current_patch = parse.(Int, split(version_string_in_project_toml, '.'))
current_version_num = 1000000 * current_major + 1000 * current_minor + current_patch
@info "Found the version number in the Project.toml is $version_string_in_project_toml"

# Check whether we should publish the package
current_branch = readchomp(`$(git()) symbolic-ref --short HEAD`)
current_branch = replace(current_branch, "heads/"=>"")
branches = split(release_branches, ',')
if current_branch ∉ branches
    @info "This branch $current_branch is not a releasing branch $release_branches, skip registering"
    # Determine whether version number should started with a 'v' letter
    if lowercase(strip_v) != "true"
        version_string_in_project_toml = "v"*version_string_in_project_toml
    end
    run(`echo "::set-output name=version::$(version_string_in_project_toml)"`)
    exit()
end

# Add the private registry
Pkg.Registry.add(RegistrySpec(url=registry_url, name=registry_name))

# Find the latest version from the registry
max_version = string(findmaxversion("/home/runner/.julia/", registry_name, project_name))
registered_major, registered_minor, registered_patch = parse.(Int, split(max_version, '.'))
registered_version_num = 1000000 * registered_major + 1000 * registered_minor + registered_patch
@info "Found the latest version number in the registry is $max_version"

# Getting the URL of the repository
GITHUB_REPOSITORY = ENV["GITHUB_REPOSITORY"]
TOKEN = ""
URL = ""
if haskey(ENV, "GITHUB_TOKEN")
    TOKEN = ENV["GITHUB_TOKEN"]
    URL = "https://x-access-token:$(TOKEN)@github.com/$(GITHUB_REPOSITORY).git"
end
@info "Found the URL as $URL"

# Find the version bump strategy
# major = 1, minor = 2, patch = 3, default = 4
version_bump = 4
git_logs = readchomp(`$(git()) log -1 --pretty='%B'`)
if occursin("#patch", git_logs)
    version_bump = 3
end
if occursin("#minor", git_logs)
    version_bump = 2
end
if occursin("#major", git_logs)
    version_bump = 1
end

julia_version_string = version_string_in_project_toml
if current_version_num > registered_version_num && version_bump == 4
    @info "The Project.toml has new version, no version bump required"
else
    if current_version_num < registered_version_num
        current_major = registered_major
        current_minor = registered_minor
        current_patch = registered_patch
    end

    # Bump up version
    if version_bump == 1
        current_major += 1
        current_minor = 0
        current_patch = 0
    elseif version_bump == 2
        current_minor += 1
        current_patch = 0
    else 
        current_patch += 1
    end

    julia_version_string = "$current_major.$current_minor.$current_patch"
    @info "Bumping version number to $julia_version_string"
    dict_project["version"] = julia_version_string
    open(fname, "w") do io
        TOML.print(io, dict_project)
    end
    
    @info "Commiting and pushing the Project.toml"
    # Commit the new Project.toml
    run(`$(git()) add Project.toml`)
    run(`$(git()) commit -m "Update version to v$julia_version_string"`)
    run(`$(git()) restore .`)
    if isempty(URL)
        run(`$(git()) push`)
    else
        run(`$(git()) push $(URL)`)
    end
    @info "Current git workspace status"
    @info readchomp(`$(git()) status`)
end

# Determine whether version number should started with a 'v' letter
if lowercase(strip_v) != "true"
    julia_version_string = "v"*julia_version_string
end

# Register the new version in the Julia registry
@info readchomp(`$(git()) status`)
@info readchomp(`$(git()) restore .`)
pkg"develop ."
register(project_name, registry_name; push = true)

# Tag
@info "Creating tag $julia_version_string"
run(`$(git()) tag "julia-registered-$(julia_version_string)"`)
if isempty(URL)
    run(`$(git()) push --tags`)
else
    run(`$(git()) push --tags $(URL)`)
end

run(`echo "::set-output name=version::$(julia_version_string)"`)