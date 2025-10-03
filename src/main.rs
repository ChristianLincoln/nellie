/*
Holy yap. So I need to rewrite nellie for bytecode, in Rust. Buns. Literal buns.

Well nellie is a list language in a way.
Every list is a 'statement' denoted by '()'
The stuff in the statement is then checked against... A H TREE!?!? no, not again. no.
It is checked against all the defined statements in a scope.
Then expanded by whatever the statement says really. Cool.

[expand [code] into (buns)]
[print (buns)]

source -> tokens[] -> statement... -> part
*/
use std::env;
use std::collections::HashMap;
use logos::{Lexer, Logos};
use std::fs;

// Something to do with logos recognising and 
#[derive(Debug, Logos)]
enum Token {
    #[token("[")]
    StatementOpen,
    #[token("]")]
    StatementClose,
    #[token("!")]
    ImmediateMarker,
    #[token("(")]
    ObjectOpen,
    #[token(")")]
    ObjectClose,
    #[token(":")]
    ClassMarker,
    #[token("{")]
    LiteralOpen,
    #[token("}")]
    LiteralClose,
    #[token("<")]
    IncludeOpen,
    #[token(">")]
    IncludeClose
}

pub enum Part {
    Statement(Statement), // Each '[]', another vector of parts
    Class(), // Each ''
    Immediate
}

pub enum Expansion {
    Function(),
    Format(String)
}

struct Statement {
    words: Vec<Part>
}

struct Definitions {

}

pub trait Evaluator {
    fn evaluate(&self, statement: Statement) -> Statement;
}

struct Scope {
    words: HashMap<String,Vec<>>;
}

impl Evaluator for Scope {
    fn evaluate(&self, statement: Statement) -> Statement {

    }
}

fn main() {
    let filename: String = env::args().nth(1).expect("Filename expected to process.");
    let src: String = fs::read_to_string(&filename).expect("Could not read file.");
    let mut lexer = Token::lexer(src.as_str());
    lexer;
}
