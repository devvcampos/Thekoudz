from __future__ import annotations

import base64
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
# ARQUIVOS DA BUILD
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
    for level in range(32):
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
        "Não foi possível gerar uma long string Lua segura."
    )


# ============================================================
# SOURCES
# ============================================================

def read_sources() -> dict[str, str]:
    sources: dict[str, str] = {}

    for relative in MODULES:
        path = SRC / relative

        if not path.is_file():
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
    sources: dict[str, str],
) -> str:
    digest = hashlib.sha256()

    for name in sorted(sources):
        digest.update(name.encode("utf-8"))
        digest.update(b"\0")
        digest.update(sources[name].encode("utf-8"))
        digest.update(b"\0")

    return digest.hexdigest()[:12].upper()


# ============================================================
# RELEASE ENCODING
# ============================================================

def make_key(build_id: str) -> bytes:
    digest = hashlib.sha256(
        build_id.encode("utf-8")
    ).digest()

    return digest[:16]


def encode_source(
    source: str,
    key: bytes,
) -> str:
    raw = source.encode("utf-8")

    transformed = bytes(
        byte ^ key[index % len(key)]
        for index, byte in enumerate(raw)
    )

    return base64.b64encode(
        transformed
    ).decode("ascii")


# ============================================================
# BUNDLE
# ============================================================

def generate_bundle(
    sources: dict[str, str],
    build_id: str,
    release: bool,
) -> str:
    parts: list[str] = []
    key = make_key(build_id)

    mode = (
        "RELEASE"
        if release
        else "DEV"
    )

    parts.append(
        "-- AUTO-GENERATED FILE\n"
        "-- DO NOT EDIT\n"
        f"-- BUILD: {build_id}\n"
        f"-- MODE: {mode}\n\n"
    )

    # --------------------------------------------------------
    # SOURCES INTERNAS
    # --------------------------------------------------------

    parts.append(
        "local __S = {\n"
    )

    for name in MODULES:
        encoded_name = json.dumps(name)

        if release:
            encoded_source = encode_source(
                sources[name],
                key,
            )

            source_literal = json.dumps(
                encoded_source
            )

        else:
            source_literal = lua_long_string(
                sources[name]
            )

        parts.append(
            "    ["
            + encoded_name
            + "] = "
            + source_literal
            + ",\n"
        )

    parts.append(
        "}\n\n"
    )

    # --------------------------------------------------------
    # DECODER DE RELEASE
    # --------------------------------------------------------

    if release:
        lua_key = ", ".join(
            str(value)
            for value in key
        )

        parts.append(
            f"""local __K = {{{lua_key}}}

local __B64 =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function __D64(data)
    data = data:gsub(
        "[^" .. __B64 .. "=]",
        ""
    )

    return (
        data:gsub(".", function(x)
            if x == "=" then
                return ""
            end

            local r = ""
            local f =
                (__B64:find(x, 1, true) or 1)
                - 1

            for i = 6, 1, -1 do
                r =
                    r
                    .. (
                        f % 2 ^ i
                        - f % 2 ^ (i - 1)
                        > 0
                        and "1"
                        or "0"
                    )
            end

            return r
        end)
        :gsub(
            "%d%d%d?%d?%d?%d?%d?%d?",
            function(x)
                if #x ~= 8 then
                    return ""
                end

                local c = 0

                for i = 1, 8 do
                    if x:sub(i, i) == "1" then
                        c =
                            c
                            + 2 ^ (8 - i)
                    end
                end

                return string.char(c)
            end
        )
    )
end

local function __Decode(data)
    local raw =
        __D64(data)

    local out = {{}}

    for i = 1, #raw do
        local keyIndex =
            ((i - 1) % #__K)
            + 1

        out[i] =
            string.char(
                bit32.bxor(
                    raw:byte(i),
                    __K[keyIndex]
                )
            )
    end

    return table.concat(out)
end

"""
        )

        source_expression = "__Decode(__S[path])"

    else:
        source_expression = "__S[path]"

    # --------------------------------------------------------
    # LOADER INTERNO
    # --------------------------------------------------------

    parts.append(
        f"""local __C = {{}}

local function __L(path)
    local cached = __C[path]

    if cached ~= nil then
        return cached
    end

    local source =
        {source_expression}

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
        """local __Main =
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
    release = "--release" in sys.argv

    sources = read_sources()

    build_id = calculate_build_id(
        sources
    )

    bundle = generate_bundle(
        sources,
        build_id,
        release,
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

    size_kb = (
        OUTPUT.stat().st_size
        / 1024
    )

    mode = (
        "RELEASE"
        if release
        else "DEV"
    )

    print()
    print(
        f"[MODE] {mode}"
    )
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
# ASSINATURA DAS SOURCES
# ============================================================

def source_signature() -> str:
    digest = hashlib.sha256()

    for relative in MODULES:
        path = SRC / relative

        digest.update(
            relative.encode("utf-8")
        )

        if path.is_file():
            digest.update(
                path.read_bytes()
            )

        else:
            digest.update(
                b"<missing>"
            )

    digest.update(
        b"release"
        if "--release" in sys.argv
        else b"dev"
    )

    return digest.hexdigest()


# ============================================================
# WATCH
# ============================================================

def watch() -> None:
    mode = (
        "RELEASE"
        if "--release" in sys.argv
        else "DEV"
    )

    print(
        f"[WATCH] Modo {mode}"
    )

    print(
        f"[WATCH] Observando: {SRC}"
    )

    previous: str | None = None

    while True:
        try:
            current = source_signature()

            if current != previous:
                try:
                    build()
                    previous = current

                except Exception as exc:
                    print(
                        f"[ERRO] {exc}"
                    )

            time.sleep(
                0.35
            )

        except KeyboardInterrupt:
            print()

            print(
                "[WATCH] Encerrado."
            )

            return


# ============================================================
# MAIN
# ============================================================

def main() -> None:
    if "--watch" in sys.argv:
        watch()

    else:
        build()


if __name__ == "__main__":
    main()