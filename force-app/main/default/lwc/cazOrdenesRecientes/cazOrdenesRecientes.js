/**
 * cazOrdenesRecientes
 * Componente hijo: tabla HTML de órdenes y solicitudes recientes.
 * Recibe userId del padre, hace sus propias llamadas Apex.
 * Por ahora usa datos mock; preparado para @wire.
 */
import { LightningElement, api } from 'lwc';

export default class CazOrdenesRecientes extends LightningElement {
    @api userId;

    // ── Mock Data (reemplazar con @wire a Apex) ──
    orders = [
        {
            id: 'ord9021',
            ref: 'ORD-9021',
            entity: 'Planta Tula',
            date: '25 Mar, 08:30',
            type: 'Pedido',
            typeIcon: 'utility:package',
            badgeClass: 'slds-badge badge-warning custom-badge',
            status: 'En Tránsito',
            amount: '$145,000.00'
        },
        {
            id: 'dev1045',
            ref: 'DEV-1045',
            entity: 'Caso M-902',
            date: '22 Mar, 14:15',
            type: 'Devolución',
            typeIcon: 'utility:undo',
            badgeClass: 'slds-badge badge-info custom-badge',
            status: 'En Revisión',
            amount: '$12,500.00'
        },
        {
            id: 'facA991',
            ref: 'FAC-A991',
            entity: 'ORD-8944',
            date: '18 Mar, 09:00',
            type: 'Factura',
            typeIcon: 'utility:file',
            badgeClass: 'slds-badge badge-success custom-badge',
            status: 'Pagada',
            amount: '$320,000.00'
        }
    ];

    handleViewAll() {
        this.dispatchEvent(new CustomEvent('viewall'));
    }
}