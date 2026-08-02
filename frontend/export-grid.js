/**
 * Exporta el grid visible de una tabla HTML a CSV (compatible Excel).
 */
function downloadTableCsv(tableSelector, filename) {
  const table = document.querySelector(tableSelector);
  if (!table) return;

  const headers = [...table.querySelectorAll("thead th")]
    .map((th) => th.textContent.trim())
    .filter((h) => h.toLowerCase() !== "acciones");

  const rows = [];
  table.querySelectorAll("tbody tr").forEach((tr) => {
    const cells = [...tr.querySelectorAll("td")];
    if (!cells.length) return;
    // última columna suele ser Acciones: la omitimos si el thead tenía Acciones
    const take = headers.length;
    const values = cells.slice(0, take).map((td) => td.innerText.trim().replace(/\s+/g, " "));
    if (values.every((v) => !v) || values[0]?.includes("No hay")) return;
    rows.push(values);
  });

  if (!rows.length) {
    alert("No hay datos para descargar en el grid.");
    return;
  }

  const escapeCell = (v) => {
    const s = String(v ?? "");
    if (/[;"\n\r]/.test(s)) return `"${s.replace(/"/g, '""')}"`;
    return s;
  };

  const lines = [headers.map(escapeCell).join(";"), ...rows.map((r) => r.map(escapeCell).join(";"))];
  const blob = new Blob(["\uFEFF" + lines.join("\r\n")], {
    type: "text/csv;charset=utf-8;",
  });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  const stamp = new Date().toISOString().slice(0, 19).replace(/[:T]/g, "-");
  a.href = url;
  a.download = `${filename}_${stamp}.csv`;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}
