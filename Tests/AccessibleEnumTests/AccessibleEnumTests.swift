import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import AccessibleEnumMacros

let testMacros: [String: Macro.Type] = [
    "enhanced": AccessibleEnumMacro.self,
]

final class EnhancedEnumTests: XCTestCase {

    func testInternalEnum() {
        assertMacroExpansion(
            """
            @enhanced
            enum Foo {
                case bar(String)
                case fooBar(Int)
            }
            """,
            expandedSource: """

            enum Foo {
                case bar(String)
                case fooBar(Int)
                enum Case {
                    case bar
                    case fooBar
                }
                func isCase(_ `case`: Case) -> Bool {
                    switch (self, `case`) {
                    case (.bar, .bar):
                        true
                    case (.fooBar, .fooBar):
                        true
                    default:
                        false
                    }
                }
                func associatedValue<T>() -> T? {
                    switch self {
                    case let .bar(val0):
                        return (val0) as? T
                    case let .fooBar(val0):
                        return (val0) as? T
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    func testPublicEnum() {
        assertMacroExpansion(
            """
            @enhanced
            public enum Foo {
                case bar(String)
                case fooBar(Int)
            }
            """,
            expandedSource: """

            public enum Foo {
                case bar(String)
                case fooBar(Int)
                public enum Case {
                    case bar
                    case fooBar
                }
                public func isCase(_ `case`: Case) -> Bool {
                    switch (self, `case`) {
                    case (.bar, .bar):
                        true
                    case (.fooBar, .fooBar):
                        true
                    default:
                        false
                    }
                }
                public func associatedValue<T>() -> T? {
                    switch self {
                    case let .bar(val0):
                        return (val0) as? T
                    case let .fooBar(val0):
                        return (val0) as? T
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    func testEnumMultipleAssociatedValues() {
        assertMacroExpansion(
            """
            @enhanced
            public enum Foo {
                case bar(String, Int)
                case fooBar(Int)
            }
            """,
            expandedSource: """

            public enum Foo {
                case bar(String, Int)
                case fooBar(Int)
                public enum Case {
                    case bar
                    case fooBar
                }
                public func isCase(_ `case`: Case) -> Bool {
                    switch (self, `case`) {
                    case (.bar, .bar):
                        true
                    case (.fooBar, .fooBar):
                        true
                    default:
                        false
                    }
                }
                public func associatedValue<T>() -> T? {
                    switch self {
                    case let .bar(val0, val1):
                        return (val0, val1) as? T
                    case let .fooBar(val0):
                        return (val0) as? T
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    func testEnumNoAssociatedValues() {
        assertMacroExpansion(
            """
            @enhanced
            public enum Foo {
                case bar
                case fooBar
            }
            """,
            expandedSource: """

            public enum Foo {
                case bar
                case fooBar
            }
            """,
            diagnostics: [
                .init(message: "The cases have no associated values, no need to apply this macro",
                      line: 1,
                      column: 1)
            ],
            macros: testMacros
        )
    }

    func testEnumNoSingleCase() {
        assertMacroExpansion(
            """
            @enhanced
            public enum Foo {
                case bar(String)
            }
            """,
            expandedSource: """

            public enum Foo {
                case bar(String)
                public enum Case {
                    case bar
                }
                public func isCase(_ `case`: Case) -> Bool {
                    switch (self, `case`) {
                    case (.bar, .bar):
                        true
                    }
                }
                public func associatedValue<T>() -> T? {
                    switch self {
                    case let .bar(val0):
                        return (val0) as? T
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    func testEnumMultipleCasesInSameLine() {
        assertMacroExpansion(
            """
            @enhanced
            enum Foo {
                case bar(String), fooBar(Int)
            }
            """,
            expandedSource: """

            enum Foo {
                case bar(String), fooBar(Int)
                enum Case {
                    case bar
                    case fooBar
                }
                func isCase(_ `case`: Case) -> Bool {
                    switch (self, `case`) {
                    case (.bar, .bar):
                        true
                    case (.fooBar, .fooBar):
                        true
                    default:
                        false
                    }
                }
                func associatedValue<T>() -> T? {
                    switch self {
                    case let .bar(val0):
                        return (val0) as? T
                    case let .fooBar(val0):
                        return (val0) as? T
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    func testEnumWithCaseAlreadyDeclared() {
        assertMacroExpansion(
            """
            @enhanced
            enum Foo {
                case bar(String)
                enum Case {}
            }
            """,
            expandedSource: """

            enum Foo {
                case bar(String)
                enum Case {
                }
            }
            """,
            diagnostics: [
                .init(message: "There is already an enum declaration with name Case already, remove or rename the declared enum.",
                      line: 1,
                      column: 1)
            ],
            macros: testMacros
        )
    }

    func testEnumWithMoreMembers() {
        assertMacroExpansion(
            """
            @enhanced
            public enum Foo {
                case bar(String)
                case fooBar(Int)

                var test: String {
                    "test"
                }

                func anotherTest() {
                }
            }
            """,
            expandedSource: """

            public enum Foo {
                case bar(String)
                case fooBar(Int)

                var test: String {
                    "test"
                }

                func anotherTest() {
                }
                public enum Case {
                    case bar
                    case fooBar
                }
                public func isCase(_ `case`: Case) -> Bool {
                    switch (self, `case`) {
                    case (.bar, .bar):
                        true
                    case (.fooBar, .fooBar):
                        true
                    default:
                        false
                    }
                }
                public func associatedValue<T>() -> T? {
                    switch self {
                    case let .bar(val0):
                        return (val0) as? T
                    case let .fooBar(val0):
                        return (val0) as? T
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    func testEmptyEnum() {
        assertMacroExpansion(
            """
            @enhanced
            enum Foo {}
            """,
            expandedSource: """

            enum Foo {
            }
            """,
            diagnostics: [
                .init(message: "The attached enum has no cases",
                      line: 1,
                      column: 1)
            ],
            macros: testMacros
        )
    }

    func testStruct() {
        assertMacroExpansion(
            """
            @enhanced
            struct Foo {}
            """,
            expandedSource: """

            struct Foo {
            }
            """,
            diagnostics: [
                .init(message: "@enhanced should only be attached to an enum declaration",
                      line: 1,
                      column: 1)
            ],
            macros: testMacros
        )
    }

    func testClass() {
        assertMacroExpansion(
            """
            @enhanced
            class Foo {}
            """,
            expandedSource: """

            class Foo {
            }
            """,
            diagnostics: [
                .init(message: "@enhanced should only be attached to an enum declaration",
                      line: 1,
                      column: 1)
            ],
            macros: testMacros
        )
    }
}
