import { LightningElement, api } from 'lwc';

/**
 * Tabla de resultados PDX: envuelve lightning-datatable y añade exportar CSV
 * y re-emisión de acciones por fila (brief §3: tabla + exportar + acciones).
 */
export default class PdxDataTable extends LightningElement {
    @api columns = [];
    @api records = [];
    @api keyField = 'id';
    @api enableExport = false;
    @api exportFilename = 'export.csv';

    handleRowAction(event) {
        this.dispatchEvent(
            new CustomEvent('rowaction', {
                detail: { action: event.detail.action, row: event.detail.row }
            })
        );
    }

    exportCsv() {
        const cols = (this.columns || []).filter((c) => c.fieldName);
        const escape = (v) => `"${v == null ? '' : String(v).replace(/"/g, '""')}"`;
        const header = cols.map((c) => escape(c.label || c.fieldName)).join(',');
        const rows = (this.records || []).map((r) =>
            cols.map((c) => escape(r[c.fieldName])).join(',')
        );
        const csv = [header, ...rows].join('\r\n');
        const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = this.exportFilename;
        a.click();
        URL.revokeObjectURL(url);
    }
}