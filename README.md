<!-- markdownlint-disable MD030 -->

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./src/frontend/src/assets/vetrai_logo_white.svg">
  <img src="./src/frontend/src/assets/vetrai_logo_black.svg" alt="Vetrai logo">
</picture>

[![Release Notes](https://img.shields.io/github/release/vetrai/vetrai?style=flat-square)](https://github.com/vetrai/vetrai/releases)
[![PyPI - License](https://img.shields.io/badge/license-MIT-orange)](https://opensource.org/licenses/MIT)
[![PyPI - Downloads](https://img.shields.io/pypi/dm/vetrai?style=flat-square)](https://pypistats.org/packages/vetrai)
[![Twitter](https://img.shields.io/twitter/url/https/twitter.com/vetrai_ai.svg?style=social&label=Follow%20%40Vetrai)](https://twitter.com/vetrai_ai)
[![Discord Server](https://img.shields.io/discord/1116803230643527710?logo=discord&style=social&label=Join)](https://discord.gg/EqksyE2EX9)

[Vetrai](https://vetrai.org) is a powerful platform for building and deploying AI-powered agents and workflows. It provides developers with both a visual authoring experience and built-in API and MCP servers that turn every workflow into a tool that can be integrated into applications built on any framework or stack. Vetrai comes with batteries included and supports all major LLMs, vector databases and a growing library of AI tools.

## ✨ Highlight features

- **Visual builder interface** to quickly get started and iterate.
- **Source code access** lets you customize any component using Python.
- **Interactive playground** to immediately test and refine your flows with step-by-step control.
- **Multi-agent orchestration** with conversation management and retrieval.
- **Deploy as an API** or export as JSON for Python apps.
- **Deploy as an MCP server** and turn your flows into tools for MCP clients.
- **Observability** with LangSmith, LangFuse and other integrations.
- **Enterprise-ready** security and scalability.

## 🖥️  Vetrai Desktop

Vetrai Desktop is the easiest way to get started with Vetrai. All dependencies are included, so you don't need to manage Python environments or install packages manually.
Available for Windows and macOS.

[📥 Download Vetrai Desktop](https://www.vetrai.org/desktop)

## ⚡️ Quickstart

### Install locally (recommended)

Requires Python 3.10–3.13 and [uv](https://docs.astral.sh/uv/getting-started/installation/) (recommended package manager).

#### Install

From a fresh directory, run:
```shell
uv pip install vetrai -U
```

The latest Vetrai package is installed.
For more information, see [Install and run the Vetrai OSS Python package](https://docs.vetrai.org/get-started-installation#install-and-run-the-vetrai-oss-python-package).

#### Run

To start Vetrai, run:
```shell
uv run vetrai run
```

Vetrai starts at http://127.0.0.1:7860.

That's it! You're ready to build with Vetrai! 🎉

## 📦 Other install options

### Run from source
If you've cloned this repository and want to contribute, run this command from the repository root:
```shell
make run_cli
```
For more information, see [DEVELOPMENT.md](./DEVELOPMENT.md).

### Docker
Start a Vetrai container with default settings:
```shell
docker run -p 7860:7860 vetrai/vetrai:latest
```
Vetrai is available at http://localhost:7860/.
For configuration options, see the [Docker deployment guide](https://docs.vetrai.org/deployment-docker).

## 🚀 Deployment

Vetrai is completely open source and you can deploy it to all major deployment clouds. To learn how to deploy Vetrai, see our [Vetrai deployment guides](https://docs.vetrai.org/deployment-overview).

## ⭐ Stay up-to-date

Star Vetrai on GitHub to be instantly notified of new releases.

## 👋 Contribute

We welcome contributions from developers of all levels. If you'd like to contribute, please check our [contributing guidelines](./CONTRIBUTING.md) and help make Vetrai more accessible.

---

## ❤️ Contributors

Thank you to all the contributors who make Vetrai possible!
