import { LightningElement, api } from 'lwc';

import butlerLogo from '@salesforce/contentAssetUrl/myorgbutlertransparent_720';

export default class TypingChatMessage extends LightningElement {
    @api message;

    butlerLogo = butlerLogo;
}