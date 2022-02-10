# julia-package-publish

Update the version number in Project.toml, commit and tag the new version, then register it into a private registry 

# Usage

```yaml
name: publish Julia package

on: 
  push:
    branches: [master]
    paths:
      - '**.jl'
      - '**.sh'
      - '**.md'
      - '**.yml'
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: '0'
      - uses: julia-actions/setup-julia@v1
        with:
          version: '1.6'
      - name: Register new Julia Package version
        uses: n6171028/julia-package-publish@main
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          julia_registry_url: 'git@github.com:$(your-registry-repo)'
          julia_registry_name: '$(your-registry-name)'
          release_branches: 'master,main'
```

Please add `paths` session in the trigger since this action will automatically register the new version to the registry. Please add `paths` without `**.toml` to prevent endlessly and recursively triggering actions.

## License

The scripts and documentation in this project are released under the [MIT License](LICENSE)