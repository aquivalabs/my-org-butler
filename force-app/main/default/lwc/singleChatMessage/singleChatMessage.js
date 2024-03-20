import { LightningElement, api } from 'lwc';

import steps from '@salesforce/apex/ChatCtrl.steps';

import butlerLogo from '@salesforce/contentAssetUrl/myorgbutlertransparent_720';

export const MESSAGE_TYPE = {
    INBOUND: 'inbound',
    OUTBOUND: 'outbound',
};

export default class SingleChatMessage extends LightningElement {
    @api message;
    @api type = MESSAGE_TYPE.OUTBOUND;

    butlerLogo = butlerLogo;
    explanation;
    explanationInitialized = false;
    visibleQuestion = true;

    get isButlerLogoVisible() {
        return this.type === MESSAGE_TYPE.INBOUND;
    }

    get isExplanationVisible() {
        return this.type === MESSAGE_TYPE.INBOUND;
    }

    get visibleMessage() {
        return this.visibleQuestion ? this.message.content : this.explanation;
    }

    get listItemClass() {
        return `slds-var-p-bottom_x-small slds-chat-listitem slds-chat-listitem_${this.type}`;
    }

    get chatMessageTextClass() {
        return `slds-grid slds-chat-message__text slds-chat-message__text_${this.type} slds-text-heading_small`
    }

    getCodeBlockStyling(code) {
        return code ? '<div style="background-color: rgb(250, 250, 250); border-radius: 10px; padding:10px"><code>'  + code + '</code></div>' : '';
    }

    async getExplanation() {
        const stepResult = await steps({runId : this.message.runId, order: 'asc'});

        let toolCallouts = [];
        for (let step = 0; step < stepResult.data.length; step++) {
            const data =  stepResult.data[step];

            if(data.type === 'tool_calls') {
                for (let i = 0; i < data.step_details.tool_calls.length; i++) {
                    const toolCall = data.step_details.tool_calls[i];
                    if(toolCall.type === 'function'){
                        const toolCallArgs = JSON.parse(toolCall.function.arguments);

                        if (toolCall.function.name === 'Call_Salesforce_API') {
                            const method = toolCallArgs.httpMethod;
                            const uri = toolCallArgs.urlIncludingParams;
                            const uriMethod = this.getCodeBlockStyling(method + ' ' + uri);

                            const body = toolCallArgs.body ? this.getCodeBlockStyling(toolCallArgs.body) : '';
                            const output = toolCall.function.output ? '\n\tOutput' + this.getCodeBlockStyling(toolCall.function.output) : '';

                            const stepInfo = (toolCallouts.length + 1) + '. ' + uriMethod + body + output;
                            toolCallouts.push(stepInfo);
                        } else if (toolCall.function.name === 'Notify_User') {
                            const title = '\n\tTitle' + this.getCodeBlockStyling(toolCallArgs.title);
                            const body = '\n\tBody' + this.getCodeBlockStyling(toolCallArgs.body);
                            const output = toolCall.function.output ? '\n\tOutput' + this.getCodeBlockStyling(toolCall.function.output) : '';

                            const stepInfo = (toolCallouts.length + 1) + '. Notification\n' + title + body + output;
                            toolCallouts.push(stepInfo);
                        }
                    }
                }
            }
        }

        this.explanation = '`Steps:` \n' + toolCallouts.join('\n');
        this.explanationInitialized = true;
    }

    async handleExplain() {
        if(!this.explanationInitialized) {
            await this.getExplanation();
        }

        this.visibleQuestion = !this.visibleQuestion;
    }
}
