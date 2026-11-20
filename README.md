# FERRAMENTAS

Em um **PowerShell como Administrador**, numa máquina Windows recém-formatada:

```powershell
irm https://raw.githubusercontent.com/lfaoliveira/FERRAMETAS/main/init.ps1 | iex
```

Não precisa de git nem de Python: o script baixa o repo em `~\FERRAMENTAS`, instala o que falta e segue sozinho.

---

## O que acontece

```
init.ps1  (PowerShell, única parte que precisa existir numa máquina limpa)
 ├─ baixa o repo (zip do GitHub) se não estiver rodando de dentro dele
 ├─ garante winget  (registra o App Installer se faltar)
 ├─ winget install jdx.mise
 ├─ mise install python
 └─ python setup.py
       ├─ mise install ─────────────── em background (node, java, go, chezmoi…)
       ├─ winget   pacotes de packages.toml, em paralelo, com retry
       │           (pula o que já está instalado → rodar de novo é rápido)
       ├─ chezmoi  init (espera o mise terminar)
       └─ debloater  https://debloat.raphi.re
```

| Arquivo         | Para quê                                           |
| --------------- | -------------------------------------------------- |
| `init.ps1`      | Bootstrap: winget → mise → Python → `setup.py`     |
| `setup.py`      | Todo o setup, só stdlib do Python                  |
| `packages.toml` | IDs do winget por perfil                           |
| `mise.toml`     | Runtimes e CLIs (python, node, java, go, chezmoi…) |
| `chezmoi/`      | Dotfiles                                           |

## Perfis

- **work** — ferramentas de desenvolvimento (lista `work` em `packages.toml`)
- **personal** — `work` + jogos, mídia etc. (lista `personal`)

## Uso com o repo já baixado

```powershell
.\init.ps1 -Perfil personal          # fluxo completo

mise run setup -- --perfil work      # só o setup.py
python setup.py --perfil work winget # uma etapa: winget | chezmoi | debloater
```

## Adicionar um programa

Procure o ID (`winget search <nome>`) e coloque em `work` ou `personal` no `packages.toml`. Depois rode `python setup.py --perfil <perfil> winget` — só o que falta será instalado.

## Problemas

- **Algum pacote falhou**: o resumo no fim mostra a saída do winget de cada falha. Rode de novo a etapa `winget`; o que já instalou é pulado.
- **mise falhou**: o log fica em `%TEMP%\mise-install.log`.
- **Comando não encontrado depois do setup**: feche e abra o terminal para recarregar o PATH.

Credenciais a configurar depois da instalação: [AUTH.md](AUTH.md). Dotfiles: [chezmoi/README.md](chezmoi/README.md).

