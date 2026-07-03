import { LightningElement } from 'lwc';

/**
 * Shell del portal (SPA, brief §8): header + nav lateral + router interno que
 * intercambia el módulo activo sin recargar (feel app-like). Cada módulo es un
 * LWC propio (maqueta con datos dummy; la capa de servicios se enchufa por módulo).
 */
export default class PdxPortalShell extends LightningElement {
    activeModule = 'home';

    handleNavigate(event) {
        this.activeModule = event.detail.name;
    }

    get isHome() {
        return this.activeModule === 'home';
    }
    get isOrdenes() {
        return this.activeModule === 'ordenes';
    }
    get isFacturas() {
        return this.activeModule === 'facturas';
    }
    get isEstado() {
        return this.activeModule === 'estado';
    }
    get isPagos() {
        return this.activeModule === 'pagos';
    }
    get isBonificaciones() {
        return this.activeModule === 'bonificaciones';
    }
    get isSolicitudes() {
        return this.activeModule === 'solicitudes';
    }
    get isCuenta() {
        return this.activeModule === 'cuenta';
    }
}