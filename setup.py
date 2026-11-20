"""Bootstrap de máquina Windows. Só stdlib — roda com o Python instalado pelo mise.

Uso:  python setup.py [--perfil work|personal] [winget] [chezmoi] [debloater]
"""

import argparse
import json
import subprocess
import sys
import tempfile
import time
import tomllib
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PARALELO = 4
TENTATIVAS = 4
# 0 = ok, 0x8A150061 = já instalado, 0x8A15002B = nenhum upgrade aplicável
SUCESSO = {0, 0x8A150061, 0x8A15002B}


def sh(*cmd, quiet=False):
    return subprocess.run(cmd, text=True, encoding="utf-8", errors="replace", capture_output=quiet)


# ---------------------------------------------------------------- winget
def winget_instalados() -> set[str]:
    """Um único `winget export` em vez de checar pacote a pacote."""
    with tempfile.TemporaryDirectory() as d:
        out = Path(d) / "installed.json"
        sh("winget", "export", "-o", str(out), "--source", "winget", "--accept-source-agreements", quiet=True)
        if not out.exists():
            return set()
        data = json.loads(out.read_text("utf-8-sig"))
    return {p["PackageIdentifier"].lower() for s in data["Sources"] for p in s["Packages"]}


def winget_install(pkg: str) -> tuple[str, bool, str]:
    for tentativa in range(1, TENTATIVAS + 1):
        r = sh(
            "winget",
            "install",
            "--id",
            pkg,
            "--exact",
            "--source",
            "winget",
            "--silent",
            "--disable-interactivity",
            "--accept-package-agreements",
            "--accept-source-agreements",
            quiet=True,
        )
        if (r.returncode & 0xFFFFFFFF) in SUCESSO:
            return pkg, True, ""
        time.sleep(2**tentativa)  # MSI aceita 1 instalação por vez → backoff
    return pkg, False, r.stdout[-1500:]


def etapa_winget(perfil: str) -> bool:
    cfg = tomllib.loads((ROOT / "packages.toml").read_text("utf-8"))
    pacotes = cfg["work"] + (cfg["personal"] if perfil == "personal" else [])

    sh("winget", "source", "update", quiet=True)
    ja = winget_instalados()
    faltam = [p for p in pacotes if p.lower() not in ja]
    print(f"winget: {len(faltam)} a instalar, {len(pacotes) - len(faltam)} já presentes")

    falhas = []
    with ThreadPoolExecutor(PARALELO) as ex:
        for fut in as_completed([ex.submit(winget_install, p) for p in faltam]):
            pkg, ok, log = fut.result()
            print(f"  {'✓' if ok else '✗'} {pkg}")
            if not ok:
                falhas.append((pkg, log))
    for pkg, log in falhas:
        print(f"\n--- {pkg} ---\n{log}")
    return not falhas


# ---------------------------------------------------------------- chezmoi
def etapa_chezmoi(perfil: str) -> bool:
    if (Path.home() / ".local/share/chezmoi/.git").exists():
        print("chezmoi: já inicializado")
        return True
    return sh("mise", "x", "--", "chezmoi", "init", "--apply=false").returncode == 0


# ---------------------------------------------------------------- debloater
def etapa_debloater(perfil: str) -> bool:
    ps = "function Clear-Host {}; & ([scriptblock]::Create((Invoke-RestMethod 'https://debloat.raphi.re/')))"
    return sh("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", ps).returncode == 0


ETAPAS = {"winget": etapa_winget, "chezmoi": etapa_chezmoi, "debloater": etapa_debloater}


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # ✓/✗ mesmo com saída redirecionada
    ap = argparse.ArgumentParser()
    ap.add_argument("--perfil", choices=["work", "personal"])
    ap.add_argument("etapas", nargs="*", metavar="ETAPA", help=" | ".join(ETAPAS))
    a = ap.parse_args()
    etapas = a.etapas or list(ETAPAS)
    if invalidas := set(etapas) - ETAPAS.keys():
        ap.error(f"etapas inválidas: {invalidas}")

    perfil = a.perfil or {"1": "work", "2": "personal"}.get(input("Perfil  [1] work  [2] personal: ").strip())
    if not perfil:
        ap.error("perfil inválido")

    # Runtimes do mise (node, java, go, chezmoi…) baixam em paralelo com o winget
    log = Path(tempfile.gettempdir()) / "mise-install.log"
    mise = subprocess.Popen(["mise", "install"], stdout=log.open("w"), stderr=subprocess.STDOUT)

    resultado = {}
    for nome in etapas:
        if nome == "chezmoi":  # chezmoi vem do mise
            mise.wait()
        print(f"\n=== {nome} ===")
        resultado[nome] = ETAPAS[nome](perfil)
    resultado["mise"] = mise.wait() == 0

    print("\n=== resumo ===")
    for nome, ok in resultado.items():
        print(f"  {'✓' if ok else '✗'} {nome}")
    if not resultado["mise"]:
        print(f"  log do mise: {log}")
    return 0 if all(resultado.values()) else 1


if __name__ == "__main__":
    raise SystemExit(main())
