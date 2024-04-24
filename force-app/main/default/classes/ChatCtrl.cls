public with sharing class ChatCtrl {

    // PUBLIC

    @AuraEnabled
    public static String init() {
        return new MyOrgButler().threadId();
    }

    @AuraEnabled
    public static String reset() {
        aquiva.Tracker.event('MyOrgButlerFeatureAdoption').with('feature', 'reset');
        aquiva.Tracker.publish();

        MyOrgButler butler = new MyOrgButler();
        butler.reset();
        return butler.threadId();
    }

    @AuraEnabled
    public static List<Message> messages(String lastMessageId) {
        return new MyOrgButler().messages(lastMessageId);
    }

    @AuraEnabled
    public static void respond(String question, String context) {
        new MyOrgButler().respond(question, context);
    }

    @AuraEnabled
    public static void modify(String messageId, Boolean isFeedbackPositive) {
        // TODO: event publishing to be added
        Message.Metadata msgMetadata = new Message.Metadata();
        msgMetadata.isFeedbackPositive = String.valueOf(isFeedbackPositive);

        Message message = new Message();
        message.id = messageId;
        message.metadata = msgMetadata;
        
        new MyOrgButler().modify(message);
    }

    @AuraEnabled
    public static Run.Steps steps(String runId, String order) {
        return new MyOrgButler().steps(runId, order);
    }
}