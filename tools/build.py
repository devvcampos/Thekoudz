from __future__ import annotations

import base64
import hashlib
import json
import random
import string
import sys
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
DIST = ROOT / "dist"
OUTPUT = DIST / "Thekoudz.lua"

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


def make_rng(build_id: str) -> random.Random:
    seed = int(
        hashlib.sha256(
            ("v3:" + build_id).encode("utf-8")
        ).hexdigest(),
        16,
    )

    return random.Random(seed)


def random_identifier(
    rng: random.Random,
    used: set[str],
    length: int = 12,
) -> str:
    alphabet_rest = string.ascii_letters + "_" + string.digits

    while True:
        value = (
            "_"
            + rng.choice(string.ascii_letters)
            + "".join(
                rng.choice(alphabet_rest)
                for _ in range(length - 2)
            )
        )

        if value not in used:
            used.add(value)
            return value


def make_module_aliases(
    build_id: str,
) -> dict[str, str]:
    aliases: dict[str, str] = {}

    for index, name in enumerate(MODULES):
        digest = hashlib.blake2s(
            (
                build_id
                + "\0"
                + str(index)
                + "\0"
                + name
            ).encode("utf-8"),
            digest_size=8,
        ).hexdigest()

        aliases[name] = digest

    return aliases


def rewrite_module_references(
    sources: dict[str, str],
    aliases: dict[str, str],
) -> dict[str, str]:
    rewritten: dict[str, str] = {}

    for source_name, source in sources.items():
        updated = source

        for module_name, alias in aliases.items():
            updated = updated.replace(
                json.dumps(module_name),
                json.dumps(alias),
            )

            updated = updated.replace(
                "'" + module_name + "'",
                "'" + alias + "'",
            )

        rewritten[source_name] = updated

    return rewritten


def make_key(
    build_id: str,
) -> bytes:
    digest = hashlib.sha256(
        ("payload:" + build_id).encode("utf-8")
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


def generate_bundle(
    sources: dict[str, str],
    build_id: str,
    release: bool,
) -> str:
    if not release:
        parts: list[str] = []

        parts.append(
            "-- AUTO-GENERATED FILE\n"
            "-- DO NOT EDIT\n"
            f"-- BUILD: {build_id}\n"
            "-- MODE: DEV\n\n"
        )

        parts.append(
            "local __S = {\n"
        )

        for name in MODULES:
            source_literal = lua_long_string(
                sources[name]
            )

            parts.append(
                "    ["
                + json.dumps(name)
                + "] = "
                + source_literal
                + ",\n"
            )

        parts.append(
            "}\n\n"
        )

        parts.append(
            """local __C = {}

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

    local chunk, err = loadstring(source)

    assert(
        chunk,
        "Erro compilando "
            .. tostring(path)
            .. ": "
            .. tostring(err)
    )

    local ok, result = pcall(chunk)

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

local __Main = __L("Main.lua")

assert(
    type(__Main) == "function",
    "Main.lua precisa retornar uma funcao"
)

return __Main(__L)
"""
        )

        return "".join(parts)

    aliases = make_module_aliases(
        build_id
    )

    rewritten_sources = rewrite_module_references(
        sources,
        aliases,
    )

    rng = make_rng(
        build_id
    )

    used: set[str] = set()

    n_sources = random_identifier(rng, used)
    n_cache = random_identifier(rng, used)
    n_key = random_identifier(rng, used)
    n_b64 = random_identifier(rng, used)
    n_decode64 = random_identifier(rng, used)
    n_decode = random_identifier(rng, used)
    n_load = random_identifier(rng, used)
    n_path = random_identifier(rng, used)
    n_cached = random_identifier(rng, used)
    n_source = random_identifier(rng, used)
    n_chunk = random_identifier(rng, used)
    n_err = random_identifier(rng, used)
    n_ok = random_identifier(rng, used)
    n_result = random_identifier(rng, used)
    n_data = random_identifier(rng, used)
    n_x = random_identifier(rng, used)
    n_r = random_identifier(rng, used)
    n_f = random_identifier(rng, used)
    n_i = random_identifier(rng, used)
    n_c = random_identifier(rng, used)
    n_raw = random_identifier(rng, used)
    n_out = random_identifier(rng, used)
    n_key_index = random_identifier(rng, used)
    n_main = random_identifier(rng, used)

    key = make_key(
        build_id
    )

    module_order = list(MODULES)
    rng.shuffle(module_order)

    parts: list[str] = []

    parts.append(
        f"local {n_sources}={{"
    )

    for name in module_order:
        alias = aliases[name]

        encoded_source = encode_source(
            rewritten_sources[name],
            key,
        )

        parts.append(
            "["
            + json.dumps(alias)
            + "]="
            + json.dumps(encoded_source)
            + ","
        )

    parts.append(
        "};"
    )

    lua_key = ",".join(
        str(value)
        for value in key
    )

    parts.append(
        f"local {n_key}={{{lua_key}}};"
    )

    parts.append(
        f'local {n_b64}="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";'
    )

    parts.append(
        f"""local function {n_decode64}({n_data})
{n_data}={n_data}:gsub("[^"..{n_b64}.."=]","");
return({n_data}:gsub(".",function({n_x})
if {n_x}=="=" then return"" end;
local {n_r}="";
local {n_f}=({n_b64}:find({n_x},1,true)or 1)-1;
for {n_i}=6,1,-1 do
{n_r}={n_r}..({n_f}%2^{n_i}-{n_f}%2^({n_i}-1)>0 and"1"or"0");
end;
return {n_r};
end):gsub("%d%d%d?%d?%d?%d?%d?%d?",function({n_x})
if #{n_x}~=8 then return"" end;
local {n_c}=0;
for {n_i}=1,8 do
if {n_x}:sub({n_i},{n_i})=="1" then {n_c}={n_c}+2^(8-{n_i});end;
end;
return string.char({n_c});
end));
end;"""
    )

    parts.append(
        f"""local function {n_decode}({n_data})
local {n_raw}={n_decode64}({n_data});
local {n_out}={{}};
for {n_i}=1,#{n_raw} do
local {n_key_index}=(({n_i}-1)%#{n_key})+1;
{n_out}[{n_i}]=string.char(bit32.bxor({n_raw}:byte({n_i}),{n_key}[{n_key_index}]));
end;
return table.concat({n_out});
end;"""
    )

    parts.append(
        f"local {n_cache}={{}};"
    )

    parts.append(
        f"""local function {n_load}({n_path})
local {n_cached}={n_cache}[{n_path}];
if {n_cached}~=nil then return {n_cached} end;
local {n_source}={n_sources}[{n_path}];
assert({n_source}~=nil,"modulo ausente");
{n_source}={n_decode}({n_source});
local {n_chunk},{n_err}=loadstring({n_source});
assert({n_chunk},{n_err});
local {n_ok},{n_result}=pcall({n_chunk});
assert({n_ok},{n_result});
assert({n_result}~=nil,"modulo retornou nil");
{n_cache}[{n_path}]={n_result};
return {n_result};
end;"""
    )

    main_alias = aliases["Main.lua"]

    parts.append(
        f'local {n_main}={n_load}({json.dumps(main_alias)});'
    )

    parts.append(
        f'assert(type({n_main})=="function","entrypoint invalido");'
    )

    parts.append(
        f"return {n_main}({n_load})"
    )

    return "".join(parts)


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
        "RELEASE-V3"
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
        b"release-v3"
        if "--release" in sys.argv
        else b"dev"
    )

    return digest.hexdigest()


def watch() -> None:
    mode = (
        "RELEASE-V3"
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


def main() -> None:
    if "--watch" in sys.argv:
        watch()
    else:
        build()


if __name__ == "__main__":
    main()
