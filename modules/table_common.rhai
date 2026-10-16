// Wire code tables, shared by every driver: `import "table_common" as t;`. A table is a map
// from the wire code, as text, to its option name, so a driver states each enum once and reads
// it both ways; several codes may share a name.

// The name of wire code `v`, or `()` for a code the table does not know.
fn name(table, v) { table[v.to_string()] }

// The lowest wire code named `name`, or `()`.
fn code(table, name) {
    let codes = table.keys().map(|k| k.parse_int());
    codes.sort();
    for k in codes { if table[k.to_string()] == name { return k; } }
    ()
}

// The distinct names of `table`, in wire-code order.
fn options(table) {
    let codes = table.keys().map(|k| k.parse_int());
    codes.sort();
    let out = [];
    for k in codes {
        let n = table[k.to_string()];
        if !out.contains(n) { out.push(n); }
    }
    out
}
