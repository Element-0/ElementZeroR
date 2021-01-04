import {Artifact, Cmd, Transformer} from "Sdk.Transformers";

import {Runner} from "Ez.Helper";

namespace Project {
    const sqlite3src: StaticDirectory = importFrom("SQLite3.source").extracted;
    const sqlite3c = sqlite3src.contents.filter(x => x.name.toString().endsWith("sqlite3.c"))[0];
    const wd = d`${Context.getMount("output").path}`;
    function getFile(rel: RelativePath) : File {
        return f`${wd}\${rel}`;
    }
    const msdiaf: StaticDirectory = importFrom("MSDia.dll").extracted;
    const chakracoref: StaticDirectory = importFrom("ChakraCore.dll").extracted;
    const funchookf: StaticDirectory = importFrom("FuncHook.dll").extracted;
    export const msdiaPip = Transformer.copyFile(msdiaf.getFile("msdia140.dll"), getFile(r`msdia140.dll`).path, ["msdia"]);
    export const funchookPip = Transformer.copyFile(funchookf.getFile("funchook.dll"), getFile(r`funchook.dll`).path, ["funchook"]);
    export const chakraCorePip = Transformer.copyFile(chakracoref.getFile("x64_release/ChakraCore.dll"), getFile(r`ChakraCore.dll`).path, ["chakra_core"]);
    export const chakraCorePdbPip = Transformer.copyFile(chakracoref.getFile("x64_release/ChakraCore.pdb"), getFile(r`ChakraCore.pdb`).path, ["chakra_core"]);
    export const sqlite3Pip = Runner.ClangCl.compile({
        type: Runner.ClangCl.TargetType.dll,
        sources: [
            sqlite3c,
            f`src/sqlite3/sqlite3init.c`,
        ],
        target: getFile(r`sqlite3.dll`),
        tags: ["sqlite3"],

        arguments: [
            Cmd.argument("-m64"),
            Cmd.argument("-MD"),
            Cmd.argument("-O2"),
            Cmd.argument("-Qvec"),
            Cmd.argument("-Wno-deprecated-declarations"),
            Cmd.options(
                "-D",
                [
                    "SQLITE_API=__declspec(dllexport)",
                    "SQLITE_DQS=0",
                    "SQLITE_THREADSAFE=0",
                    "SQLITE_DEFAULT_MEMSTATUS=0",
                    "SQLITE_DEFAULT_WAL_SYNCHRONOUS=1",
                    "SQLITE_LIKE_DOESNT_MATCH_BLOBS=1",
                    "SQLITE_MAX_EXPR_DEPTH=0",
                    "SQLITE_OMIT_DEPRECATED",
                    "SQLITE_OMIT_PROGRESS_CALLBACK",
                    "SQLITE_OMIT_SHARED_CACHE",
                    "SQLITE_USE_ALLOCA",
                    "SQLITE_OMIT_AUTOINIT",
                    "SQLITE_OMIT_DEPRECATED",
                    "SQLITE_WIN32_MALLOC",
                    "SQLITE_ENABLE_FTS5",
                    "SQLITE_ENABLE_JSON1",
                    "SQLITE_ENABLE_RTREE",
                    "SQLITE_ENABLE_SNAPSHOT",
                    "SQLITE_DISABLE_LFS",
                    "SQLITE_DISABLE_DIRSYNC",
                ]
            ),
        ],
    });
    export const chakraPip = Runner.Nim.compile({
        type: Runner.Nim.ApplicationType.lib,
        source: f`src/chakra/chakra.nim`,
        target: getFile(r`chakra.dll`),
        tags: ["chakra"],
        dependencies: [
            chakraCorePip,
            funchookPip,
            sqlite3Pip.getOutputFile(getFile(r`sqlite3.dll`).path),
        ],
        arguments: [
            Cmd.option("--gc:", "orc"),
            Cmd.options("--passC:", ["/MD"]),
            Cmd.options("-d:", [
                    "chakra",
                    "useMalloc",
                    "noSignalHandler",
                ]),
        ],
    });
    export const pdbparserPip = Runner.Nim.compile({
        type: Runner.Nim.ApplicationType.console,
        source: f`src/pdbparser/parser.nim`,
        target: getFile(r`pdbparser.exe`),
        tags: ["pdbparser"],
        dependencies: [msdiaPip],
        arguments: [Cmd.option("--cincludes:", p`deps/include`)],
    });
    export const ezmgrPip = Runner.Nim.compile({
        type: Runner.Nim.ApplicationType.console,
        source: f`src/ezmgr/config.nim`,
        target: getFile(r`ezmgr.exe`),
        tags: ["ezmgr"],
    });
}