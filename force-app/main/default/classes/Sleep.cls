public with sharing class Sleep {
    
    // PMD False Positive: Empty while is part of idle algortihm of https://salesforce.stackexchange.com/a/302152/256
    @SuppressWarnings('PMD')
    public Sleep(Integer milliseconds) {
        Long startTime = DateTime.now().getTime();
        while(DateTime.now().getTime() - startTime < milliseconds); 
    }
}