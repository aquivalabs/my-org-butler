import { LightningElement, api } from 'lwc';
import steps from '@salesforce/apex/ChatCtrl.steps';
import modify from '@salesforce/apex/ChatCtrl.modify';
import butlerLogo from '@salesforce/contentAssetUrl/myorgbutlertransparent_720';

export const MESSAGE_TYPE = {
    INBOUND: 'inbound',
    OUTBOUND: 'outbound',
};

export default class SingleChatMessage extends LightningElement {
    @api message;
    @api type = MESSAGE_TYPE.OUTBOUND;

    butlerLogo = butlerLogo;
    explanationSteps = [];
    isExpanded = false;

    get isButlerLogoVisible() {
        return this.type === MESSAGE_TYPE.INBOUND;
    }

    get isExplanationVisible() {
        return this.type === MESSAGE_TYPE.INBOUND;
    }

    get listItemClass() {
        return `slds-var-p-bottom_x-small slds-chat-listitem slds-chat-listitem_${this.type}`;
    }

    get chatMessageTextClass() {
        return `slds-grid slds-chat-message__text slds-chat-message__text_${this.type} slds-text-heading_small`
    }

    get showFeedbackOptions() {
        return this.type === MESSAGE_TYPE.INBOUND;
    }

    get toggleIcon() {
        return this.isExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get contentClass() {
        return `slds-p-left_small explanation-content ${this.isExpanded ? 'expanded' : ''}`;
    }

    async connectedCallback() {
        if (this.type === MESSAGE_TYPE.INBOUND) {
            await this.getExplanation();
        }
    }

    async getExplanation() {
        const stepResult = await steps({runId : this.message.runId, order: 'asc'});

        this.explanationSteps = stepResult.data
            .filter(data => data.type === 'tool_calls')
            .flatMap(data => data.step_details.tool_calls)
            .filter(toolCall => toolCall.type === 'function')
            .map((toolCall, index) => {
                const args = JSON.parse(toolCall.function.arguments);
                return {
                    id: `step-${index}`,
                    title: `${index + 1}. ${toolCall.function.name.replace(/_/g, ' ')}`,
                    args: JSON.stringify(args, null, 2),
                    output: toolCall.function.output
                };
            });
    }

    toggleExplanation() {
        this.isExpanded = !this.isExpanded;
    }

    async handleVoteClick(event) {
        await modify({ 
            message: { 
                id: this.message.id, 
                run_id: this.message.runId,
                metadata: { 
                    isFeedbackPositive: event.detail.isPositive?.toString()
                } 
            } 
        });
    }
}
