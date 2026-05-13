trigger Leads on Lead (before insert, before update) {
    new LeadScoring(Trigger.new).score();
}
