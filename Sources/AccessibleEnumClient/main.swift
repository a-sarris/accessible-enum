import AccessibleEnum

@AccessibleEnum
public indirect enum Foo {
    case bar(String)
    case fooBar(Int)
    case noValue
}

let value = Foo.fooBar(3)

let associated: Int? = value.associatedValue()

let isFooBar = value.isCase(.fooBar)

@AccessibleEnum
public enum Bar {
    case foo(String)
}
