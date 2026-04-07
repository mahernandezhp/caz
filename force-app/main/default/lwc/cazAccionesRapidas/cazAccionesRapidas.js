/**
 * cazAccionesRapidas
 * Componente hijo: grid de acciones rápidas del dashboard.
 * Recibe userId del padre; define sus propias acciones.
 * Dispara evento onactionclick con el actionId para que el padre navegue.
 */
import { LightningElement, api } from 'lwc';

export default class CazAccionesRapidas extends LightningElement {
    @api userId;

    // Las acciones se definen aquí — extensible vía Apex en el futuro
    get actions() {
        return [
            {
                id: 'nueva_orden',
                label: 'Nueva Orden',
                subtitle: 'Crear pedido',
                icon: 'utility:delivery',
                iconContainerClass: 'icon-action-circle bg-blue-light slds-m-right_medium'
            },
            {
                id: 'pagar_ordenes',
                label: 'Pagar Órdenes',
                subtitle: 'Liquidar adeudos',
                icon: 'utility:money',
                iconContainerClass: 'icon-action-circle bg-green-light slds-m-right_medium'
            },
            {
                id: 'devoluciones',
                label: 'Devoluciones',
                subtitle: 'Retornos logísticos',
                icon: 'utility:undo',
                iconContainerClass: 'icon-action-circle bg-orange-light slds-m-right_medium'
            },
            {
                id: 'aclaraciones',
                label: 'Aclaraciones',
                subtitle: 'Reportar un caso',
                icon: 'utility:help',
                iconContainerClass: 'icon-action-circle bg-purple-light slds-m-right_medium'
            },
            {
                id: 'ampliacion_credito',
                label: 'Ampliación Crédito',
                subtitle: 'Aumentar línea',
                icon: 'utility:builder_control',
                iconContainerClass: 'icon-action-circle bg-indigo-light slds-m-right_medium'
            }
        ];
    }

    handleActionClick(event) {
        const actionId = event.currentTarget.dataset.actionId;
        this.dispatchEvent(new CustomEvent('actionclick', {
            detail: { actionId }
        }));
    }
}