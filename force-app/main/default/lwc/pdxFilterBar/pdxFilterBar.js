import { LightningElement, api } from 'lwc';

/**
 * Fila de filtros estándar (brief §3): número de cliente + rango de fechas.
 * Emite `apply` con { numCliente, desde, hasta }. Defaults sensatos los pone el padre.
 */
export default class PdxFilterBar extends LightningElement {
    @api numCliente;
    @api numClienteReadonly = false;
    desde;
    hasta;

    handleNum(event) {
        this.numCliente = event.target.value;
    }
    handleDesde(event) {
        this.desde = event.target.value;
    }
    handleHasta(event) {
        this.hasta = event.target.value;
    }

    apply() {
        this.dispatchEvent(
            new CustomEvent('apply', {
                detail: { numCliente: this.numCliente, desde: this.desde, hasta: this.hasta }
            })
        );
    }

    clearFilters() {
        this.desde = null;
        this.hasta = null;
        this.apply();
    }
}