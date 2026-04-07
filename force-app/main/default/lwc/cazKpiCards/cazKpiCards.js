/**
 * cazKpiCards
 * Componente hijo: tarjetas KPI con gráficos donut y data pills.
 * Recibe userId del padre, hace sus propias llamadas Apex.
 * Por ahora usa datos mock; preparado para @wire.
 */
import { LightningElement, api } from 'lwc';

export default class CazKpiCards extends LightningElement {
    @api userId;

    // ── Mock Data (reemplazar con @wire a Apex) ──
    creditAvailable = '$1.25M';
    creditUsed = '$1.74M';
    creditOverdue = '$0';
    usagePercent = 58;
    creditLimit = '$3M';
    openCases = 0;
    overdueBalance = '$0';
    criticalCases = 0;

    get freePercent() {
        return 100 - this.usagePercent;
    }

    /**
     * Genera dinámicamente la clase CSS del donut basándose en el porcentaje.
     * El conic-gradient se define en CSS como clase estática; si necesitamos
     * un gradiente dinámico, usaríamos style binding.
     */
    get donutUsageClass() {
        return 'donut-chart donut-chart-red-partial';
    }

    // ── Eventos hacia el padre ──
    handleAmpliar() {
        this.dispatchEvent(new CustomEvent('kpiaction', { detail: { action: 'ampliar' } }));
    }

    handleDetalles() {
        this.dispatchEvent(new CustomEvent('kpiaction', { detail: { action: 'detalles' } }));
    }

    handleCasos() {
        this.dispatchEvent(new CustomEvent('kpiaction', { detail: { action: 'casos' } }));
    }
}