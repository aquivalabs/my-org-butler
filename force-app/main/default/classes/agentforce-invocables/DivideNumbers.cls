public with sharing class DivideNumbers {
    
    @InvocableMethod(label='Divide Numbers' description='Divides the first number by the second number')
    public static List<Output> execute(List<Input> inputs) {
        Input input = inputs[0];
        if (input.number2 == 0) {
            throw new ApplicationException('Cannot divide by zero');
        }
        Output output = new Output();
        output.result = input.number1 / input.number2;
        return new List<Output>{ output };
    }

    // INNER

    public class Input {
        @InvocableVariable(label='First Number' description='Number to be divided (dividend)' required=true)
        public Decimal number1;

        @InvocableVariable(label='Second Number' description='Number to divide by (divisor)' required=true)
        public Decimal number2;
    }

    public class Output {
        @InvocableVariable(label='Quotient' description='The result of dividing the first number by the second')
        public Decimal result;
    }
}