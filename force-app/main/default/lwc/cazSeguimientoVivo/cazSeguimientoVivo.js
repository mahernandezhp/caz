/**
 * cazSeguimientoVivo
 * Componente hijo: panel de seguimiento en vivo con timeline de entregas.
 * Recibe userId del padre, hace sus propias llamadas Apex.
 * Por ahora usa datos mock; preparado para @wire.
 */
import { LightningElement, api } from 'lwc';

export default class CazSeguimientoVivo extends LightningElement {
    @api userId;

    // ── Mock Data (reemplazar con @wire a Apex) ──
    activeOrderRef = 'ORD-9021';
    estimatedArrival = 'Hoy, 18:00';
    progressPercent = 70;

    get progressStyle() {
        return `width: ${this.progressPercent}%`;
    }

    get timelineSteps() {
        return [
            {
                id: 'step1',
                title: 'Carga Completada',
                description: '14:30 PM - Planta Tula',
                isCompleted: true,
                isActive: false,
                isPending: false,
                isLast: false,
                hasMapLink: false,
                connectorClass: 'timeline-connector connector-success',
                contentClass: 'timeline-content',
                titleClass: 'slds-text-title_bold slds-m-bottom_xxx-small title-dark',
                descClass: 'slds-text-body_small slds-text-color_weak'
            },
            {
                id: 'step2',
                title: 'En Ruta (Unidad 557)',
                description: 'Aproximado a 45 min del destino en base a tráfico actual.',
                isCompleted: false,
                isActive: true,
                isPending: false,
                isLast: false,
                hasMapLink: true,
                connectorClass: 'timeline-connector connector-pending',
                contentClass: 'timeline-content bg-blue-highlight',
                titleClass: 'slds-text-title_bold slds-m-bottom_xxx-small title-brand',
                descClass: 'slds-text-body_small slds-text-color_weak'
            },
            {
                id: 'step3',
                title: 'Entrega en Obra',
                description: 'Pendiente de firma',
                isCompleted: false,
                isActive: false,
                isPending: true,
                isLast: true,
                hasMapLink: false,
                connectorClass: '',
                contentClass: 'timeline-content',
                titleClass: 'slds-m-bottom_xxx-small title-muted',
                descClass: 'slds-text-body_small text-muted'
            }
        ];
    }
}