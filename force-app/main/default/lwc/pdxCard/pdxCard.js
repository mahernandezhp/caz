import { LightningElement, api } from 'lwc';

/**
 * Contenedor de marca PDX: encabezado con título/icono + slot de acciones + cuerpo.
 * Patrón base de pantalla (brief §8): card -> filtros -> tabla.
 */
export default class PdxCard extends LightningElement {
    @api title;
    @api iconName;
}