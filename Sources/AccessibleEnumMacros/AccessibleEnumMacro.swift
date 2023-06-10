import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

public struct AccessibleEnumMacro: MemberMacro {

    enum MacroError: Error, CustomStringConvertible {
        case notAttachedToAnEnum
        case noAssociatedValues
        case enumIsEmpty
        case internalEnumAlreadyDeclared

        var description: String {
            switch self {
            case .notAttachedToAnEnum:
                "@enhanced should only be attached to an enum declaration"
            case .enumIsEmpty:
                "The attached enum has no cases"
            case .internalEnumAlreadyDeclared:
                "There is already an enum declaration with name Case already, remove or rename the declared enum."
            case .noAssociatedValues:
                "The cases have no associated values, no need to apply this macro"
            }
        }
    }

    public static func expansion<Declaration, Context>(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context
    ) throws -> [SwiftSyntax.DeclSyntax] where Declaration : SwiftSyntax.DeclGroupSyntax, Context : SwiftSyntaxMacros.MacroExpansionContext {

        guard let enumDeclaration = declaration.as(
            EnumDeclSyntax.self
        ) else {
            throw MacroError.notAttachedToAnEnum
        }

        let modifier = makeModifier(
            enumDeclaration: enumDeclaration
        )

        let caseIdentifiers = extractCaseIdentifiers(
            enumDeclaration: enumDeclaration
        )

        guard !caseIdentifiers.isEmpty else {
            throw MacroError.enumIsEmpty
        }

        guard hasAssociatedTypes(enumDeclaration: enumDeclaration) else {
            throw MacroError.noAssociatedValues
        }

        guard hasNoCaseEnumAlreadyDeclared(enumDeclaration) else {
            throw MacroError.internalEnumAlreadyDeclared
        }

        let internalEnumDecl = try makeHelperEnum(
            modifier: modifier,
            caseIdentifiers: caseIdentifiers
        )

        let isFunctionDecl = try makeIsFunction(
            modifier: modifier,
            caseIdentifiers: caseIdentifiers
        )

        guard hasAssociatedTypes(enumDeclaration: enumDeclaration) else {
            return [
                internalEnumDecl,
                isFunctionDecl
            ]
        }

        let associatedValueFuncDecl = try makeAssociatedValueFuncDecl(enumDeclaration: enumDeclaration)

        return [
            internalEnumDecl,
            isFunctionDecl,
            associatedValueFuncDecl
        ]
    }

    private static func hasNoCaseEnumAlreadyDeclared(
        _ enumDeclaration: EnumDeclSyntax
    ) -> Bool {
        enumDeclaration
            .memberBlock
            .members
            .compactMap { $0.decl.as(EnumDeclSyntax.self) }
            .first { $0.identifier.text == "Case" } == nil
    }

    private static func makeModifier(enumDeclaration: EnumDeclSyntax) -> String {
        enumDeclaration
            .modifiers?
            .first { $0.as(DeclModifierSyntax.self)?.name.text == "public" } != nil ? "public " : ""
    }

    private static func extractCaseDeclarations(enumDeclaration: EnumDeclSyntax) -> [EnumCaseElementSyntax] {
        enumDeclaration.memberBlock.members
            .compactMap { $0.as(MemberDeclListItemSyntax.self)?.decl.as(EnumCaseDeclSyntax.self) }
            .flatMap { $0.elements }
    }

    private static func extractCaseIdentifiers(enumDeclaration: EnumDeclSyntax) -> [String] {
        extractCaseDeclarations(enumDeclaration: enumDeclaration)
            .map { $0.identifier.text }
    }

    private static func makeHelperEnum(modifier: String, caseIdentifiers: [String]) throws -> DeclSyntax {
        MemberDeclListItemSyntax(
            decl: try EnumDeclSyntax("\(raw: modifier)enum Case",
                                     membersBuilder: {
                                         for identifier in caseIdentifiers {
                                             DeclSyntax("case \(raw: identifier)")
                                         }
                                     }).with(\.leadingTrivia, "    ")
        ).decl
    }

    private static func makeIsFunction(modifier: String, caseIdentifiers: [String]) throws -> DeclSyntax {
        MemberDeclListItemSyntax(
            decl: try FunctionDeclSyntax("\(raw: modifier)func isCase(_ `case`: Case) -> Bool") {

                try SwitchExprSyntax("switch (self, `case`)") {
                    SwitchCaseListSyntax {
                        for identifier in caseIdentifiers {
                            .switchCase("case (.\(raw: identifier), .\(raw: identifier)): true")
                        }
                        if caseIdentifiers.count > 1 {
                            .switchCase("default: false")
                        }
                    }
                }
            }).decl
    }

    private static func hasAssociatedTypes(
        enumDeclaration: EnumDeclSyntax
    ) -> Bool {
        extractCaseDeclarations(enumDeclaration: enumDeclaration)
            .first {
                $0.associatedValue?.parameterList.isEmpty == false
            } != nil
    }

    private static func makeAssociatedValueFuncDecl(
        enumDeclaration: EnumDeclSyntax
    ) throws -> DeclSyntax {
        let modifier = makeModifier(enumDeclaration: enumDeclaration)
        let cases = extractCaseDeclarations(enumDeclaration: enumDeclaration)
        let casesCount = cases.count
        let expandedCases = cases
            .map {
                let paramCount = $0.associatedValue?.parameterList.count ?? 0
                let identifier = $0.identifier.text

                return (identifier, paramCount)
            }
            .filter { $0.1 > 0 }
            .map { caseInfo in
                let (identifier, paramCount) = caseInfo
                let values: [Int] = Array(0...(paramCount - 1))
                let mappedValues = values
                    .map { value in
                        return "val\(value)"
                    }
                    .joined(separator: ", ")

                return (identifier, "(\(mappedValues))")
            }.map {
                SwitchCaseListSyntax
                    .Element
                    .switchCase("case let .\(raw: $0.0)\(raw: $0.1): return \(raw: $0.1) as? T")

            }

        return MemberDeclListItemSyntax(
            decl: try FunctionDeclSyntax("\(raw: modifier)func associatedValue<T>() -> T?") {

                try SwitchExprSyntax("switch self") {
                    SwitchCaseListSyntax {
                        for expandedCase in expandedCases {
                            expandedCase
                        }
                        if casesCount > expandedCases.count {
                            .switchCase("default: return nil")
                        }
                    }
                }

            }).decl
    }

}

@main
struct EnumMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AccessibleEnumMacro.self,
    ]
}
