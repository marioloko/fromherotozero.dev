+++
title = "Introduction to Rust Macros"
date = 2021-01-08
description = "My journey learning Rust macros. What are macros and how to use them."
+++

For some time now, I've been looking for a cool open source project where to contribute during my free time
and improve my programming skills in _Rust_. Sometimes I found a cool project, but I didn't
consider myself to have a good level to contribute in it, other times I found projects where I feel
myself confident but I didn't find the project challenging. This situation changed some months ago,
when I found the [Polars project](https://github.com/ritchie46/polars), a DataFrame manipulation 
project written in Rust, which focus on performing really fast.

During this time, I focused in the implementaion of parallel iterators using rayon, and in order to
avoid repeating my code once and again, I relied a lot on declarative macros. During this experience,
I can say that I improved quite a lot my skills with Rust macros and I really started to know their
potential, as well as their limitations. That's why today I am going to talk about _Rust declarative macros_.

This post starts as if the reader has zero knowledge about the usage of _declarative Macros_. Moreover,
the post will include links to other resources that I found useful during my learning experience.

## What Are Macros?

Macros, like functions, are tools to reuse code, but in contrast with functions, macro code is
expanded in the place where they are called, you can see this as if the macro code was copied at compilation
time from the macro declaration into the place where they are called. This is not really true, as macros in
Rust are not just text replacement, and do follow some rules when called, but the copy-paste definition
can help the reader to visualize better the differences between macros and functions. In addition,
macros are also less prohibitive than functions, as they are expanded in early compilation time,
before static checking.

## What Are Macros Useful For?

Macros are really useful in some situations:
1. When you want to implement the same functionality for different functions and structs, and solving
the problem with _generic types_ and _traits_ is cumbersome.
2. To implement tests with different input values.
3. To deal with enum type polymorphism, to unwrap the values or apply a function to its values.
4. When you want to implement slighly different structs with same behaviour.
Example: The same behaviour for tuples with one, two, three ... or twelve elements.

The drawback is that macros are generally harder to debug and to understand than functions, so it
is preferable to avoid them when posible to keep the code clean. However, it is important to notice,
for those people coming from C, that Rust macros are not just text replacement, but they are partially hygienic,
what implies that the variables inside the macro do not conflict with variables with the same name outside
the macro; moreover, metavariables are readed like a whole, if you have the expression `5 * $a` in your macro code,
and you call the macro with `$a = 5 + 3`, the macro is expanded as `5 * (5 + 3)`.
Check [Rust book](https://doc.rust-lang.org/1.7.0/book/macros.html#hygiene)
and [Rust Macro Book](http://danielkeep.github.io/tlborm/book/mbe-min-hygiene.html) for more info.

## Macro Metavariables

While functions only accept expressions as arguments, macros also accept other syntax tokens,
called metavariables. Among the available metavariables we can find:
- `literal`: A single literal. Ex: `True` or `"hello"`.
- `expr`: A programming expression. Ex: `2 + 2` or `foo(x, y, z)`. Function arguments accept expressions, then,
if you want to pass to a macro an argument that is also valid for a function, maybe `expr` is the way to go.
- `stmt`: A single statement. Ex: `let x = 3`.
- `block`: A programming block delimited by braces. Ex: `{ let x = 3; let y = 3 + x; 2 * y }`.
These metavariables can be really useful to write tests, as a block can be used to initialize the test with different input values,
and the body of the test can be the same, independently of the initialization block. Remember than in Rust,
the last element of a block can be returned.
- `lifetime`: Represent a Rust lifetime. Ex: `'a`.
- `ty`: Represent a type which is in the scope of the macro at the moment of calling. Ex: `i32` or `Vec<Option<&str>>`.
This metavariable cannot be used to create a new type inside the macro, but to use an existing one.
- `ident`: An identifier. Ex: `foo` or `my_var`. They are quite useful for macros that define and implement functions and structs,
they are used to name the functions and structs defined and implemented inside the macro.
You can use them in tests, to name the functions defining your tests with a slightly different name.

There are still more metavariables but I will not explain them all, if you are interested and want to
find more info you can look at the [Rust Reference Book](https://doc.rust-lang.org/reference/macros-by-example.html)
and the [Rust Book](https://doc.rust-lang.org/1.7.0/book/macros.html).

## How Are Macros Used In Rust?

Macros in Rust are used like functions, but they include an `!` at the end of the name.
You may have seen macros like `println!("Hello {}!", name)`, `vec![0, 1, 2, 3]` or
`c![x*x, for x in 0..10, if x % 2 == 0]`. As you can see the different macros can have different syntaxes,
the first one uses a function like syntax, using parenthesis; the second one uses array like syntax,
using square brackets; and the last one uses python comprehesion list like syntax.
If you are interested in the macro for comprehesion list in Rust you should take a look at [cute](https://docs.rs/cute/0.3.0/cute/).
Rust macros are that powerful that allow us to define our own syntax for the macros, however I
recommend you to stick with function like syntax in most of the cases, as it is easier to see and understand the arguments.

## How Are Macros Defined?

### Macro Rules

Let's continue by explaining how declarative macros are defined, they are defined using the macro 
`macro_rules!`. I will use a simplified version of [cute](https://docs.rs/cute/0.3.0/cute/), as example:

```rust
macro_rules! c {

    ($exp:expr, for $i:ident in $iter:expr) => {
        {
            let mut r = vec![];
            for $i in $iter {
                r.push($exp);
            }
            r
        }
    };

    ($exp:expr, for $i:ident in $iter:expr, if $cond:expr) => {
        {
            let mut r = vec![];
            for $i in $iter {
                if $cond {
                    r.push($exp.clone());
                }
            }
            r
        }
    };

}
```

In the previous example we can see that a macro is defined as _match_ statements,
they can have one or more branches, and when we call a macro, they are going to use the first branch 
that matches our arguments.
Ex: The previous macro can be called without a condition `c!(x*x, for x in list)`, in that case it will match
the first branch; or with a condition `c!(x*x, for x in list, if x > 10)`, in that case it will
match the second branch. Also it is important to say that it is indiferent if, during macro invocation, 
we use parenthesis, square brackets, or curly brackets, so we could have used `c![x*x, for x in list]` 
or `c!{x*x, for x in list}` instead.

Basically for each branch, we define, in between parenthesis, the arguments and tokens that the
macro accepts. The input arguments start with `$` sign, then, for the macro in the example above,
`exp`, `i`, `iter` and `cond` are macro arguments;
while the commas and the `for` and `if` are just fixed tokens, they are used to help the user understand
what he is doing, and to help the compiler decide which branch to use. Moreover,
in between curly brackets we define the body of the macro, where the macro metavariables, when used,
are preceded by the `$` sign.

### Macros 2.0

In addition, there is still another way to create declarative macros, if you are using Rust
nightly version, and your macro has only one brace, maybe you want to give a try to Macros 2.0.
They are still an unstable feature and they are under development, but you can activate them with the feature 
`#![feature(decl_macro)]`. In my opinion, one of the main advantages of these macros is that it is easier 
to deal with the visibility of the macro, its visibility is changed with the `pub` keyword, the same way as functions do. The
`macro_rules!` macros visibility can be changed with the `#[macro_use]` attribute. The drawback of
`#[macro_use]` is that the imported macros are stored in the root of the crate. However, with Macros 2.0,
the macros are kept in the module they are defined, and they can be imported with the `use` keyword,
just like functions. If you are interested in Macros 2.0 you can look for more information
[here](https://github.com/rust-lang/rust/issues/39412). An example of macros 2.0 can be found below:

```rust
#![feature(decl_macro)]

/// Macro which creates just one test with the name given as argument.
pub macro impl_test($name:ident) {
    #[test]
    fn $name() {
        println!("This test always succeeds");
    }
}
```

During this post I will stick with `macro_rules!` because, at the moment of writing this,
they are the only ones supported by stable Rust.

### Macros With Variable Number Of Arguments

One of the advantages of Rust macros over functions, is that while functions do not accept a variable
number of arguments or optional arguments, macros do. An example of a macro which uses a variable
number of arguments is the `vec!` macro, which accept zero or more arguments.

```rust
macro_rules! vec {
    ( $( $x:expr ),* ) => {
        {
            let mut temp_vec = Vec::new();
            $(
                temp_vec.push($x);
            )*
            temp_vec
        }
    };
}
```

The `$( $x:expr ),*` in the arguments means that it accepts zero or more macros separated by
commas. Then, in the macro body they are used with `$( temp_vec.push($x); )*`, which will repeat
the content in between the `$( ... )*` as many times as expresions are received in the argument list.
Ex: `vec![3, 4];` would be expanded as `temp_vec.push(3); temp_vec.push(4);`.

If instead of multiple arguments we just want an optional argument that can be given as input either
zero or one time, we should use `$( ... )?` instead of `$( ... )*`.

```rust
use std::marker::PhantomData;

macro_rules! impl_my_new_struct {
    (
        $name:ident
        $(
            , lifetime = $lt:lifetime
        )?
    ) => {
        struct $name<$( $lt )?> {
            $( phantom: PhantomData<&$lt str>, )?
        }
    };
}
```

The example above creates a dummy struct with an optional lifetime, this way we can create the struct without
lifetime `impl_my_new_struct!(Dummy)` or with lifetime `impl_my_new_struct!(Dummy, lifetime = 'a)`. There is no
need to define our macro with `lifetime =` for optional arguments, however, I find the python way more
readable for optional arguments.

In Rust macros, the order of argument matters, which means that if you declare several optional arguments, 
Ex: `($name:ident $(, lifetime = $lt:lifetime) $(, opt = $opt:ident))`, the optional argument `lifetime`, if used,
shall be always called before `opt`.

### Macro Recursion

Finally, it is important to talk about macro recursion. Macros, as well as functions, can be called recursively
and they will be expanded at compile time. Looking on the Internet I found the crate
[crunchy](https://docs.rs/crunchy/0.1.6/crunchy/), which basically unrolls loops using macro recursion.
I encourage you to look at its [source code](https://docs.rs/crunchy/0.1.6/src/crunchy/home/cratesfyi/cratesfyi/debug/build/crunchy-c49306e9952d1d33/out/lib.rs.html#24-780)
to understand better how macro recursion works. Below you can find an example of macro recursion,
it is a simplified version of the crunchy unroll macro, which only accepts up to 3 elements in the for loop,
just for learning reasons.

```rust
#[macro_export]
macro_rules! unroll {
    // 1. Base case.
    (for $v:ident in 0..0 $c:block) => {};

    // 2. Recursive case.
    (for $v:ident in 0..$b:tt {$($c:tt)*}) => {
        { unroll!(@$v, 0, $b, {$($c)*}); }
    };

    // 3. Base case.
    (@$v:ident, $a:expr, 1, $c:block) => {
        { const $v: usize = $a; $c }
    };

    // 4. Recursive case.
    (@$v:ident, $a:expr, 2, $c:block) => {
        { unroll!(@$v, $a, 1, $c }
        { unroll!(@$v, $a + 1, 1, $c }
    };

    // 5. Recursive case.
    (@$v:ident, $a:expr, 3, $c:block) => {
        { unroll!(@$v, $a, 2, $c }
        { unroll!(@$v, $a + 2, 1, $c }
    };
}
```

The first thing that we can notice is that the macro has several branches. It is important because
recursive macros shall have at least one branch that is a base case and does not have recursion.
The second thing that we notice is that some of them starts with `for` and other with `@`, the reason
is that macro branches cannot have private visibility, then, the one who developed this macro decided to use `for`
for the public interface and `@` for the private interface, which can be useful to prevent other
developers to use branches of the macro that should not be used by them. In case that you develop a
public and  a private interface you should at least create documentation for the public branches.

Now let's explain the example above, branch by branch:
1. It is a base case for a loop with 0 elements. It belongs to the public interface.
In this case we expect to do nothing, then, an empty block is returned.
2. It is a recursive case for a loop with more than 1 elements. It belongs to the public interface.
In this case it will call recursively the same function, using the private branches.
The called private branch is the one whose third element is equal to `$b`, where `$b` can be a number between 1 and 3.
3. It is a base case for a loop which unrolls 1 element. It belongs to the private interface.
It executes the block `$c`, with the index passed to `$a` stored in variable `$v`.
4. It is a recursive case for a loop which unrolls 2 elements. It belongs to the private interface.
It calls the branch number 3 two times, one with the current index and other with the following index,
this way it unrolls 1 elements in each recursive call.
5. It is a recursive case for a loop which unrolls 3 elements. It belongs to the private interface. 
It calls the branch number 4 and 3 one time, one with the current index and other with two indexes ahead.
This way it unrolls 2 elements in the first recursive call and 1 in the other.

At this point, you may be wondering why we did not define something like this:

```rust
// THIS EXAMPLE DOES NOT WORK.
macro_rules! unroll {
    (for $v:ident in 0..0 $c:block) => {};

    (for $v:ident in 0..$b:tt {$($c:tt)*}) => {
        { const $v: usize = $a; $c }
        { unroll!(for $v in ($b - 1) {$($c)*}); }
    };
}
```

The reason why this example does not work is because expression `$b - 1` is not evaluated at macro
expansion time, so it will never reach the base case where `$b - 1 = 0`. It will be expanded infinitely to
`(((((($b - 1) - 1) - 1) - 1) - 1) ...)`. Then, be careful with macro expresions expansion when dealing
with recursive macros.
Check this [stack overflow question](https://stackoverflow.com/questions/33751796/is-there-a-way-to-count-with-macros) for more info.

### Macro Visibility

Maybe, you have also notice the macro attribute `#[macro_export]`. Macros, by default are visible just
in the module they are declared. If you define the macro in one module and you want to use
the macro in another, then, you can use the macro by importing the module defining the
macro with the `#[macro_use]` macro attribute.

However, if you want to use the macro in a different crate, you shall export this macro. In order
to export the macro we use the `#[macro_export]` macro attribute. This way, you can use the macro
by importing the crate containing the macro with `#[macro_use]`. However, notice
that imported macros are stored at the root of the imported crate, and not at the module level.

## Conclusion

In this post I introduced the Rust macros, what can they offer and how to use them with several examples.

In the next one I will talk about how I used declarative macros in the [Polars project](https://github.com/ritchie46/polars),
what problems I faced and how I solved them.

See you in the next post! :D
