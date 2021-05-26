# julia-package-publish

Setting the version number in Project.toml, commit and tag the new version, then register it into the private registry 

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
      - name: Bump up version
        uses: anothrNick/github-tag-action@1.26.0
        id: tagger
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          RELEASE_BRANCHES: master
          WITH_V: true
          DRY_RUN: true
      - name: Register new Julia Package version
        uses: n6171028/julia-package-publish@main
        with:
          version: ${{steps.tagger.outputs.new_tag}}
          ssh_key: ${{ secrets.SSH }}
          julia_registry_url: 'git@github.com:$(your-registry-repo)'
          julia_registry_name: 'your-registry-repo'
```

Please add `paths` session in the trigger since this action will automatically push the new Project.toml in the repository. Please add `paths` without `**.toml` to prevent endlessly and recursively triggering actions.

## License

The scripts and documentation in this project are released under the [MIT License](LICENSE)