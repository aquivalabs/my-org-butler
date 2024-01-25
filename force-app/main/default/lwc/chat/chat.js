import { api, LightningElement, track } from 'lwc';
import { subscribe, unsubscribe} from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

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

export default class ChatWindow extends LightningElement {
    @track messages = [];
    @api channelName = '/event/AssistantCallback__e';

    threadId;
    subscription;
    question = '';
    lastMessageId = null;

    isLoading = true;
    waitingForResponse = false;

    get messagesToDisplay() {
        return this.messages
            .map((msg, index) => ({
                order: index,
                message: msg,
                messageType: MESSAGE_TYPE_BY_ROLE[msg.role],
            }));
    }

    get askingQuestionsDisabled() {
        return this.waitingForResponse == true;
    }

    addMessage(msg) {
        this.messages.push(msg);
    }

    resetQuestion() {
        this.question = '';
    }

    addPreviewMessage(message) {
        this.addMessage({ role: MESSAGE_ROLE.USER, content: message, preview: true});
    }

    removePreviewMessage() {
        if(this.messages.length !== 0 && this.messages[this.messages.length - 1].preview === true){
            this.messages.pop();
        }
    }

    async initialize() {
        try {
            this.threadId = await init();
        } catch(excpetion) {
            this.logException(excpetion);
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
                chatMessage.runId = message.run_id;

                this.addMessage(chatMessage);
            });

            this.lastMessageId = this.messages.length !== 0 ?
                this.messages[this.messages.length - 1].id : null;
        } catch(excpetion) {
            this.logException(excpetion);
        }
    }

    subscribe() {
        const messageCallback = async (response) => {
            try {
                const event = JSON.parse(JSON.stringify(response));
                const threadId = event.data.payload.ThreadId__c;

                if (this.threadId === threadId) {
                    await this.loadMesages();
                    this.waitingForResponse = false;
                }
            } catch(excpetion) {
                this.logException(excpetion);
            }
        };

        subscribe(this.channelName, -1, messageCallback).then(response => {
            this.subscription = response;
        });
    }

    logException(excpetion) {
        const errorMessage = excpetion.body?.message || excpetion.message;

        const event = new ShowToastEvent({
            title: 'Error Occured',
            message: errorMessage,
            variant: 'error',
            mode: 'sticky'
        });

        this.dispatchEvent(event);
    }

    async handleEnterAskQuestion(event) {
        if(event.keyCode === ENTER_BUTTON_CODE) {
            await this.handleAskQuestion();
        }
    }

    async handleAskQuestion() {
        try {
            if (this.question === '') {
                return;
            }

            this.waitingForResponse = true;

            const message = this.question;
            this.addPreviewMessage(message);
            this.resetQuestion();

            await respond({message : message});
        } catch(excpetion) {
            this.logException(excpetion);
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
        } catch(excpetion) {
            this.logException(excpetion);
        } finally {
            this.waitingForResponse = false;
            this.isLoading = false;
        }
    }

    async connectedCallback() {
        try {
            this.subscribe();
            await this.initialize();
            await this.loadMesages();
        } catch(excpetion) {
            this.logException(excpetion);
        } finally {
            this.isLoading = false;
        }
    }

    disconnectedCallback(){
        unsubscribe(this.subscription, (response) => {}).catch((error) => { console.error(error); });
    }

    renderedCallback() {
        if (this.refs.chatMessages) {
            this.refs.chatMessages.scrollTop = this.refs.chatMessages.scrollHeight;
        }
    }
}