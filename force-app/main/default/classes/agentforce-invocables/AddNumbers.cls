public with sharing class AddNumbers {
    
    @InvocableMethod(label='Add Numbers' description='Adds two numbers together and returns their sum')
    public static List<Output> execute(List<Input> inputs) {
        Input input = inputs[0];
        Output output = new Output();
        output.result = input.number1 + input.number2;
        return new List<Output>{ output };
    }

    // INNER

    public class Input {
        @InvocableVariable(label='First Number' description='First number to add' required=true)
        public Decimal number1;

        @InvocableVariable(label='Second Number' description='Second number to add' required=true)
        public Decimal number2;
    }

    public class Output {
        @InvocableVariable(label='Sum' description='The sum of the two numbers')
        public Decimal result;
    }
}