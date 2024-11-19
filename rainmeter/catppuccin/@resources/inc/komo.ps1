$output = komorebic state

if ($output -match 'float_identifiers') {
    komorebic stop
} else {
    komorebic start --whkd
}