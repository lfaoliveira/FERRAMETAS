# app-life-saver

Em um **PowerShell como Administrador**, numa máquina Windows recém-formatada:

```powershell
irm https://raw.githubusercontent.com/lfaoliveira/FERRAMETAS/main/init.ps1 | iex
```

Não precisa de git nem de Python: o script baixa o repo em `~\app-life-saver`, instala o que falta e segue sozinho.

---

## O que acontece

```
init.ps1  (PowerShell, única parte que precisa existir numa máquina limpa)
 ├─ baixa o repo (zip do GitHub) se não estiver rodando de dentro dele
 ├─ garante winget  (registra o App Installer se faltar)
 ├─ winget install jdx.mise
 ├─ mise install      (python, node, java, go, chezmoi…)
 └─ python setup.py <perfil>
       ├─ winget     pacotes do perfil em packages.toml, em paralelo, com retry
       ├─ chezmoi    init
       ├─ debloater  https://debloat.raphi.re
       └─ resumo     o que falhou e com qual erro (falha não interrompe nada)
```

| Arquivo         | Para quê                                           |
| --------------- | -------------------------------------------------- |
| `init.ps1`      | Bootstrap: winget → mise → Python → `setup.py`     |
| `setup.py`      | Todo o setup, só stdlib do Python                  |
| `packages.toml` | IDs do winget por perfil                           |
| `mise.toml`     | Runtimes e CLIs (python, node, java, go, chezmoi…) |
| `chezmoi/`      | Dotfiles                                           |

## Perfis

- **work** — app-life-saver de desenvolvimento (lista `work` em `packages.toml`)
- **personal** — `work` + jogos, mídia etc. (lista `personal`)

## Uso com o repo já baixado

```powershell
powershell -ExecutionPolicy Bypass -File .\init.ps1 -Perfil personal   # fluxo completo
mise run setup -- work                                                 # só o setup.py
```

O `-ExecutionPolicy Bypass` é necessário porque o Windows recém-instalado bloqueia `.ps1` locais.

## Adicionar um programa

Procure o ID (`winget search <nome>`) e coloque em `work` ou `personal` no `packages.toml`. Depois rode `mise run setup -- <perfil>` de novo — o que já está instalado é reconhecido e não conta como falha.

## Problemas

- **Algum pacote falhou**: o resumo no fim lista cada falha com o código e a última mensagem do winget. Basta rodar o setup de novo.
- **`winget` não reconhecido logo após formatar**: o App Installer ainda está se registrando. Rode `Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe` e tente de novo.
- **Comando não encontrado depois do setup**: feche e abra o terminal para recarregar o PATH.

Credenciais a configurar depois da instalação: [AUTH.md](AUTH.md). Dotfiles: [chezmoi/README.md](chezmoi/README.md).
