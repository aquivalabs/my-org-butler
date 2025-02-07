import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SpeechInput extends LightningElement {
    @api disabled = false;
    isListening = false;
    recognition = null;

    connectedCallback() {
        const SpeechRecognition = window.SpeechRecognition || 
                                 window.webkitSpeechRecognition ||
                                 window.mozSpeechRecognition ||
                                 window.msSpeechRecognition;
        
        if (SpeechRecognition) {
            this.recognition = new SpeechRecognition();
            this.setupRecognition();
        }
    }

    setupRecognition() {
        if (!this.recognition) return;

        this.recognition.continuous = true;
        this.recognition.interimResults = true;
        this.recognition.lang = 'en-US';

        this.recognition.onstart = () => {
            this.isListening = true;
        };

        this.recognition.onresult = (event) => {
            const result = event.results[event.results.length - 1];
            if (result.isFinal) {
                const transcript = result[0].transcript;
                this.dispatchEvent(new CustomEvent('speechresult', {
                    detail: transcript
                }));
            }
        };

        this.recognition.onerror = (event) => {
            if (event.error !== 'aborted') {
                this.showErrorToast('Speech Recognition Error', event.error);
            }
            this.isListening = false;
        };

        this.recognition.onend = () => {
            if (this.isListening) {
                try {
                    this.recognition.start();
                } catch (error) {
                    this.showErrorToast('Recognition Error', error.message);
                    this.isListening = false;
                }
            }
        };
    }

    handleClick() {
        if (!this.recognition) {
            this.showErrorToast('Browser Error', 'Speech recognition not supported');
            return;
        }

        try {
            if (this.isListening) {
                this.isListening = false;
                this.recognition.stop();
            } else {
                this.recognition.start();
            }
        } catch (error) {
            this.showErrorToast('Recognition Error', error.message);
            this.isListening = false;
        }
    }

    showErrorToast(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'error'
        }));
    }

    get buttonIcon() {
        return this.isListening ? 'utility:stop' : 'utility:record';
    }

    get buttonVariant() {
        return this.isListening ? 'destructive' : 'neutral';
    }

    get buttonTitle() {
        return this.isListening ? 'Recording... Click to stop' : 'Click to start voice recording';
    }
} 