import Foundation
import PackagePlugin

@main
final class SwiftFormatPlugin: BuildToolPlugin {
    enum Error: Swift.Error {
        case wrongTargetType
        case noSwiftFormatConfigFile
        case other
    }

    func createBuildCommands(context: PackagePlugin.PluginContext, target: PackagePlugin.Target) async throws -> [PackagePlugin.Command] {
        guard let target = target as? SwiftSourceModuleTarget else {
            throw Error.wrongTargetType
        }

        let arguments: [CustomStringConvertible]
        let packageConfigPath = context.package.directory.appending(".swiftformat").string
        if FileManager.default.fileExists(atPath: packageConfigPath) {
            arguments = [
                "--config", packageConfigPath
            ]
        } else {
            let rules = Constant.rules.prepareRules()
            let exclude = Constant.exclude.prepareExclude()
            let options = Constant.options.prepareOptions()
            arguments = [
                "--swiftversion", "5.6",
                "--rules", rules,
                "--exclude", exclude,
            ] + options
        }

        let blacklist = Constant.blacklist.prepareBlacklist()
        let tool = try context.tool(named: "swiftformat")
        let commands: [Command] = target
            .sourceFiles(withSuffix: ".swift")
            .compactMap {
                switch $0.type {
                case .source,
                        .header:
                    break
                case .resource,
                        .unknown:
                    return nil
                @unknown default:
                    return nil
                }

                if blacklist.contains($0.path.lastComponent) {
                    return nil
                }

                let filePath = $0.path
                return .prebuildCommand(displayName: "Processing \(filePath.lastComponent)",
                                        executable: tool.path,
                                        arguments: [
                                            filePath.string,
                                            "--cache", "ignore",
                                        ] + arguments,
                                        outputFilesDirectory: filePath)
            }
        return commands
    }
}

private extension String {
    func prepareBlacklist() -> [String] {
        return components(separatedBy: ",")
            .compactMap { rule in
                let rule = rule.replacingOccurrences(of: " ", with: "")
                return rule.hasPrefix("#") || rule.hasPrefix("-") ? nil : rule
            }
    }

    func prepareOptions() -> [String] {
        return components(separatedBy: "\n")
            .flatMap { option -> [String] in
                if option.hasPrefix("#") {
                    return []
                }

                guard let ind = option.firstIndex(of: " ") else {
                    return []
                }

                return [
                    String(option[..<ind]),
                    option[option.index(after: ind)...].components(separatedBy: " #").first.unsafelyUnwrapped
                ]
            }
    }

    func prepareExclude() -> String {
        return components(separatedBy: ",")
            .compactMap { rule in
                let rule = rule.replacingOccurrences(of: " ", with: "")
                return rule.hasPrefix("#") || rule.hasPrefix("-") ? nil : rule
            }
            .joined(separator: ",")
    }

    func prepareRules() -> String {
        return prepareBlacklist()
            .joined(separator: ",")
    }
}

private enum Constant {
    static let rules: String =
"""
# rules \
--rules \
# acronyms,\
andOperator,\
anyObjectProtocol,\
assertionFailures,\
blankLineAfterImports,\
blankLinesAroundMark,\
blankLinesAtEndOfScope,\
blankLinesAtStartOfScope,\
# blankLinesBetweenImports,\
blankLinesBetweenScopes,\
blockComments,\
braces,\
consecutiveBlankLines,\
consecutiveSpaces,\
docComments,\
duplicateImports,\
elseOnSameLine,\
emptyBraces,\
enumNamespaces,\
extensionAccessControl,\
fileHeader,\
genericExtensions,\
hoistPatternLet,\
indent,\
initCoderUnavailable,\
isEmpty,\
leadingDelimiters,\
linebreakAtEndOfFile,\
linebreaks,\
markTypes,\
modifierOrder,\
numberFormatting,\
opaqueGenericParameters,\
# organizeDeclarations,\
# preferDouble,\
preferKeyPath,\
redundantBackticks,\
redundantBreak,\
# redundantClosure,\
redundantExtensionACL,\
redundantFileprivate,\
redundantGet,\
redundantInit,\
redundantLet,\
redundantLetError,\
redundantNilInit,\
redundantObjc,\
redundantOptionalBinding,\
redundantParens,\
redundantPattern,\
redundantRawValues,\
# redundantReturn,\
redundantSelf,\
redundantType,\
redundantVoidReturnType,\
semicolons,\
sortDeclarations,\
sortedImports,\
sortedSwitchCases,\
spaceAroundBraces,\
spaceAroundBrackets,\
spaceAroundComments,\
spaceAroundGenerics,\
spaceAroundOperators,\
spaceAroundParens,\
spaceInsideBraces,\
spaceInsideBrackets,\
spaceInsideComments,\
spaceInsideGenerics,\
spaceInsideParens,\
# strongOutlets,\
strongifiedSelf,\
todos,\
trailingClosures,\
trailingCommas,\
trailingSpace,\
typeSugar,\
unusedArguments,\
void,\
# wrap,\
wrapArguments,\
wrapAttributes,\
wrapConditionalBodies,\
wrapEnumCases,\
# wrapMultilineStatementBraces,\
wrapSingleLineComments,\
wrapSwitchCases,\
yodaConditions
"""

    static let options: String =
"""
# options
--self init-only
--importgrouping testable-last
--commas inline
--trimwhitespace always
--indent 4
--ifdef no-indent
--wraparguments after-first
--wrapparameters after-first
--wrapcollections before-first
--wrapconditions after-first
--wrapreturntype preserve
--closingparen same-line #or balanced
--funcattributes prev-line
--typeattributes prev-line
--varattributes preserve
--extensionacl on-extension
--patternlet inline #or hoist
--elseposition same-line
--guardelse same-line
--emptybraces no-space
--indentcase false
--xcodeindentation true
--linebreaks lf
--decimalgrouping ignore
--binarygrouping ignore
--octalgrouping ignore
--hexgrouping ignore
--fractiongrouping disabled
--exponentgrouping disabled
--hexliteralcase uppercase
--exponentcase uppercase
--semicolons never
--operatorfunc no-space
--ranges no-space
--stripunusedargs unnamed-only #or always
--header strip
--marktypes never
--markextensions if-not-empty
--typemark "MARK: - %t"
--groupedextension "MARK: - %c"
--extensionmark "MARK: - %t + %c"
--redundanttype explicit
--typeblanklines remove
--allman false
--enumnamespaces always
--someAny true
--yodaswap always
"""

    static let exclude: String =
"""
--exclude Pods,\
Generated
"""

    static let blacklist: String =
"""
Package.swift
"""
}

/// reminder
//
/// wrap
// --maxwidth 80
// --wrapternary before-operators
//
/// comments
// --sortDeclarations
// Sorts the body of declarations with // swiftformat:sort and declarations # between // swiftformat:sort:begin and // swiftformat:sort:end comments.
