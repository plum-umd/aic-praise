parser grammar RuleParser;

options {

    // Default language but name it anyway
    //
    language  = Java;

    // Produce an AST
    //
    output    = AST;

    // Use the vocabulary generated by the accompanying
    // lexer. Maven knows how to work out the relationship
    // between the lexer and parser and will build the 
    // lexer before the parser. It will also rebuild the
    // parser if the lexer changes.
    //
    tokenVocab = RuleLexer;
    
    ASTLabelType = CommonTree;
    
    backtrack = true;
    memoize = true;
}

tokens {
    POTENTIALEXPRESSION1 ;
    POTENTIALEXPRESSION2 ;

    CONDITIONALEXPRESSION1 ;
    CONDITIONALEXPRESSION2 ;

    PROLOGEXPRESSION1 ;
    PROLOGEXPRESSION2 ;
    PROLOGEXPRESSION3 ;
    PROLOGEXPRESSION4 ;

    STANDARDPROBABILITYEXPRESSION ;
    CAUSALEXPRESSION ;

    THEREEXISTS ;
    FORALL ;
    MAYBESAMEAS ;

    SET ;
    FUNCTION ;
    KLEENE ;
    SYMBOL ;
    
    CONJUNCTION ;
}


@header {

    package com.sri.ai.praise.rules.antlr;
}


@members {

/** Makes parser fail on first error. */
@Override
public Object recoverFromMismatchedSet(IntStream input, RecognitionException e, BitSet follow)
    throws RecognitionException {
    throw e;
    //return null;
}

/** Makes parser fail on first error. */
protected Object recoverFromMismatchedToken(IntStream input, int ttype, BitSet follow)
    throws RecognitionException {
    throw new MismatchedTokenException(ttype, input);
}
}

// Alter code generation so catch-clauses get replace with this action.
@rulecatch {
catch (RecognitionException e) { throw e; }
}

start 
    : model* EOF!
//    : model EOF!
    ;


model
    : random_variable_decl SEMICOLON!
    | sort_decl SEMICOLON!
    | rule
    ;

random_variable_decl
    : RANDOM atomic_symbol COLON SINGLE_ARROW atomic_symbol                                    -> ^(RANDOM atomic_symbol+)
    | RANDOM atomic_symbol COLON atomic_symbol SINGLE_ARROW atomic_symbol                      -> ^(RANDOM atomic_symbol+)
    | RANDOM atomic_symbol COLON atomic_symbol ( X atomic_symbol )+ SINGLE_ARROW atomic_symbol -> ^(RANDOM atomic_symbol+)
    ;

sort_decl
    : SORT atomic_symbol COLON atomic_symbol COMMA kleene1 -> ^(SORT atomic_symbol+ ^(SET kleene1))
    | SORT atomic_symbol COLON atomic_symbol               -> ^(SORT atomic_symbol+ ^(SET ^(KLEENE)))
    | SORT a=atomic_symbol                                 -> ^(SORT atomic_symbol ^(SYMBOL ID["Unknown"]) ^(SET ^(KLEENE)))
    ;

rule
    : rule_conjunction SEMICOLON!
    ;

rule_conjunction
    : raw_rule (AND raw_rule)+ -> ^(CONJUNCTION raw_rule+)
    | raw_rule -> raw_rule
    ;

raw_rule
    : prolog_rule
    | conditional_rule
    | standard_probability_rule
    | causal_rule
    | atomic_rule
    | OPEN_PAREN! rule_conjunction CLOSE_PAREN!
    ;

prolog_rule
    : formula PERIOD                              -> ^(PROLOGEXPRESSION1 formula)
    | formula COLON_DASH formula PERIOD           -> ^(PROLOGEXPRESSION2 formula+)
    | potential formula PERIOD                    -> ^(PROLOGEXPRESSION3 potential formula)
    | potential formula COLON_DASH formula PERIOD -> ^(PROLOGEXPRESSION4 potential formula+)
    ;

conditional_rule
    : IF formula THEN rule_conjunction ELSE rule_conjunction -> ^(CONDITIONALEXPRESSION2 formula rule_conjunction+)
    | IF formula THEN rule_conjunction                       -> ^(CONDITIONALEXPRESSION1 formula rule_conjunction)
    ;

atomic_rule
    : formula potential -> ^(POTENTIALEXPRESSION2 formula potential)
    | formula           -> ^(POTENTIALEXPRESSION1 formula)
    ;

standard_probability_rule
    : P OPEN_PAREN formula VERT_BAR formula CLOSE_PAREN EQUAL potential -> ^(STANDARDPROBABILITYEXPRESSION formula+ potential)
    ;

causal_rule
    : formula SINGLE_ARROW rule_conjunction -> ^(CAUSALEXPRESSION formula rule_conjunction)
    ;

//=============================
// FORMULA
//=============================
formula
    : leg
    ;

leg
    : eg (DOUBLE_ARROW^ eg)*
    ;

eg
    : exists (ARROW^ exists)*
    ;

exists
    : THERE EXISTS a=exists COLON b=exists -> ^(THEREEXISTS $a $b)
    | forall
    ;

forall
    : FOR ALL a=forall COLON b=forall -> ^(FORALL $a $b)
    | and
    ;

and
    : or (AND^ or)*
    ;

or
    : not (OR^ not)*
    ;

not
    // Using "not" instead of expected "term" so that we can support cases like "not not x".
    : NOT^ not
    | term
    ;

//=============================
// TERM
//=============================
term
    : plus
    ;

plus
    : dash (PLUS^ dash)*
    ;

dash
    : minus (DASH^ minus)*
    ;

minus
    : multiply (MINUS^ multiply)*
    ;

multiply
    : divide (TIMES^ divide)*
    ;

divide
    : carat (DIVIDE^ carat)*
    ;

carat
    : negative (CARAT^ negative)*
    ;

negative
    // Using "negative" instead of expected "atomic_symbol" so that we can support cases like "--x".
    : DASH^ negative
    | equal
    ;

equal
    : notequal (EQUAL^ notequal)*
    ;

notequal
    : maybesame (NOT_EQUAL^ maybesame)*
    ;

maybesame
    : function MAY BE SAME AS function -> ^(MAYBESAMEAS function+)
    | function
    ;

function
    : atomic_symbol OPEN_PAREN (term ( COMMA term )*)? CLOSE_PAREN  -> ^(FUNCTION atomic_symbol term*)
    | atomic_symbol
    ;


//=============================
// POTENTIAL
//=============================
potential
    : term   // term accepts more than potential needs, but this will work.
    ;




//=============================
// SYMBOL
//=============================
atomic_symbol
    : ARROW                -> ^(SYMBOL ID[$ARROW.text])
    | SINGLE_ARROW         -> ^(SYMBOL ID[$SINGLE_ARROW.text])
    | DOUBLE_ARROW         -> ^(SYMBOL ID[$DOUBLE_ARROW.text])
    | OR                   -> ^(SYMBOL ID[$OR.text])
    | AND                  -> ^(SYMBOL ID[$AND.text])
    | EQUAL                -> ^(SYMBOL ID[$EQUAL.text])
    | NOT_EQUAL            -> ^(SYMBOL ID[$NOT_EQUAL.text])
    | X                    -> ^(SYMBOL ID[$X.text])
    | PLUS                 -> ^(SYMBOL ID[$PLUS.text])
    | DASH                 -> ^(SYMBOL ID[$DASH.text])
    | MINUS                -> ^(SYMBOL ID[$MINUS.text])
    | TIMES                -> ^(SYMBOL ID[$TIMES.text])
    | DIVIDE               -> ^(SYMBOL ID[$DIVIDE.text])
    | CARAT                -> ^(SYMBOL ID[$CARAT.text])
    | NOT                  -> ^(SYMBOL ID[$NOT.text])
    | P                    -> ^(SYMBOL ID[$P.text])
//    | IF                   -> ^(SYMBOL ID[$IF.text])
//    | THEN                 -> ^(SYMBOL ID[$THEN.text])
//    | ELSE                 -> ^(SYMBOL ID[$ELSE.text])
//    | SORT                 -> ^(SYMBOL ID[$SORT.text])
//    | RANDOM               -> ^(SYMBOL ID[$RANDOM.text])
//    | THERE                -> ^(SYMBOL ID[$THERE.text])
//    | EXISTS               -> ^(SYMBOL ID[$EXISTS.text])
//    | FOR                  -> ^(SYMBOL ID[$FOR.text])
//    | ALL                  -> ^(SYMBOL ID[$ALL.text])
//    | MAY                  -> ^(SYMBOL ID[$MAY.text])
//    | BE                   -> ^(SYMBOL ID[$BE.text])
//    | SAME                 -> ^(SYMBOL ID[$SAME.text])
//    | AS                   -> ^(SYMBOL ID[$AS.text])
    | atom
    ;



atom
    : ID -> ^(SYMBOL ID)
    | STRING -> ^(SYMBOL ID[$STRING.text])
    | OPEN_PAREN! formula CLOSE_PAREN!
    ;



//set
//    : OPEN_CURLY kleene CLOSE_CURLY -> ^(SET kleene)
//    ;


// For cases where you need 0 or more items in the kleene
kleene
    : (atomic_symbol ( COMMA atomic_symbol )+)? -> ^(KLEENE atomic_symbol*)
    | atomic_symbol
    ;

// For cases where you need 1 or more items in the kleene
kleene1
    : atomic_symbol ( COMMA atomic_symbol )+ -> ^(KLEENE atomic_symbol*)
    | atomic_symbol -> atomic_symbol
    ;


