import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SpeechInput extends LightningElement {
    @api disabled = false;
    isListening = false;
    recognition = null;

    connectedCallback() {
        // Try different Speech Recognition implementations
        const SpeechRecognition = window.SpeechRecognition || 
                                 window.webkitSpeechRecognition ||
                                 window.mozSpeechRecognition ||
                                 window.msSpeechRecognition;
        
        if (SpeechRecognition) {
            try {
                this.recognition = new SpeechRecognition();
                this.setupRecognition();
            } catch (e) {
                console.error('Failed to initialize speech recognition:', e);
            }
        }
    }

    setupRecognition() {
        if (!this.recognition) return;

        this.recognition.continuous = false;
        this.recognition.interimResults = true;
        
        // Force US English for better recognition
        this.recognition.lang = 'en-US';

        this.recognition.onstart = () => {
            this.isListening = true;
        };

        this.recognition.onresult = (event) => {
            if (event.results && event.results[0]) {
                const result = event.results[0];
                if (result.isFinal) {
                    const transcript = result[0].transcript;
                    this.dispatchEvent(new CustomEvent('speechresult', {
                        detail: transcript
                    }));
                    this.isListening = false;
                }
            }
        };

        this.recognition.onerror = (event) => {
            let errorMessage;
            
            switch(event.error) {
                case 'not-allowed':
                    errorMessage = 'Please allow microphone access in your browser.';
                    break;
                case 'no-speech':
                    errorMessage = 'No speech was detected. Please try again.';
                    break;
                case 'network':
                    errorMessage = 'Please check your internet connection.';
                    break;
                case 'audio-capture':
                    errorMessage = 'No microphone was found. Please check your settings.';
                    break;
                case 'aborted':
                    // Don't show error for user-initiated stops
                    return;
                default:
                    errorMessage = 'Please try again.';
            }
            
            if (errorMessage) {
                this.showErrorToast('Microphone Error', errorMessage);
            }
            this.isListening = false;
        };

        this.recognition.onend = () => {
            this.isListening = false;
        };
    }

    handleClick() {
        if (!this.recognition) {
            this.showErrorToast('Browser Not Supported', 
                'Speech recognition is not supported in your browser.');
            return;
        }

        if (!this.isListening) {
            try {
                this.recognition.start();
            } catch (e) {
                console.error('Failed to start recognition:', e);
                this.showErrorToast('Error', 'Failed to start voice input. Please try again.');
            }
        } else {
            try {
                this.recognition.stop();
            } catch (e) {
                console.error('Failed to stop recognition:', e);
            }
        }
    }

    showErrorToast(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: 'error',
            mode: 'dismissable'
        }));
    }

    get buttonIcon() {
        return this.isListening ? 'utility:stop' : 'utility:listen';
    }

    get buttonVariant() {
        return this.isListening ? 'destructive' : 'neutral';
    }

    get buttonTitle() {
        return this.isListening ? 'Recording... Click to stop' : 'Click to start voice recording';
    }
} 