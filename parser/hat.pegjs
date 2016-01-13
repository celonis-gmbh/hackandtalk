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

start = 
  fex:
  (_
  (
    ("rows" _ lparen
        _ rows: (elist: ( expr (( _ comma e: expr ){ return e; }) * ) { return exprlist(elist); } )
        _ rparen _ ) { return rows}
  )  ?
  (
    ("cells" _ lparen
        _ cells: ( elist: ( agg_expr (( _ comma _ e: agg_expr ) { return e; }) * ) { return exprlist(elist); } )
        _ rparen _ ) {return cells}
  ) ?
  )
  {
    var rows = fex[1] || [];
    var cells = fex[2] || [];
    return piv.qry(rows, cells);
  }
  

value =
  v: ( _
       ( ( x: literal_value { return piv.con(x); } )
       / call_function
       / ( c: column_name { return piv.col(c) } )
       / ( _ lparen expr _ rparen ) ) )
  { return v[1] }


expr =
  e: ( _ value )
  { return e[1]; }


agg_expr =
  name: agg_name _ lparen _ e: expr _ rparen _ { return piv.agg(name, e); }

call_function =
  fn: ( function_name _ 
      lparen 
        ( _ elist: ( expr ( ( _ comma _ e:expr) { return e; } )* ) { return exprlist(elist); } )? 
      _ rparen
  ) { return piv.op(fn[0], fn[3]); }

literal_value =
  ( numeric_literal / string_literal )

numeric_literal =
  digits:( ( ( ( digit )+ ( decimal_point ( digit )+ )? )
           / ( decimal_point ( digit )+ ) ) )
  { var x = flatstr(digits);
    if (x.indexOf('.') >= 0) {
      return parseFloat(x);
    }
    return parseInt(x);
  }


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

digit = [0-9]
decimal_point = dot

name =
  str:[A-Za-z0-9_]+
  { return str.join('') }

column_name = name
function_name = name
agg_name = name

end_of_input = ''