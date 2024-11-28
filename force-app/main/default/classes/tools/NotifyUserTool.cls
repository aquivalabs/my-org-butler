public with sharing class NotifyUserTool extends MyOrgButler.Tool {
    
    public override String execute(String paramsJson) {
        List<NotifyUser.Notification> notifications = new List<NotifyUser.Notification>{ new NotifyUser.Notification(paramsJson) };
        List<NotifyUser.Output> result = NotifyUser.execute(notifications);
        return JSON.serialize(result[0]);
    }
}