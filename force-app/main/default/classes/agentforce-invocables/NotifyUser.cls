// PMD False Positives: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalMethod')
global with sharing class NotifyUser {
    
    @InvocableMethod(label='MyOrgButler: Notify User' description='Sends an In-org notification message to a set of users optionally linking to a target record')
    global static List<Output> execute(List<Notification> notifications) {
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(notifications[0].title);
        notification.setBody(notifications[0].body);
        notification.setNotificationTypeId([SELECT Id FROM CustomNotificationType WHERE DeveloperName='InOrgNotifications'].Id);
        notification.setTargetId(notifications[0].targetId);
        notification.send(new Set<String>(notifications[0].recipientIds));

        return new List<Output>{ new Output() };
    }

    // INNER

    global with sharing class Notification {
        @InvocableVariable(label='Recipient User Ids' description='Comma separated list of Salesforce Ids of the users to send the notification to' required=true)
        global List<String> recipientIds;

        @InvocableVariable(label='Title' description='Short title of the notification' required=true)
        global String title;

        @InvocableVariable(label='Body' description='Notification text' required=true)
        global String body;

        @InvocableVariable(label='Target Id' description='Salesforce Id of the record to link to. If there is none use 000000000000000AAA' required=true)
        global String targetId;
    }

    global class Output {
        @InvocableVariable(label='Ignored' description='ignored' required=false)
        global String ignored;

    }
}