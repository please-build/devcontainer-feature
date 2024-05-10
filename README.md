# [please.build] Dev Container Feature

By Thought Machine

## Description

please.build's Dev Container Feature allows you to include please in Visual
Studio Code Dev Containers.  This feature ensures access to `plz` from the
terminal and the Please Plugin is installed.

## Terms of use

You are free to copy, modify, and distribute [please.build] Dev Container
Feature with attributation under the terms of the Apache-2.0 license. See the
`LICENSE` file for details.

## Prerequisites

* Visual Studio Code with Remote Development plugin installed

## How to use [please.build] devcontainer feature

* Add "ghcr.io/please-build/devcontainer-feature/please:1" to "features" in your `.devcontainer/devcontainer.json` file
* Run the "Rebuild and Reopen in Container" command

## Documentation

* [please.build]: please homepage
* <https://github.com/please-build/devcontainer-feature>: Repository for [please.build] devcontainer feature
* <https://github.com/please-build>: GitHub organisation for please repositories
* [Visual Studio Code Dev Container Features](https://code.visualstudio.com/docs/devcontainers/containers): Documentation on Visual Studio Code's Dev Containers

## Getting support

* [Issues](https://github.com/please-build/devcontainer-feature/issues): Report any issues to GitHub

## Distributing Features

### Marking Feature Public

Note that by default, GHCR packages are marked as `private`.  To stay within the free tier, Features need to be marked as `public`.

This can be done by navigating to the Feature's "package settings" page in GHCR, and setting the visibility to 'public`.  The URL may look something like:

```
https://github.com/users/<owner>/packages/container/<repo>%2F<featureName>/settings
```

<img width="669" alt="image" src="https://user-images.githubusercontent.com/23246594/185244705-232cf86a-bd05-43cb-9c25-07b45b3f4b04.png">

### Adding Features to the Index

If you'd like your Features to appear in our [public index](https://containers.dev/features) so that other community members can find them, you can do the following:

* Go to [github.com/devcontainers/devcontainers.github.io](https://github.com/devcontainers/devcontainers.github.io)
     * This is the GitHub repo backing the [containers.dev](https://containers.dev/) spec site
* Open a PR to modify the [collection-index.yml](https://github.com/devcontainers/devcontainers.github.io/blob/gh-pages/_data/collection-index.yml) file

This index is from where [supporting tools](https://containers.dev/supporting) like [VS Code Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) and [GitHub Codespaces](https://github.com/features/codespaces) surface Features for their dev container creation UI.

#### Using private Features in Codespaces

For any Features hosted in GHCR that are kept private, the `GITHUB_TOKEN` access token in your environment will need to have `package:read` and `contents:read` for the associated repository.

Many implementing tools use a broadly scoped access token and will work automatically.  GitHub Codespaces uses repo-scoped tokens, and therefore you'll need to add the permissions in `devcontainer.json`

An example `devcontainer.json` can be found below.

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
     "ghcr.io/my-org/private-features/hello:1": {
            "greeting": "Hello"
        }
    },
    "customizations": {
        "codespaces": {
            "repositories": {
                "my-org/private-features": {
                    "permissions": {
                        "packages": "read",
                        "contents": "read"
                    }
                }
            }
        }
    }
}
```
