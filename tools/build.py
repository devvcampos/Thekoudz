from __future__ import annotations

import hashlib
import json
import sys
import time
from pathlib import Path


# ============================================================
# PATHS
# ============================================================

ROOT = Path(__file__).resolve().parent.parent

SRC = ROOT / "src"
DIST = ROOT / "dist"

OUTPUT = DIST / "Thekoudz.lua"


# ============================================================
# ARQUIVOS QUE ENTRAM NA BUILD
# ============================================================

MODULES = [
    "Main.lua",

    "Config.lua",
    "Ui.lua",
    "Library.lua",

    "Modules/ESP.lua",
    "Modules/DeadBodyChams.lua",

    "addons/ThemeManager.lua",
    "addons/SaveManager.lua",
]


# ============================================================
# LUA LONG STRING
# ============================================================

def lua_long_string(text: str) -> str:
    """
    Gera uma long string Lua que não conflite
    com o conteúdo do arquivo.
    """

    for level in range(20):
        equals = "=" * level

        closing = "]" + equals + "]"

        if closing not in text:
            return (
                "["
                + equals
                + "["
                + text
                + "]"
                + equals
                + "]"
            )

    raise RuntimeError(
        "Não foi possível gerar uma long string segura."
    )


# ============================================================
# LEITURA DAS SOURCES
# ============================================================

def read_sources() -> dict[str, str]:
    sources: dict[str, str] = {}

    for relative in MODULES:
        path = SRC / relative

        if not path.exists():
            raise FileNotFoundError(
                f"Arquivo não encontrado: {path}"
            )

        sources[relative] = path.read_text(
            encoding="utf-8-sig"
        )

    return sources


# ============================================================
# BUILD ID
# ============================================================

def calculate_build_id(
    sources: dict[str, str]
) -> str:

    digest = hashlib.sha256()

    for name in sorted(sources):
        digest.update(
            name.encode("utf-8")
        )

        digest.update(
            b"\0"
        )

        digest.update(
            sources[name].encode("utf-8")
        )

        digest.update(
            b"\0"
        )

    return digest.hexdigest()[:12].upper()


# ============================================================
# GERADOR
# ============================================================

def generate_bundle(
    sources: dict[str, str],
    build_id: str,
) -> str:

    parts: list[str] = []

    parts.append(
        "-- AUTO-GENERATED FILE\n"
        "-- DO NOT EDIT\n"
        f"-- BUILD: {build_id}\n\n"
    )

    # --------------------------------------------------------
    # TABELA INTERNA DE SOURCES
    # --------------------------------------------------------

    parts.append(
        "local __S = {\n"
    )

    for name in MODULES:
        encoded_name = json.dumps(name)

source = lua_long_string(
    sources[name]
)

        parts.append(
            "    ["
            + encoded_name
            + "] = "
            + source
            + ",\n"
        )

    parts.append(
        "}\n\n"
    )

    # --------------------------------------------------------
    # CACHE INTERNO
    # --------------------------------------------------------

    parts.append(
        """
local __C = {}

local function __L(path)
    local cached = __C[path]

    if cached ~= nil then
        return cached
    end

    local source = __S[path]

    assert(
        source ~= nil,
        "Modulo nao encontrado na build: "
            .. tostring(path)
    )

    local chunk, err =
        loadstring(source)

    assert(
        chunk,
        "Erro compilando "
            .. tostring(path)
            .. ": "
            .. tostring(err)
    )

    local ok, result =
        pcall(chunk)

    assert(
        ok,
        "Erro executando "
            .. tostring(path)
            .. ": "
            .. tostring(result)
    )

    assert(
        result ~= nil,
        tostring(path)
            .. " retornou nil"
    )

    __C[path] = result

    return result
end

"""
    )

    # --------------------------------------------------------
    # ENTRYPOINT
    # --------------------------------------------------------

    parts.append(
        """
local __Main =
    __L("Main.lua")

assert(
    type(__Main) == "function",
    "Main.lua precisa retornar uma funcao"
)

return __Main(__L)
"""
    )

    return "".join(parts)


# ============================================================
# BUILD
# ============================================================

def build() -> str:
    sources = read_sources()

    build_id =
        calculate_build_id(
            sources
        )

    bundle =
        generate_bundle(
            sources,
            build_id,
        )

    DIST.mkdir(
        parents=True,
        exist_ok=True,
    )

    OUTPUT.write_text(
        bundle,
        encoding="utf-8",
        newline="\n",
    )

    size_kb =
        OUTPUT.stat().st_size / 1024

    print()
    print(
        f"[BUILD] {build_id}"
    )

    print(
        f"[OK] {OUTPUT}"
    )

    print(
        f"[SIZE] {size_kb:.1f} KB"
    )

    return build_id


# ============================================================
# WATCHER
# ============================================================

def source_signature() -> str:
    digest = hashlib.sha256()

    for relative in MODULES:
        path = SRC / relative

        if not path.exists():
            digest.update(
                relative.encode()
            )

            continue

        digest.update(
            relative.encode()
        )

        digest.update(
            path.read_bytes()
        )

    return digest.hexdigest()


def watch() -> None:
    print(
        "[WATCH] Observando src/..."
    )

    previous = None

    while True:
        try:
            current = source_signature()

            if current != previous:
                try:
                    build()

                    previous = current
                except Exception as exc:
                    print(
                        "[ERRO]",
                        exc
                    )

            time.sleep(0.35)

        except KeyboardInterrupt:
            print()
            print(
                "[WATCH] Encerrado."
            )

            return


# ============================================================
# CLI
# ============================================================

if __name__ == "__main__":
    if "--watch" in sys.argv:
        watch()
    else:
        build()
