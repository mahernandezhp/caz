import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import crearPedido from '@salesforce/apex/CAZ_PortalPedidosController.crearPedido';

export default class CazNuevoPedidoForm extends LightningElement {
    @api accountId;
    @api accountName;
    @api contactName;
    @api claveCuenta;
    @api plantaDefault;

    @track guardando = false;

    fechaSolicitud;
    cantidad;
    tipoCemento;

    tipoCementoOptions = [
        { label: 'Cemento Gris', value: 'Cemento Gris' },
        { label: 'Cemento Blanco', value: 'Cemento Blanco' },
        { label: 'Mortero', value: 'Mortero' }
    ];

    get hoy() {
        const hoy = new Date();
        const year = hoy.getFullYear();
        const month = String(hoy.getMonth() + 1).padStart(2, '0');
        const day = String(hoy.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    handleChange(event) {
        const campo = event.target.name;
        const valor = event.target.value;

        console.log('CazNuevoPedidoForm.handleChange - campo =>', campo);
        console.log('CazNuevoPedidoForm.handleChange - valor =>', valor);

        this[campo] = valor;

        console.log('CazNuevoPedidoForm.handleChange - estado actual =>', JSON.stringify({
            fechaSolicitud: this.fechaSolicitud,
            cantidad: this.cantidad,
            tipoCemento: this.tipoCemento
        }));
    }

    handleCancel() {
        console.log('CazNuevoPedidoForm.handleCancel - INICIO');
        this.dispatchEvent(new CustomEvent('cancel'));
        console.log('CazNuevoPedidoForm.handleCancel - FIN');
    }

    async handleGuardar() {
        console.log('CazNuevoPedidoForm.handleGuardar - INICIO');
        console.log('CazNuevoPedidoForm.handleGuardar - fechaSolicitud =>', this.fechaSolicitud);
        console.log('CazNuevoPedidoForm.handleGuardar - cantidad =>', this.cantidad);
        console.log('CazNuevoPedidoForm.handleGuardar - tipoCemento =>', this.tipoCemento);

        const tipoOrden = this.mapearTipoOrden(this.tipoCemento);
        console.log('CazNuevoPedidoForm.handleGuardar - tipoOrden =>', tipoOrden);

        if (!this.validarFormulario()) {
            console.log('CazNuevoPedidoForm.handleGuardar - Formulario inválido');
            return;
        }

        this.guardando = true;
        console.log('CazNuevoPedidoForm.handleGuardar - guardando =>', this.guardando);

        try {
            const request = {
                fechaSolicitud: this.fechaSolicitud,
                cantidad: this.cantidad !== null && this.cantidad !== '' ? Number(this.cantidad) : null,
                tipoCemento: this.tipoCemento,
                tipoOrden: tipoOrden
            };

            console.log('CazNuevoPedidoForm.handleGuardar - request =>', JSON.stringify(request));

            const response = await crearPedido({ req: request });

            console.log('CazNuevoPedidoForm.handleGuardar - response =>', response);

            this.dispatchEvent(new CustomEvent('success'));
            console.log('CazNuevoPedidoForm.handleGuardar - Evento success disparado');
        } catch (error) {
            console.error('CazNuevoPedidoForm.handleGuardar - ERROR =>', error);
            console.error('CazNuevoPedidoForm.handleGuardar - error.body =>', error?.body);
            console.error('CazNuevoPedidoForm.handleGuardar - error.body.message =>', error?.body?.message);
            console.error('CazNuevoPedidoForm.handleGuardar - error.message =>', error?.message);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error al guardar',
                    message: this.obtenerMensajeError(error),
                    variant: 'error'
                })
            );

            console.log('CazNuevoPedidoForm.handleGuardar - Toast de error mostrado');
        } finally {
            this.guardando = false;
            console.log('CazNuevoPedidoForm.handleGuardar - guardando =>', this.guardando);
            console.log('CazNuevoPedidoForm.handleGuardar - FIN');
        }
    }

    validarFormulario() {
        console.log('CazNuevoPedidoForm.validarFormulario - INICIO');

        const inputs = this.template.querySelectorAll('lightning-input, lightning-combobox');
        let esValido = true;

        console.log('CazNuevoPedidoForm.validarFormulario - cantidad de inputs =>', inputs.length);

        inputs.forEach(input => {
            console.log('CazNuevoPedidoForm.validarFormulario - input.name =>', input.name);
            console.log('CazNuevoPedidoForm.validarFormulario - input.value =>', input.value);

            if (!input.reportValidity()) {
                esValido = false;
                console.log('CazNuevoPedidoForm.validarFormulario - input inválido =>', input.name);
            }
        });

        console.log('CazNuevoPedidoForm.validarFormulario - fechaSolicitud =>', this.fechaSolicitud);
        console.log('CazNuevoPedidoForm.validarFormulario - hoy =>', this.hoy);

        if (this.fechaSolicitud && this.fechaSolicitud < this.hoy) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Fecha inválida',
                    message: 'No se permite una fecha anterior al día de hoy.',
                    variant: 'error'
                })
            );
            esValido = false;
            console.log('CazNuevoPedidoForm.validarFormulario - fecha inválida');
        }

        console.log('CazNuevoPedidoForm.validarFormulario - esValido =>', esValido);
        console.log('CazNuevoPedidoForm.validarFormulario - FIN');

        return esValido;
    }

    mapearTipoOrden(tipoCemento) {
        console.log('CazNuevoPedidoForm.mapearTipoOrden - INICIO');
        console.log('CazNuevoPedidoForm.mapearTipoOrden - tipoCemento =>', tipoCemento);

        const mapa = {
            'Cemento Gris': 'ORDEN_GRIS',
            'Cemento Blanco': 'ORDEN_BLANCO',
            'Mortero': 'ORDEN_MORTERO'
        };

        const resultado = mapa[tipoCemento] || 'ORDEN_GENERAL';

        console.log('CazNuevoPedidoForm.mapearTipoOrden - resultado =>', resultado);
        console.log('CazNuevoPedidoForm.mapearTipoOrden - FIN');

        return resultado;
    }

    obtenerMensajeError(error) {
        console.log('CazNuevoPedidoForm.obtenerMensajeError - INICIO');
        console.log('CazNuevoPedidoForm.obtenerMensajeError - error =>', error);
        console.log('CazNuevoPedidoForm.obtenerMensajeError - error.body =>', error?.body);
        console.log('CazNuevoPedidoForm.obtenerMensajeError - error.body.message =>', error?.body?.message);
        console.log('CazNuevoPedidoForm.obtenerMensajeError - error.message =>', error?.message);

        if (error?.body?.message) {
            console.log('CazNuevoPedidoForm.obtenerMensajeError - FIN con error.body.message');
            return error.body.message;
        }

        if (error?.message) {
            console.log('CazNuevoPedidoForm.obtenerMensajeError - FIN con error.message');
            return error.message;
        }

        console.log('CazNuevoPedidoForm.obtenerMensajeError - FIN con mensaje genérico');
        return 'Ocurrió un error inesperado.';
    }
}