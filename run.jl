# Add dependencies
using Pkg
Pkg.add("TOML")
using TOML

# Extract the version number to be updated
VERSION = ARGS[1]
VERSION = split(VERSION, "-")[1]
VERSION = replace(VERSION, "v" => "")
VERSION = replace(VERSION, "V" => "")

# Update the version number
fname = "Project.toml";
dict_project = TOML.parsefile(fname)
dict_project["version"] = VERSION
open(fname, "w") do io
    TOML.print(io, dict_project)
end
