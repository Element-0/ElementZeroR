config({
    resolvers: [
        {
            kind: "DScript",
            modules: [
                f`module.config.dsc`,
                f`Sdk/module.config.dsc`,
                f`${Environment.getPathValue("BUILDXL_BIN")}/Sdk/Sdk.Transformers/package.config.dsc`,
            ],
        },
        {
            kind: "Download",
            downloads: [
                {
                    moduleName: "SQLite3.source",
                    url: "https://www.sqlite.org/2020/sqlite-amalgamation-3340000.zip",
                    fileName: "sqlite3.zip",
                    archiveType: "zip",
                    hash: "VSO0:36EC0D32B5C188F6BA665E01D96D0E533C301F0CAD1F9EAAC5D00196D2B4872D00",
                },
                {
                    moduleName: "MSDia.dll",
                    url: "https://ipfs.io/ipfs/QmcjcskLLr1uKpNssH7im9dgM4tAubj9noUgfow6tR4QDH/msdia140.dll",
                    fileName: "msdia140.dll",
                    archiveType: "file",
                    hash: "VSO0:CD45B0DD8179638DB05D55388AEB22A562B0E475571659DF75C3FDC09601B3AF00"
                },
                {
                    moduleName: "ChakraCore.dll",
                    url: "https://aka.ms/chakracore/cc_windows_all_1_11_24",
                    fileName: "chakracore.zip",
                    archiveType: "zip",
                    hash: "VSO0:19D7152610F706853DD554322E807757D278ED4C10029932775A6C9973171A9C00"
                },
                {
                    moduleName: "FuncHook.dll",
                    url: "https://github.com/Element-0/Dependencies/releases/download/funchook-9f414f77ef504048e17836f3eb3455ca86a472b7/funchook.dll",
                    fileName: "funchook.dll",
                    archiveType: "file",
                    hash: "VSO0:B21FBBDA153631D90796D7F650E9A864741FAD01324A0AAF66B7D5542EBC237100"
                }
            ],
        }
    ],

    mounts: [
        {
            name: a`output`,
            path: p`dist`,
            trackSourceFileChanges: true,
            isWritable: true,
            isReadable: true,
        }
    ]
});