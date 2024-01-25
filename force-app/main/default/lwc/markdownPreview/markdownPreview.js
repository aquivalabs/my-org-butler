import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import markedJs from '@salesforce/resourceUrl/markedJs';

export default class MarkdownPreview extends LightningElement {
    isRendered = false;
    _body = '';

    @api
    get body() {
        return this._body;
    }
    set body(value) {
        this._body = value;

        if (this.isRendered) {
            this.renderMarkdown();
        }
    }

    renderedCallback() {
        if (this.isRendered) {
            return;
        }

        this.isRendered = true;

        loadScript(this, markedJs).then(() => {
            this.renderMarkdown();
        });
    }

    renderMarkdown() {
        this.template.querySelector('div').innerHTML = marked.parse(this.body);
    }
}