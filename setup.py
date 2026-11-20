"""Setup da máquina: winget (pacotes do perfil) -> chezmoi -> debloater.

Uso: python setup.py [work|personal]
Falhas não interrompem nada: aparecem só no resumo do fim.
"""

import io
import json
import shutil
import subprocess
import sys
import tempfile
import threading
import time
import tomllib
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from types import TracebackType

PACOTES_TOML = Path(__file__).resolve().parent / "packages.toml"
PARALELO = 4
TENTATIVAS = 3
ESPERA_ENTRE_TENTATIVAS = 10  # segundos, multiplicado pela tentativa

# winget devolve HRESULTs; estes contam como sucesso
OK = 0
JA_INSTALADO = 0x8A150061
SEM_ATUALIZACAO = 0x8A15002B
CODIGOS_DE_SUCESSO = {OK, JA_INSTALADO, SEM_ATUALIZACAO}

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
UPDATE_PS1 = ["winget", "upgrade", "Microsoft.PowerShell"]
# fmt: on

Erro = str | None  # None = deu certo


class Progresso:
    """Linha temporária no pé da tela: barra ASCII, tempo e pacotes em andamento.

    As mensagens normais são impressas acima dela. A linha some ao sair do
    `with`, seja ao chegar em 100% ou por erro. Fora de um terminal (saída
    redirecionada) só as mensagens são impressas.
    """

    LARGURA_BARRA = 20

    def __init__(self, pacotes: list[str]) -> None:
        self.total = len(pacotes)
        self.largura_nome = max(map(len, pacotes), default=0)
        self.concluidos = 0
        self.em_andamento: list[str] = []
        self.inicio = time.monotonic()
        self.terminal = sys.stdout.isatty()
        self.lock = threading.Lock()
        self.parar = threading.Event()

    def __enter__(self) -> "Progresso":
        threading.Thread(target=self._relogio, daemon=True).start()
        return self

    def __exit__(
        self,
        tipo: type[BaseException] | None,
        erro: BaseException | None,
        tb: TracebackType | None,
    ) -> None:
        self.parar.set()
        with self.lock:
            self._apagar()

    def comecou(self, pacote: str, status: str) -> None:
        with self.lock:
            self.em_andamento.append(pacote)
            self._imprimir(pacote, status)

    def avisar(self, pacote: str, status: str) -> None:
        with self.lock:
            self._imprimir(pacote, status)

    def terminou(self, pacote: str, status: str) -> None:
        with self.lock:
            self.em_andamento.remove(pacote)
            self.concluidos += 1
            self._imprimir(pacote, status)

    # Os métodos abaixo assumem que o lock já está com quem chamou.
    def _imprimir(self, pacote: str, status: str) -> None:
        """Nome do pacote alinhado à esquerda, status à direita."""
        self._apagar()
        print(f"  {pacote:<{self.largura_nome}}  {status}")
        self._desenhar()

    def _desenhar(self) -> None:
        if not self.terminal or self.parar.is_set():
            return
        cheio = self.LARGURA_BARRA * self.concluidos // self.total
        barra = "#" * cheio + "-" * (self.LARGURA_BARRA - cheio)
        minutos, segundos = divmod(int(time.monotonic() - self.inicio), 60)
        linha = (
            f"[{barra}] {self.concluidos}/{self.total} "
            f"{minutos:02}:{segundos:02} | {', '.join(self.em_andamento)}"
        )
        largura = shutil.get_terminal_size().columns - 1
        sys.stdout.write("\r" + linha[:largura].ljust(largura))
        sys.stdout.flush()

    def _apagar(self) -> None:
        if self.terminal:
            largura = shutil.get_terminal_size().columns - 1
            sys.stdout.write("\r" + " " * largura + "\r")

    def _relogio(self) -> None:
        while not self.parar.wait(1):
            with self.lock:
                self._desenhar()


def ultima_linha(texto: str) -> str:
    linhas = [linha.strip() for linha in texto.splitlines() if linha.strip()]
    return linhas[-1] if linhas else ""


def winget_instalados() -> set[str]:
    """IDs já instalados, com um único `winget export` (em minúsculas)."""
    with tempfile.TemporaryDirectory() as pasta:
        arquivo = Path(pasta) / "instalados.json"
        subprocess.run(
            ["winget", "export", "-o", str(arquivo), "--source", "winget",
             "--accept-source-agreements"],
            capture_output=True,
        )  # fmt: skip
        if not arquivo.exists():
            return set()
        dados = json.loads(arquivo.read_text("utf-8-sig"))
    return {
        pacote["PackageIdentifier"].lower() for origem in dados["Sources"] for pacote in origem["Packages"]
    }


def instalar(pacote: str, ja_instalado: bool, progresso: Progresso) -> Erro:
    """Instala (ou atualiza) um pacote do winget, tentando de novo se falhar."""
    progresso.comecou(pacote, "atualizando..." if ja_instalado else "instalando...")

    erro = "não executado"
    for tentativa in range(TENTATIVAS):
        if tentativa > 0:
            progresso.avisar(pacote, f"tentando de novo ({tentativa + 1}/{TENTATIVAS})")
            # MSI só aceita uma instalação por vez: espera e tenta de novo
            time.sleep(ESPERA_ENTRE_TENTATIVAS * tentativa)

        resultado = subprocess.run(
            [*WINGET_INSTALL, "--id", pacote],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        codigo = resultado.returncode & 0xFFFFFFFF  # HRESULT como inteiro sem sinal
        if codigo in CODIGOS_DE_SUCESSO:
            if codigo == SEM_ATUALIZACAO:
                status = "já na última versão"
            elif codigo == JA_INSTALADO:
                status = "já instalado"
            elif ja_instalado:
                status = "atualizado"
            else:
                status = "instalado"
            progresso.terminou(pacote, f"ok, {status}")
            return None
        erro = f"0x{codigo:08X} {ultima_linha(resultado.stdout)}"

    progresso.terminou(pacote, "FALHOU (detalhes no resumo)")
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
    print("  verificando o que já está instalado...")
    instalados = winget_instalados()

    with Progresso(pacotes) as progresso, ThreadPoolExecutor(PARALELO) as executor:
        erros = executor.map(
            lambda pacote: instalar(pacote, pacote.lower() in instalados, progresso),
            pacotes,
        )
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
    erros["powershell"] = rodar(UPDATE_PS1)

    mostrar_resumo(erros)


if __name__ == "__main__":
    main()
