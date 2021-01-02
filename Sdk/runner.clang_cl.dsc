import {Tool, Cmd, Transformer} from "Sdk.Transformers";

namespace Runner.ClangCl {
    @@public
    export const enum TargetType {
        exe,
        dll,
    }
    @@public
    export interface Arguments extends Transformer.RunnerArguments {
        type: TargetType;
        sources: File[];
        target: File;
        arguments: Argument[];
    }
    function mapType(type: TargetType) : Argument[] {
        switch (type) {
            case TargetType.dll:
                return [Cmd.argument("/LD")];
            case TargetType.exe:
                return [];
        };
    }
    function mapOutput(type: TargetType, orig: Path) : Path[] {
        switch (type) {
            case TargetType.dll:
                return [orig, orig.changeExtension(".exp"), orig.changeExtension(".lib")];
            case TargetType.exe:
                return [orig];
        };
    }
    export const clangClTool: Transformer.ToolDefinition = {
        exe: f`${Environment.getPathValue("VCINSTALLDIR")}/Tools/Llvm/bin/clang-cl.exe`,
        dependsOnWindowsDirectories: true,
        prepareTempDirectory: true,
        untrackedDirectoryScopes: [
            Environment.getDirectoryValue("ProgramData"),
            Environment.getDirectoryValue("VSINSTALLDIR"),
            Environment.getDirectoryValue("VCINSTALLDIR"),
            Environment.getDirectoryValue("WindowsSdkDir"),
        ],
    };
    @@public
    export function compile(args: Arguments) : Transformer.ExecuteResult {
        let wd = Context.getNewOutputDirectory(a`clang-cl`);
        let tmp = Context.getTempDirectory(a`clang-cl`);
        return Transformer.execute({
            tool: args.tool || clangClTool,
            tempDirectory: tmp,
            allowUndeclaredSourceReads: true,
            unsafe: {
                passThroughEnvironmentVariables: [
                    "VSINSTALLDIR",
                    "VCINSTALLDIR",
                    "WindowsSDKLibVersion",
                    "WindowsSDKVersion",
                    "VisualStudioVersion",
                    "VS160COMNTOOLS",
                    "VCToolsRedistDir",
                    "VSCMD_ARG_HOST_ARCH",
                    "UCRTVersion",
                    "VCToolsVersion",
                    "VCIDEInstallDir",
                    "WindowsLibPath",
                    "VSCMD_ARG_TGT_ARCH",
                    "LIB",
                    "INCLUDE",
                    "WindowsSdkDir",
                    "VCToolsInstallDir",
                ]
            },
            arguments: [
                ...args.arguments,
                ...mapType(args.type),
                Cmd.option("/Fe", args.target.path),
                Cmd.files(args.sources),
            ],
            outputs: mapOutput(args.type, args.target.path),
            dependencies: [...args.sources],
            workingDirectory: wd,
            tags: [
                "compile",
                "clang_cl",
                ...args.tags,
            ],
        });
    }
}