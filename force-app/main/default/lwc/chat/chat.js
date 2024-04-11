import { api, LightningElement, track, wire } from 'lwc';
import { subscribe, unsubscribe} from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';

import init from '@salesforce/apex/ChatCtrl.init';
import reset from '@salesforce/apex/ChatCtrl.reset';
import messages from '@salesforce/apex/ChatCtrl.messages';
import respond from '@salesforce/apex/ChatCtrl.respond';

import { MESSAGE_TYPE } from 'c/singleChatMessage';

const MESSAGE_ROLE = {
    ASSISTANT: 'assistant',
    USER: 'user',
};

const MESSAGE_TYPE_BY_ROLE = {
    [MESSAGE_ROLE.ASSISTANT]: MESSAGE_TYPE.INBOUND,
    [MESSAGE_ROLE.USER]: MESSAGE_TYPE.OUTBOUND,
};

const ENTER_BUTTON_CODE = 13;

export default class ChatWindow extends NavigationMixin(LightningElement) {
    @track messages = [];
    @track currentPage; 

    @api channelName = '/event/aquiva_os__AssistantCallback__e';

    threadId;
    subscription;
    question = '';
    lastMessageId = null;

    isLoading = true;
    waitingForResponse = false;

    get messagesToDisplay() {
        return this.messages
            .map((message, index) => ({
                order: index,
                message: message,
                messageType: MESSAGE_TYPE_BY_ROLE[message.role],
            }));
    }

    get askingQuestionsDisabled() {
        return this.waitingForResponse == true;
    }

    addMessage(message) {
        this.messages.push(message);
    }

    resetQuestion() {
        this.question = '';
    }

    addPreviewMessage(question) {
        this.addMessage({ role: MESSAGE_ROLE.USER, content: question, preview: true});
    }

    removePreviewMessage() {
        if(this.messages.length !== 0 && this.messages[this.messages.length - 1].preview === true){
            this.messages.pop();
        }
    }

    async initialize() {
        try {
            this.threadId = await init();
        } 
        catch(exception) {
            this.logException(exception);
        }
    }

    async loadMesages() {
        try {
            const chatMessages = await messages({lastMessageId : this.lastMessageId});

            this.removePreviewMessage();

            chatMessages.forEach((message) => {
                let chatMessage = {};
                chatMessage.id = message.id;
                chatMessage.role = message.role;
                chatMessage.content = message.content[0].text.value;
                chatMessage.content = message.content?.[0].text.value ?? "No content";
                chatMessage.runId = message.run_id;

                this.addMessage(chatMessage);
            });

            this.lastMessageId = this.messages.length !== 0 ?
                this.messages[this.messages.length - 1].id : null;
        } 
        catch(exception) {
            this.logException(exception);
        }
    }

    subscribe() {
        const messageCallback = async (response) => {
            try {
                const event = JSON.parse(JSON.stringify(response));
                const threadId = event.data.payload.aquiva_os__ThreadId__c;
                const eventType = event.data.payload.aquiva_os__Type__c;

                if(this.threadId === threadId) {
                    if(eventType === 'NAVIGATE') {
                        const pageReference = JSON.parse(event.data.payload.aquiva_os__Payload__c);
                        this[NavigationMixin.Navigate](pageReference);
                    }
                    else if(eventType === 'RUN_FINISHED') {
                        await this.loadMesages();
                        this.waitingForResponse = false;
                    }
                }
            } 
            catch(exception) {
                this.logException(exception);
            }
        };

        subscribe(this.channelName, -1, messageCallback).then(response => {
            this.subscription = response;
        });
    }

    logException(exception) {
        const errorMessage = exception.body?.message || exception.message;

        const event = new ShowToastEvent({
            title: 'Error Occured',
            message: errorMessage,
            variant: 'error',
            mode: 'sticky'
        });

        this.dispatchEvent(event);
    }

    async handleEnterAskQuestion(event) {
        if (event.key === 'Enter' && !event.shiftKey) {
            event.preventDefault();
            await this.handleAskQuestion();
        }
    }

    async handleAskQuestion() {
        try {
            if(this.question === '') {
                return;
            }

            this.waitingForResponse = true;
            this.addPreviewMessage(this.question);
            await respond({ question: this.question, context: JSON.stringify(this.currentPage) });
            this.resetQuestion();
        } 
        catch(exception) {
            this.logException(exception);
        }
    }

    handleQuestionChange(event) {
        this.question = event.detail.value;
    }

    async handleResetChat() {
        try {
            this.isLoading = true;
            this.threadId = await reset();
            this.messages = [];
            this.lastMessageId = null;
        } 
        catch(exception) {
            this.logException(exception);
        } 
        finally {
            this.waitingForResponse = false;
            this.isLoading = false;
        }
    }

    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
        this.currentPage = currentPageReference;
    }   

    async connectedCallback() {
        try {
            this.subscribe();
            await this.initialize();
            await this.loadMesages();
        } 
        catch(exception) {
            this.logException(exception);
        } 
        finally {
            this.isLoading = false;
        }
    }

    disconnectedCallback(){
        unsubscribe(this.subscription, (response) => {}).catch((error) => { console.error(error); });
    }

    renderedCallback() {
        if(this.refs.chatMessages) {
            this.refs.chatMessages.scrollTop = this.refs.chatMessages.scrollHeight;
        }
    }
}