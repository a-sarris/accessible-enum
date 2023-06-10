## AccessibleEnumMacro
A macro (Swift 5.9 only) that when attached to an `enum` declaration, adds additional functionality.
### Installation

- Add it as a Swift Package
- Add `AccessibleEnum` Library to your project

### Usage 

Attach `@AccessibleEnum` to an enum with multiple cases that have associated values.

```
@AccessibleEnum
public enum Foo {
    case bar(String)
    case fooBar(Int)
    case noValue
}
```

#### Allows determining the case

```
let value = Foo.fooBar(3)

let isFooBar = value.isCase(.fooBar)

```

#### Easier way to extract the associated value

```
let associated: Int? = value.associatedValue()
```

Inspired by [EnumKit](https://github.com/gringoireDM/EnumKit)
