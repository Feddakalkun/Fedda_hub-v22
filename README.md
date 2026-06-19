# FEDDA Hub v21

FEDDA Hub v21 is the modular distribution branch for a workflow-first local AI studio.

## v21 scope

The core UI stays focused on five areas:

- Image Studio
- Video Studio
- Gallery, with images and videos together
- LoRA & Character
- Ollama Models

Workflow families are being separated into core and booster modules so the app can stay usable even when an optional model pack or custom node set is not installed.

Current module ownership lives in:

```text
config\modules.json
```

v21 builds on the clean repo + install separation. The modular foundation (core + boosters) is in place, with Venice.ai integration (image generation + agent chat) added in recent updates. Modules describe ownership and guide installer node selection.

## Install layout

For local staging, put the one-click installer in any folder you want to use as the install root. The installer creates:

```text
<your chosen folder>\
  FEDDA_v21_Installer.bat
  app\                 # local runtime install target, ignored by git
  logs\                # installer logs
```

The single-file installer clones or updates:

```text
https://github.com/Feddakalkun/Fedda_hub-v21
```

into `install\app`, then runs `scripts\install.bat LITE`.

Current active features include:
- Image + Video Studios
- Gallery
- LoRA & Character management
- Ollama models
- **Venice.ai** (Image generation + full Agent chat with web search, vision, reasoning)

That same repository is the active v21 development remote.

## Runtime policy

Runtime and generated assets are not committed:

- `ComfyUI/`
- `python_embeded/`
- `venv/`
- `node_modules/`
- `ollama_embeded/`
- model folders and model binaries
- cache, logs, temp, output folders

The installer bootstraps those locally.

## Development checks

From the repo folder:

```powershell
cd <your repo folder>
.\scripts\smoke_clean_install.ps1
cd frontend
npm.cmd run build
```

Module manifest checks:

```powershell
python -m py_compile backend\module_service.py backend\server.py
powershell -ExecutionPolicy Bypass -Command ". .\scripts\module_nodes.ps1; Get-FeddaNodeConfig -RootPath (Get-Location).Path"
```

