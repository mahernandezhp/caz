/**
 * cazDashboardHeader
 * Componente hijo: encabezado de bienvenida del dashboard.
 * Recibe userId del padre y resuelve el nombre del usuario.
 * Por ahora usa datos mock; preparado para @wire con Apex.
 */
import { LightningElement, api } from 'lwc';

export default class CazDashboardHeader extends LightningElement {
    @api userId;

    // Mock — será reemplazado por @wire cuando exista el Apex controller
    get userName() {
        return 'Marco';
    }

    get dateLabel() {
        const now = new Date();
        const options = { day: 'numeric', month: 'long' };
        return now.toLocaleDateString('es-MX', options);
    }

    handleDownload() {
        this.dispatchEvent(new CustomEvent('download'));
    }

    handleNewOrder() {
        this.dispatchEvent(new CustomEvent('neworder'));
    }
}