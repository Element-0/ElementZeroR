import {Tool, Artifact, Cmd, Transformer} from "Sdk.Transformers";

namespace Runner.Nim {
    @@public
    export const enum ApplicationType {
        console,
        gui,
        lib,
        staticlib,
    }
    @@public
    export interface Arguments extends Transformer.RunnerArguments {
        dependencies?: Array<File | StaticDirectory>;
        type: ApplicationType;
        source: File;
        target: File;
        arguments?: Argument[];
    }
    const nimTool: Transformer.ToolDefinition = {
        exe: f`${Environment.getPathValue("NIMPATH").path}`,
        dependsOnWindowsDirectories: true,
        prepareTempDirectory: true,

        untrackedDirectoryScopes: [
            Environment.getDirectoryValue("ProgramFiles"),
            Environment.getDirectoryValue("CHOOSENIM"),
            Environment.getDirectoryValue("NIMBLEPATH"),
            Environment.getDirectoryValue("ProgramData"),
            Environment.getDirectoryValue("VSINSTALLDIR"),
            Environment.getDirectoryValue("VCINSTALLDIR"),
            Environment.getDirectoryValue("WindowsSdkDir"),
        ],
    };
    function getAppType(type: ApplicationType) : Argument {
        switch (type) {
            case ApplicationType.console:
                return Cmd.option("--app:", "console");
            case ApplicationType.gui:
                return Cmd.option("--app:", "gui");
            case ApplicationType.lib:
                return Cmd.option("--app:", "lib");
            case ApplicationType.staticlib:
                return Cmd.option("--app:", "staticlib");
        };
    }
    @@public
    export function compile(args: Arguments) : DerivedFile {
        let wd = Context.getNewOutputDirectory(a`nim`);
        let tmp = Context.getTempDirectory(a`nim`);
        let tmpcache = Context.getTempDirectory(a`nimcache`);
        let tmpout = Context.getTempDirectory(a`nim-out`);
        let xtarget = p`${wd}/${args.target.name}`;
        let res = Transformer.execute({
            tool: args.tool || nimTool,
            tempDirectory: tmp,
            additionalTempDirectories: [
                tmpout,
                tmpcache,
            ],
            allowUndeclaredSourceReads: true,
            unsafe: {passThroughEnvironmentVariables: ["PATH"]},

            arguments: [
                Cmd.argument("cpp"),
                ...(args.arguments || []),
                Cmd.options("--passC:", [
                        "-m64",
                        "-Wno-duplicate-decl-specifier",
                        "-Wno-int-to-void-pointer-cast",
                        "-Wno-deprecated-declarations",
                    ]),
                getAppType(args.type),
                Cmd.option("--cc:", "clang_cl"),
                Cmd.option("--nimcache:", tmpcache.path),
                Cmd.option("--nimblePath:", Environment.getPathValue("NIMBLEPATH")),
                Cmd.option("-o:", Artifact.output(xtarget)),
                Cmd.argument(Artifact.input(args.source)),
            ],
            outputs: [
                wd,
                xtarget,
            ],
            dependencies: [
                args.source,
                ...(args.dependencies || []),
            ],
            workingDirectory: wd,
            tags: [
                "compile",
                "nim",
                ...args.tags,
            ],
        });

        return Transformer.copyFile(res.getOutputFile(xtarget), args.target.path);
    }
}