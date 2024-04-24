import { LightningElement } from 'lwc';

export default class Feedback extends LightningElement {
    FEEDBACK_POSITIVE = 'positive';
    FEEDBACK_NEGATIVE = 'negative';

    isPositive;

    get negativeFeedbackVariant() {
        return this.voted && !this.isPositive ? 'brand' : '';
    }

    get positiveFeedbackVariant() {
        return this.voted && this.isPositive ? 'brand' : '';
    }

    get voted() {
        return this.isPositive !== undefined;
    }

    handleFeedback(event) {
        this.isPositive = event.target.dataset.feedback === this.FEEDBACK_POSITIVE;
        this.dispatchEvent(
            new CustomEvent('vote', { detail: { isPositive: this.isPositive } } )
        );
    }
}