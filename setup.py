"""Setup da máquina: winget (pacotes do perfil) -> chezmoi -> debloater.

Uso: python setup.py [work|personal]
Falhas não interrompem nada: aparecem só no resumo do fim.
"""

import io
import subprocess
import sys
import time
import tomllib
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

PACOTES_TOML = Path(__file__).resolve().parent / "packages.toml"
PARALELO = 4
TENTATIVAS = 3
ESPERA_ENTRE_TENTATIVAS = 10  # segundos, multiplicado pela tentativa

# 0 = ok, 0x8A150061 = já instalado, 0x8A15002B = sem upgrade disponível
CODIGOS_DE_SUCESSO = {0, 0x8A150061, 0x8A15002B}

# fmt: off
WINGET_INSTALL = [
    "winget", "install", "--exact", "--source", "winget", "--silent",
    "--disable-interactivity",
    "--accept-package-agreements", "--accept-source-agreements",
]

CHEZMOI_INIT = ["mise", "x", "--", "chezmoi", "init"]

DEBLOATER = [
    "powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command",
    "function Clear-Host {}; & ([scriptblock]::Create((irm 'https://debloat.raphi.re/')))",
]
# fmt: on

Erro = str | None  # None = deu certo


def ultima_linha(texto: str) -> str:
    linhas = [linha.strip() for linha in texto.splitlines() if linha.strip()]
    return linhas[-1] if linhas else ""


def instalar(pacote: str) -> Erro:
    """Instala um pacote do winget, tentando de novo se falhar."""
    erro = "não executado"
    for tentativa in range(TENTATIVAS):
        if tentativa > 0:
            # MSI só aceita uma instalação por vez: espera e tenta de novo
            time.sleep(ESPERA_ENTRE_TENTATIVAS * tentativa)

        resultado = subprocess.run(
            [*WINGET_INSTALL, "--id", pacote],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        # winget devolve um HRESULT; normaliza para inteiro sem sinal
        codigo = resultado.returncode & 0xFFFFFFFF
        if codigo in CODIGOS_DE_SUCESSO:
            print(f"  ok     {pacote}")
            return None
        else:
            erro = f"0x{codigo:08X} {ultima_linha(resultado.stdout)}"

    print(f"  falhou {pacote}")
    return erro


def rodar(comando: list[str]) -> Erro:
    codigo = subprocess.run(comando).returncode
    return None if codigo == 0 else f"saiu com código {codigo}"


def escolher_perfil(perfis: list[str]) -> str:
    if len(sys.argv) > 1:
        perfil = sys.argv[1]
    else:
        perfil = input(f"Perfil ({'/'.join(perfis)}): ").strip()

    if perfil not in perfis:
        sys.exit(f"Perfil inválido: {perfil!r}")
    return perfil


def pacotes_do_perfil(listas: dict[str, list[str]], perfil: str) -> list[str]:
    """`work` é a base de todos os perfis; os outros somam a própria lista."""
    if perfil == "work":
        return listas["work"]
    return listas["work"] + listas[perfil]


def instalar_todos(pacotes: list[str]) -> dict[str, Erro]:
    with ThreadPoolExecutor(PARALELO) as executor:
        erros = executor.map(instalar, pacotes)
        return dict(zip(pacotes, erros, strict=True))


def mostrar_resumo(erros: dict[str, Erro]) -> None:
    falhas = {nome: erro for nome, erro in erros.items() if erro is not None}
    print("\n== resumo")
    if not falhas:
        print("  tudo certo")
        return
    for nome, erro in falhas.items():
        print(f"  {nome}: {erro}")
    print(f"  {len(falhas)} falha(s)")


def main() -> None:
    if isinstance(sys.stdout, io.TextIOWrapper):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    listas = tomllib.loads(PACOTES_TOML.read_text("utf-8"))
    perfil = escolher_perfil(list(listas))
    pacotes = pacotes_do_perfil(listas, perfil)

    print(f"\n== winget ({perfil}, {len(pacotes)} pacotes)")
    erros = instalar_todos(pacotes)

    print("\n== chezmoi")
    erros["chezmoi"] = rodar(CHEZMOI_INIT)

    print("\n== debloater")
    erros["debloater"] = rodar(DEBLOATER)

    mostrar_resumo(erros)


if __name__ == "__main__":
    main()
