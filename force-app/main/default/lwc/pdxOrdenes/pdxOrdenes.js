import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/* MAQUETA — datos dummy. Reemplazar por datos dinámicos al habilitar servicios.
   TODO(servicio): listado de órdenes -> servicio de Órdenes (PDX_MXConnectService.Host.READ).
   TODO(servicio): acción "Complemento"  -> POST /JDE/order/complement  (Host.WRITE).
   TODO(servicio): acción "Reprogramar"  -> POST /JDE/order/reprogramar (Host.WRITE; el ERP valida fechas pasadas/días inhábiles).
   Patrón: ver PDX_FacturasController como referencia para el controlador Apex. */
const ORDENES = [
    { id: 'o1', folio: 'OV-5567', fecha: '2026-06-10', planta: 'Cruz Azul Hidalgo', total: 254900.75, moneda: 'MXN', estatus: 'En tránsito' },
    { id: 'o2', folio: 'OV-5560', fecha: '2026-06-08', planta: 'Lagunas Oaxaca', total: 88210.0, moneda: 'MXN', estatus: 'Programada' },
    { id: 'o3', folio: 'OV-5551', fecha: '2026-06-03', planta: 'Cruz Azul Hidalgo', total: 17500.2, moneda: 'MXN', estatus: 'Entregada' },
    { id: 'o4', folio: 'OV-5540', fecha: '2026-05-28', planta: 'Tepezalá Aguascalientes', total: 320000.0, moneda: 'MXN', estatus: 'Cancelada' }
];

const COLUMNS = [
    { label: 'Folio', fieldName: 'folio', type: 'text' },
    { label: 'Fecha despacho', fieldName: 'fecha', type: 'date-local' },
    { label: 'Planta', fieldName: 'planta', type: 'text' },
    { label: 'Total', fieldName: 'total', type: 'currency', typeAttributes: { currencyCode: { fieldName: 'moneda' } }, cellAttributes: { alignment: 'right' } },
    { label: 'Estatus', fieldName: 'estatus', type: 'text' },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'Complemento', name: 'complemento', iconName: 'utility:add' },
                { label: 'Reprogramar', name: 'reprogramar', iconName: 'utility:event' }
            ]
        }
    }
];

export default class PdxOrdenes extends LightningElement {
    ordenes = ORDENES;
    columns = COLUMNS;
    numCliente;

    handleApply() {
        // TODO(servicio): re-consultar órdenes por número de cliente + rango de fechas.
    }

    handleRowAction(event) {
        const { action, row } = event.detail;
        this.pendiente(action.label, row.folio);
    }

    pendiente(accion, folio) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Maqueta',
                message: `"${accion}" de ${folio}: se conectará a MXConnect al desbloquear el P0.`,
                variant: 'info'
            })
        );
    }
}