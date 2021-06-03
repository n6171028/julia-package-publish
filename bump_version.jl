# Add dependencies
using Pkg
Pkg.add(Pkg.PackageSpec(;name="Git", version="1.2.1"))
Pkg.add(Pkg.PackageSpec(;name="TOML", version="1.0.0"))
using TOML
using Git

# Extract the version number to be updated
VERSION = ""
if length(ARGS) > 0
    VERSION = ARGS[1]
end

GITHUB_REPOSITORY = ENV["GITHUB_REPOSITORY"]
TOKEN = ""
URL = ""
if haskey(ENV, "GITHUB_TOKEN")
    TOKEN = ENV["GITHUB_TOKEN"]
    URL = "https://x-access-token:$(TOKEN)@github.com/$(GITHUB_REPOSITORY).git"
end

# Read the Project.toml file in the package
fname = "Project.toml";
dict_project = TOML.parsefile(fname)

# If no version is given, use the version number in the Project.toml
if isempty(VERSION)
    VERSION = dict_project["version"]
else
    # Santity
    VERSION = split(VERSION, "-")[1]
    VERSION = replace(VERSION, "v" => "")
    VERSION = replace(VERSION, "V" => "")

    # Update the version number in the Project.toml
    if dict_project["version"] != VERSION
        dict_project["version"] = VERSION
        open(fname, "w") do io
            TOML.print(io, dict_project)
        end

        # Commit the new Project.toml
        run(`$(git()) add Project.toml`)
        run(`$(git()) commit -m "Update version to v$(VERSION)"`)
        if isempty(URL)
            run(`$(git()) push`)
        else
            run(`$(git()) push $(URL)`)
        end
    end
end

# Set output
run(`echo "::set-output name=version::$(VERSION)"`)