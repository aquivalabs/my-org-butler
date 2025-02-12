public with sharing class ChatCtrl {

    // PUBLIC

    @AuraEnabled
    public static String init() {
        return new MyOrgButler().threadId();
    }

    @AuraEnabled
    public static String reset() {
        MyOrgButler butler = new MyOrgButler();
        butler.reset();
        return butler.threadId();
    }

    @AuraEnabled
    public static List<Message> messages(String lastMessageId) {
        return new MyOrgButler().messages(lastMessageId);
    }

    @AuraEnabled
    public static void respond(String question) {
        new MyOrgButler().respond(question);
    }

    @AuraEnabled
    public static void modify(Message message) {
        new MyOrgButler().modify(message);
    }

    @AuraEnabled
    public static Run.Steps steps(String runId, String order) {
        return new MyOrgButler().steps(runId, order);
    }
}