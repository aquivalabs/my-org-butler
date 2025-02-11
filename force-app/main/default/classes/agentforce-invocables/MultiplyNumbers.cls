public with sharing class MultiplyNumbers {
    
    @InvocableMethod(label='Multiply Numbers' description='Multiplies two numbers together and returns their product')
    public static List<Output> execute(List<Input> inputs) {
        Input input = inputs[0];
        Output output = new Output();
        output.result = input.number1 * input.number2;
        return new List<Output>{ output };
    }

    // INNER

    public class Input {
        @InvocableVariable(label='First Number' description='First number to multiply' required=true)
        public Decimal number1;

        @InvocableVariable(label='Second Number' description='Second number to multiply' required=true)
        public Decimal number2;
    }

    public class Output {
        @InvocableVariable(label='Product' description='The product of the two numbers')
        public Decimal result;
    }
}