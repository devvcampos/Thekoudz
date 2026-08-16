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
INFO_OUTPUT = DIST / "build-info.json"

MODULES = [
    "Main.lua",
    "Config.lua",
    "Ui.lua",
    "Library.lua",
    "Modules/ESP.lua",
    "Modules/Aimbot.lua",
    "Modules/AimProvider.lua",
    "Modules/DeadBodyChams.lua",
    "addons/ThemeManager.lua",
    "addons/SaveManager.lua",
]


# ============================================================
# BASIC HELPERS
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


def read_sources() -> dict[str, str]:
    sources: dict[str, str] = {}

    for relative in MODULES:
        path = SRC / relative

        if not path.is_file():
            raise FileNotFoundError(
                f"Arquivo não encontrado: {path}"
            )

        text = path.read_text(
            encoding="utf-8-sig"
        )

        if not text.strip():
            raise ValueError(
                f"Source vazia: {path}"
            )

        sources[relative] = text

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


def make_rng(
    build_id: str,
    domain: str,
) -> random.Random:
    seed = int(
        hashlib.sha256(
            (domain + ":" + build_id).encode("utf-8")
        ).hexdigest(),
        16,
    )

    return random.Random(seed)


def random_identifier(
    rng: random.Random,
    used: set[str],
    length: int = 13,
) -> str:
    rest = string.ascii_letters + string.digits + "_"

    while True:
        value = (
            "_"
            + rng.choice(string.ascii_letters)
            + "".join(
                rng.choice(rest)
                for _ in range(length - 2)
            )
        )

        if value not in used:
            used.add(value)
            return value


# ============================================================
# MODULE IDS / SOURCE REWRITE
# ============================================================

def make_module_ids(
    build_id: str,
) -> dict[str, int]:
    rng = make_rng(
        build_id,
        "module-ids-v5",
    )

    used: set[int] = set()
    result: dict[str, int] = {}

    for name in MODULES:
        while True:
            value = rng.randrange(
                100_000_000,
                2_000_000_000,
            )

            if value not in used:
                used.add(value)
                result[name] = value
                break

    return result


def rewrite_module_references(
    sources: dict[str, str],
    module_ids: dict[str, int],
) -> dict[str, str]:
    rewritten: dict[str, str] = {}

    for source_name, source in sources.items():
        updated = source

        for module_name, module_id in module_ids.items():
            replacement = str(module_id)

            updated = updated.replace(
                json.dumps(module_name),
                replacement,
            )

            updated = updated.replace(
                "'" + module_name + "'",
                replacement,
            )

        rewritten[source_name] = updated

    return rewritten


# ============================================================
# PAYLOAD ENCODING
# ============================================================

def make_stream_seed(
    build_id: str,
    module_id: int,
) -> int:
    digest = hashlib.sha256(
        (
            "stream-v5:"
            + build_id
            + ":"
            + str(module_id)
        ).encode("utf-8")
    ).digest()

    value = int.from_bytes(
        digest[:4],
        "big",
    ) & 0xFFFFFFFF

    return value or 0xA5A5A5A5


def xorshift32(
    value: int,
) -> int:
    value &= 0xFFFFFFFF
    value ^= (value << 13) & 0xFFFFFFFF
    value ^= (value >> 17) & 0xFFFFFFFF
    value ^= (value << 5) & 0xFFFFFFFF
    return value & 0xFFFFFFFF


def encode_source(
    source: str,
    seed: int,
) -> str:
    raw = source.encode("utf-8")

    state = seed
    out = bytearray()

    for byte in raw:
        state = xorshift32(
            state
        )

        out.append(
            byte ^ (state & 0xFF)
        )

    return base64.b64encode(
        bytes(out)
    ).decode("ascii")


def split_payload(
    payload: str,
    rng: random.Random,
) -> list[str]:
    if len(payload) <= 256:
        return [payload]

    chunks: list[str] = []
    index = 0

    while index < len(payload):
        width = rng.randint(
            180,
            420,
        )

        chunks.append(
            payload[
                index:index + width
            ]
        )

        index += width

    return chunks


# ============================================================
# INTEGRITY
# ============================================================

def adler32_bytes(
    data: bytes,
) -> int:
    mod = 65521
    a = 1
    b = 0

    for value in data:
        a = (a + value) % mod
        b = (b + a) % mod

    return (
        (b << 16)
        | a
    )


def source_metadata(
    source: str,
) -> tuple[int, int]:
    raw = source.encode("utf-8")

    return (
        len(raw),
        adler32_bytes(raw),
    )


# ============================================================
# DEV BUNDLE
# ============================================================

def generate_dev_bundle(
    sources: dict[str, str],
    build_id: str,
) -> str:
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


# ============================================================
# RELEASE V5
# ============================================================

def generate_release_bundle(
    sources: dict[str, str],
    build_id: str,
) -> str:
    module_ids = make_module_ids(
        build_id
    )

    rewritten = rewrite_module_references(
        sources,
        module_ids,
    )

    rng = make_rng(
        build_id,
        "wrapper-v5",
    )

    used: set[str] = set()

    # Core names
    n_payload = random_identifier(rng, used)
    n_seed = random_identifier(rng, used)
    n_length = random_identifier(rng, used)
    n_tag = random_identifier(rng, used)
    n_cache = random_identifier(rng, used)
    n_alpha = random_identifier(rng, used)
    n_b64 = random_identifier(rng, used)
    n_stream = random_identifier(rng, used)
    n_decode = random_identifier(rng, used)
    n_check = random_identifier(rng, used)
    n_join = random_identifier(rng, used)
    n_load = random_identifier(rng, used)

    # Locals
    n_data = random_identifier(rng, used)
    n_x = random_identifier(rng, used)
    n_r = random_identifier(rng, used)
    n_f = random_identifier(rng, used)
    n_i = random_identifier(rng, used)
    n_c = random_identifier(rng, used)
    n_state = random_identifier(rng, used)
    n_out = random_identifier(rng, used)
    n_raw = random_identifier(rng, used)
    n_id = random_identifier(rng, used)
    n_cached = random_identifier(rng, used)
    n_source = random_identifier(rng, used)
    n_chunk = random_identifier(rng, used)
    n_err = random_identifier(rng, used)
    n_ok = random_identifier(rng, used)
    n_result = random_identifier(rng, used)
    n_a = random_identifier(rng, used)
    n_b = random_identifier(rng, used)
    n_byte = random_identifier(rng, used)
    n_actual = random_identifier(rng, used)
    n_main = random_identifier(rng, used)
    n_parts = random_identifier(rng, used)

    module_order = list(MODULES)
    rng.shuffle(module_order)

    payload_entries: list[str] = []
    seed_entries: list[str] = []
    length_entries: list[str] = []
    tag_entries: list[str] = []

    for name in module_order:
        module_id = module_ids[name]

        seed = make_stream_seed(
            build_id,
            module_id,
        )

        encoded = encode_source(
            rewritten[name],
            seed,
        )

        chunk_rng = make_rng(
            build_id,
            "chunks:" + str(module_id),
        )

        chunks = split_payload(
            encoded,
            chunk_rng,
        )

        # Physical chunk order is shuffled, but each chunk keeps
        # an explicit numeric position so runtime reconstruction
        # remains deterministic.
        indexed_chunks = list(
            enumerate(
                chunks,
                start=1,
            )
        )

        chunk_rng.shuffle(
            indexed_chunks
        )

        chunk_table = (
            "{"
            + ",".join(
                f"[{index}]={json.dumps(chunk)}"
                for index, chunk in indexed_chunks
            )
            + "}"
        )

        length, tag = source_metadata(
            rewritten[name]
        )

        payload_entries.append(
            f"[{module_id}]={chunk_table}"
        )

        seed_entries.append(
            f"[{module_id}]={seed}"
        )

        length_entries.append(
            f"[{module_id}]={length}"
        )

        tag_entries.append(
            f"[{module_id}]={tag}"
        )

    payload_table = ",".join(
        payload_entries
    )

    seed_table = ",".join(
        seed_entries
    )

    length_table = ",".join(
        length_entries
    )

    tag_table = ",".join(
        tag_entries
    )

    main_id = module_ids[
        "Main.lua"
    ]

    # Split the Base64 alphabet into several literal fragments so
    # the wrapper layout differs from previous releases.
    alphabet = (
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "abcdefghijklmnopqrstuvwxyz"
        "0123456789+/"
    )

    alphabet_parts = [
        alphabet[:17],
        alphabet[17:39],
        alphabet[39:56],
        alphabet[56:],
    ]

    rng.shuffle(
        alphabet_parts
    )

    # We need original alphabet order at runtime, so store fragments
    # in an indexed table with physical declaration order shuffled.
    alphabet_indexed = list(
        enumerate(
            [
                alphabet[:17],
                alphabet[17:39],
                alphabet[39:56],
                alphabet[56:],
            ],
            start=1,
        )
    )

    rng.shuffle(
        alphabet_indexed
    )

    alpha_table = (
        "{"
        + ",".join(
            f"[{index}]={json.dumps(fragment)}"
            for index, fragment in alphabet_indexed
        )
        + "}"
    )

    # One of three equivalent loader layouts is selected
    # deterministically from the build id.
    loader_profile = rng.randrange(
        0,
        3,
    )

    prefix = (
        f"local {n_payload}={{{payload_table}}};"
        f"local {n_seed}={{{seed_table}}};"
        f"local {n_length}={{{length_table}}};"
        f"local {n_tag}={{{tag_table}}};"
        f"local {n_cache}={{}};"
        f"local {n_parts}={alpha_table};"
        f"local {n_alpha}=table.concat({n_parts});"
    )

    common = (
        f"local function {n_b64}({n_data})"
        f"{n_data}={n_data}:gsub(\"[^\"..{n_alpha}..\"=]\",\"\");"
        f"return({n_data}:gsub(\".\",function({n_x})"
        f"if {n_x}==\"=\" then return\"\" end;"
        f"local {n_r}=\"\";"
        f"local {n_f}=({n_alpha}:find({n_x},1,true)or 1)-1;"
        f"for {n_i}=6,1,-1 do "
        f"{n_r}={n_r}..({n_f}%2^{n_i}-{n_f}%2^({n_i}-1)>0 and\"1\"or\"0\");"
        f"end;"
        f"return {n_r};"
        f"end):gsub(\"%d%d%d?%d?%d?%d?%d?%d?\",function({n_x})"
        f"if #{n_x}~=8 then return\"\" end;"
        f"local {n_c}=0;"
        f"for {n_i}=1,8 do "
        f"if {n_x}:sub({n_i},{n_i})==\"1\" then "
        f"{n_c}={n_c}+2^(8-{n_i});"
        f"end;"
        f"end;"
        f"return string.char({n_c});"
        f"end));"
        f"end;"
        f"local function {n_stream}({n_state})"
        f"{n_state}=bit32.bxor({n_state},bit32.lshift({n_state},13));"
        f"{n_state}=bit32.bxor({n_state},bit32.rshift({n_state},17));"
        f"{n_state}=bit32.bxor({n_state},bit32.lshift({n_state},5));"
        f"return bit32.band({n_state},4294967295);"
        f"end;"
        f"local function {n_join}({n_data})"
        f"return table.concat({n_data});"
        f"end;"
        f"local function {n_decode}({n_data},{n_state})"
        f"local {n_raw}={n_b64}({n_join}({n_data}));"
        f"local {n_out}={{}};"
        f"for {n_i}=1,#{n_raw} do "
        f"{n_state}={n_stream}({n_state});"
        f"{n_out}[{n_i}]=string.char(bit32.bxor({n_raw}:byte({n_i}),bit32.band({n_state},255)));"
        f"end;"
        f"return table.concat({n_out});"
        f"end;"
        f"local function {n_check}({n_data})"
        f"local {n_a}=1;"
        f"local {n_b}=0;"
        f"for {n_i}=1,#{n_data} do "
        f"local {n_byte}={n_data}:byte({n_i});"
        f"{n_a}=({n_a}+{n_byte})%65521;"
        f"{n_b}=({n_b}+{n_a})%65521;"
        f"end;"
        f"return {n_b}*65536+{n_a};"
        f"end;"
    )

    if loader_profile == 0:
        loader = (
            f"local function {n_load}({n_id})"
            f"local {n_cached}={n_cache}[{n_id}];"
            f"if {n_cached}~=nil then return {n_cached} end;"
            f"local {n_source}={n_payload}[{n_id}];"
            f"assert({n_source}~=nil,\"modulo ausente\");"
            f"{n_source}={n_decode}({n_source},{n_seed}[{n_id}]);"
            f"assert(#{n_source}=={n_length}[{n_id}],\"payload truncado\");"
            f"assert({n_check}({n_source})=={n_tag}[{n_id}],\"payload corrompido\");"
            f"local {n_chunk},{n_err}=loadstring({n_source});"
            f"assert({n_chunk},{n_err});"
            f"local {n_ok},{n_result}=pcall({n_chunk});"
            f"assert({n_ok},{n_result});"
            f"assert({n_result}~=nil,\"modulo retornou nil\");"
            f"{n_cache}[{n_id}]={n_result};"
            f"return {n_result};"
            f"end;"
        )

    elif loader_profile == 1:
        loader = (
            f"local function {n_load}({n_id})"
            f"if {n_cache}[{n_id}]~=nil then return {n_cache}[{n_id}] end;"
            f"local {n_source}={n_payload}[{n_id}];"
            f"assert({n_source},\"modulo ausente\");"
            f"{n_source}={n_decode}({n_source},{n_seed}[{n_id}]);"
            f"local {n_actual}=#{n_source};"
            f"assert({n_actual}=={n_length}[{n_id}],\"payload truncado\");"
            f"{n_actual}={n_check}({n_source});"
            f"assert({n_actual}=={n_tag}[{n_id}],\"payload corrompido\");"
            f"local {n_chunk},{n_err}=loadstring({n_source});"
            f"assert({n_chunk},{n_err});"
            f"local {n_ok},{n_result}=pcall({n_chunk});"
            f"if not {n_ok} then error({n_result}) end;"
            f"assert({n_result}~=nil,\"modulo retornou nil\");"
            f"{n_cache}[{n_id}]={n_result};"
            f"return {n_cache}[{n_id}];"
            f"end;"
        )

    else:
        loader = (
            f"local function {n_load}({n_id})"
            f"local {n_cached}={n_cache}[{n_id}];"
            f"if {n_cached} then return {n_cached} end;"
            f"local {n_source}=assert({n_payload}[{n_id}],\"modulo ausente\");"
            f"{n_source}={n_decode}({n_source},{n_seed}[{n_id}]);"
            f"assert({n_length}[{n_id}]==#{n_source},\"payload truncado\");"
            f"local {n_actual}={n_check}({n_source});"
            f"assert({n_tag}[{n_id}]=={n_actual},\"payload corrompido\");"
            f"local {n_chunk},{n_err}=loadstring({n_source});"
            f"if not {n_chunk} then error({n_err}) end;"
            f"local {n_ok},{n_result}=pcall({n_chunk});"
            f"if not {n_ok} then error({n_result}) end;"
            f"assert({n_result}~=nil,\"modulo retornou nil\");"
            f"{n_cache}[{n_id}]={n_result};"
            f"return {n_result};"
            f"end;"
        )

    suffix = (
        f"local {n_main}={n_load}({main_id});"
        f"assert(type({n_main})==\"function\",\"entrypoint invalido\");"
        f"return {n_main}({n_load})"
    )

    return (
        prefix
        + common
        + loader
        + suffix
    )


# ============================================================
# BUILD WRAPPER
# ============================================================

def generate_bundle(
    sources: dict[str, str],
    build_id: str,
    release: bool,
) -> str:
    if release:
        return generate_release_bundle(
            sources,
            build_id,
        )

    return generate_dev_bundle(
        sources,
        build_id,
    )


# ============================================================
# BUILD INFO / VALIDATION
# ============================================================

def write_build_info(
    sources: dict[str, str],
    build_id: str,
    release: bool,
    bundle: str,
) -> None:
    info = {
        "build": build_id,
        "mode": (
            "RELEASE-V5"
            if release
            else "DEV"
        ),
        "module_count": len(MODULES),
        "bundle_sha256": hashlib.sha256(
            bundle.encode("utf-8")
        ).hexdigest(),
        "sources": {
            name: hashlib.sha256(
                content.encode("utf-8")
            ).hexdigest()
            for name, content in sorted(
                sources.items()
            )
        },
    }

    INFO_OUTPUT.write_text(
        json.dumps(
            info,
            indent=2,
            ensure_ascii=False,
        )
        + "\n",
        encoding="utf-8",
    )


def validate_bundle_text(
    bundle: str,
    release: bool,
) -> None:
    if not bundle.strip():
        raise RuntimeError(
            "Bundle gerado está vazio."
        )

    if release:
        forbidden = [
            "Modules/ESP.lua",
            "Modules/DeadBodyChams.lua",
            "Library.lua",
            "Config.lua",
            "Ui.lua",
            "__Decode",
            "__L",
            "AUTO-GENERATED FILE",
            "MODE:",
        ]

        leaks = [
            value
            for value in forbidden
            if value in bundle
        ]

        if leaks:
            raise RuntimeError(
                "Vazamento estrutural na RELEASE: "
                + ", ".join(leaks)
            )

        if len(bundle) < 1000:
            raise RuntimeError(
                "Bundle RELEASE pequeno demais."
            )

    else:
        if "Main.lua" not in bundle:
            raise RuntimeError(
                "Bundle DEV não contém o entrypoint."
            )


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

    validate_bundle_text(
        bundle,
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

    write_build_info(
        sources,
        build_id,
        release,
        bundle,
    )

    size_kb = (
        OUTPUT.stat().st_size
        / 1024
    )

    mode = (
        "RELEASE-V5"
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
        f"[INFO] {INFO_OUTPUT}"
    )
    print(
        f"[SIZE] {size_kb:.1f} KB"
    )

    return build_id


# ============================================================
# WATCH
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
        b"release-v5"
        if "--release" in sys.argv
        else b"dev"
    )

    return digest.hexdigest()


def watch() -> None:
    mode = (
        "RELEASE-V5"
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