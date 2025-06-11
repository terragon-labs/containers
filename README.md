# containers

Containers for the Terragon platform.

## e2b

```sh
# make sure you have e2b installed
brew install e2b

# This will give you a template id that we can use in e2b-provider.ts
pnpm run build:e2b
```

## docker

```sh
# This is for local testing. On CI, we'll build the docker image and push it to the gh registry.
pnpm run build:local
```
