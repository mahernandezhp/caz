import { LightningElement, track } from 'lwc';

export default class CazDashboardDistribuidor extends LightningElement {
    @track currentView = 'home';

    get isHome() { return this.currentView === 'home'; }
    get isDevoluciones() { return this.currentView === 'mis_solicitudes'; }
    get isNuevaDevolucion() { return this.currentView === 'nueva_solicitud'; }

    handleNavHome() {
        this.currentView = 'home';
    }

    handleNavDevoluciones() {
        this.currentView = 'mis_solicitudes';
    }

    handleSpaNavigation(event) {
        const target = event.detail.target;
        if (target) {
            this.currentView = target;
        }
    }
}
