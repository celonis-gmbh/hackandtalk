// Some helper functions

{

  function append(arr, x) {
      arr[arr.length] = x;
      return arr;
  }

  function getstr(chars) {
      return chars.join('');
  }

  function flatten(x, rejectSpace, acc) {
    acc = acc || [];
    if (x == null || x == undefined) {
      if (!rejectSpace) {
        return append(acc, x);
      }
      return acc;
    }
    if (x.length == undefined) { // Just an object, not a string or array.
      return append(acc, x);
    }
    if (rejectSpace &&
        ((x.length == 0) ||
         (typeof(x) == "string" &&
          x.match(/^\s*$/)))) {
      return acc;
    }
    if (typeof(x) == "string") {
      return append(acc, x);
    }
    for (var i = 0; i < x.length; i++) {
      flatten(x[i], rejectSpace, acc);
    }
    return acc;
  }

  function flatstr(x, rejectSpace, joinChar) {
      return flatten(x, rejectSpace, []).join(joinChar || '');
  }

  function exprlist(elist) {
    if (elist.length == 0) {
      return [];
    } else if (elist.length == 1) {
      return [ elist[0] ];
    } else {
      var l = [elist[0]];
      for (var i = 0; i < elist[1].length; i++) {
        l.push(elist[1][i]);
      }
      return l;
    }
  }

}


// our goal: parse and execute the following query
// rows(FundCode)cells(count(1))
// How to do it:
// write rules on how to process the token stream and parse expressions
// general syntax: [rulename] = [ parseExpression ] { javascript return code }

// most simple case: a static string
start = "SAMPLE"

// 1) the first expression is taken as the "root" rule of the parser
/*
start = 
  "rows" _ lparen _ rparen _ "cells" _ lparen _ rparen _
*/

// 2) Allow for an argument list in the rows part
/*
start = 
  "rows" _ lparen _ expr ( _ comma expr ) * _ rparen _ "cells" _ lparen _ rparen

expr = 
  "PLACEHOLDER"
*/

// 3) Extend our expression to allow for column names
/*
start = 
  "rows" _ lparen _ expr ( _ comma expr ) * _ rparen _ "cells" _ lparen _ rparen

expr = 
  column_name
*/

// 4) Allow the cells part to contain aggregation functions
/*
start = 
  "rows" _ lparen _ expr ( _ comma _ expr ) * _ rparen _ "cells" _ lparen _ agg_expr ( _ comma _ agg_expr ) * _ rparen

expr = 
  column_name

agg_expr = 
  "AGGREGATION"
*/

// 5) Define our aggreagations expressions
/*
start = 
  "rows" _ lparen _ expr ( _ comma _ expr ) * _ rparen _ "cells" _ lparen _ agg_expr ( _ comma _ agg_expr ) * _ rparen

expr = 
  column_name

agg_expr =
 agg_name _ lparen _ expr _ rparen
*/


// 6)  Remove whitespace
/*
start = 
  "rows" _ lparen _ expr ( _ comma _ expr ) * _ rparen _ "cells" _ lparen _ agg_expr ( _ comma _ agg_expr ) * _ rparen

expr = 
  c: column_name
  { return c; }

agg_expr =
 a: agg_name _ lparen _  e: expr _ rparen
 { return [ a, e ]; }
*/

// 7) Remove whitespace and flatten argument list (in the full query)
/*
start = 
  "rows" _ lparen _ ( res: ( expr ( ( _ comma _ ees: expr ) { return ees; } ) * ) { return exprlist(res); } )_ rparen _ 
  "cells" _ lparen _ ( aggs: ( a: agg_expr as: ( ( _ comma _ aas: agg_expr ) { return aas; } ) * ) { return exprlist(aggs); } ) _ rparen

expr = 
  c: column_name
  { return c; }

agg_expr =
 a: agg_name _ lparen _  e: expr _ rparen
 { return [ a, e ]; }
*/


// 8) extract query arguments queries
/*
start =
   
  ( r: ("rows" _ lparen _ ( res: ( expr ( ( _ comma _ ees: expr ) { return ees; } ) * ) { return exprlist(res); } )_ rparen _ ) { return r[4]; } )
  ( c: ("cells" _ lparen _ ( aggs: ( a: agg_expr as: ( ( _ comma _ aas: agg_expr ) { return aas; } ) * ) { return exprlist(aggs); } ) _ rparen ) { return c[4]; } )

expr = 
  c: column_name
  { return c; }

agg_expr =
 a: agg_name _ lparen _  e: expr _ rparen
 { return [ a, e ]; }
*/


// 9) generate operators
/*
to create column operators, the hat engine provides a function piv.col(colname)
*/
/*
start = 
  ( r: ("rows" _ lparen _ ( res: ( expr ( ( _ comma _ ees: expr ) { return ees; } ) * ) { return exprlist(res); } )_ rparen _ ) { return r[4]; } )
  ( c: ("cells" _ lparen _ ( aggs: ( a: agg_expr as: ( ( _ comma _ aas: agg_expr ) { return aas; } ) * ) { return exprlist(aggs); } ) _ rparen ) { return c[4]; } )

expr = 
  c: column_name
  { return piv.col(c); }

agg_expr =
 a: agg_name _ lparen _  e: expr _ rparen
 { return [ a, e ]; }
*/

// 10) generate aggregate operators
/*
to create aggregate operators, the hat engine provides a function piv.agg(aggname, expression)
*/
/*
start = 
  ( r: ("rows" _ lparen _ ( res: ( expr ( ( _ comma _ ees: expr ) { return ees; } ) * ) { return exprlist(res); } )_ rparen _ ) { return r[4]; } )
  ( c: ("cells" _ lparen _ ( aggs: ( a: agg_expr as: ( ( _ comma _ aas: agg_expr ) { return aas; } ) * ) { return exprlist(aggs); } ) _ rparen ) { return c[4]; } )

expr = 
  c: column_name
  { return piv.col(c); }

agg_expr =
 a: agg_name _ lparen _  e: expr _ rparen
 { return piv.agg(a, e); }
*/

// 11) return a query object
/*
to create a query object, the hat engine provides a function piv.qry(rows, cells)
*/
/*
start = 
  qry: (
  ( r: ("rows" _ lparen _ ( res: ( expr ( ( _ comma _ ees: expr ) { return ees; } ) * ) { return exprlist(res); } )_ rparen _ ) { return r[4]; } )
  ( c: ("cells" _ lparen _ ( aggs: ( a: agg_expr as: ( ( _ comma _ aas: agg_expr ) { return aas; } ) * ) { return exprlist(aggs); } ) _ rparen ) { return c[4]; } )
  ) {
  	return piv.qry(qry[0], qry[1]);
  }

expr = 
  c: column_name
  { return piv.col(c); }

agg_expr =
 a: agg_name _ lparen _  e: expr _ rparen
 { return piv.agg(a, e); }
*/



// TOKENS
dot = '.'
lparen = '('
rparen = ')'
star = '*'
nil = ''
comma = ','

string_literal = '"' s: (escape_char / [^"])* '"' { return getstr(s); }
escape_char = '\\' .

_ =
  [ \t\n\r]*
__ =
  [ \t\n\r]+

binary_operator =
  x: ( _ ( '*' / '/' / '+' / '-' ) )
  { return x[1] }

digit = [0-9]
decimal_point = dot

name =
  str:[A-Za-z0-9_]+
  { return str.join('') }

column_name = name
function_name = name
agg_name = name

end_of_input = ''