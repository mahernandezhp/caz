import { LightningElement, api } from 'lwc';

/**
 * Botón de marca PDX. Variantes: brand | neutral | destructive.
 * Emite el evento `click`. Mantiene la estética de marca (azul Cruz Azul).
 */
export default class PdxButton extends LightningElement {
    @api label;
    @api variant = 'brand';
    @api iconName;
    @api disabled = false;
    @api type = 'button';

    get computedClass() {
        return `pdx-button pdx-button_${this.variant}`;
    }

    handleClick() {
        this.dispatchEvent(new CustomEvent('click'));
    }
}