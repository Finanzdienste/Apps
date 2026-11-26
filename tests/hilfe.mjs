/* check() mit der Ausgabe „OK …“ / „FAIL …“ und am Ende die Zählung. */
export function pruefer() {
  let fails = 0;
  let oks = 0;
  const check = (c, m) => {
    console.log(`${c ? 'OK  ' : 'FAIL'} ${m}`);
    if (c) oks++; else { fails++; process.exitCode = 1; }
  };
  const ende = () => {
    console.log(`\n${oks} OK, ${fails} FAIL`);
    if (fails) process.exitCode = 1;
  };
  return { check, ende };
}
