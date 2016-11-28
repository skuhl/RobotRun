package expression;

import java.util.ArrayList;
import java.util.EmptyStackException;
import java.util.Stack;
import java.util.regex.Pattern;

import geom.Point;
import programming.RegStmtPoint;
import regs.PositionType;
import robot.RobotRun;

/**
 * This class is designed to save an arithmetic expression for a register statement instruction. Register statements include the
 * folllowing operands: floating-point constants, Register values, Position Register points, and Position Register values. Legal
 * operators for these statements include addition(+), subtraction(-), multiplication(*), division(/), modulus(%), integer
 * division(|), and parenthesis(). An expression is evaluated left to right, ignoring any operation prescendence, save for
 * parenthesis, whose contents are evaluated first. An expression will have a maximum of 5 operators (discluding closing parenthesis).
 * 
 * All valid operands should extend the Operand interface, which simply has a method to get the value of the operand. Constant operands
 * hold a single floating-point constants. Register operands holds an index for a specific Data register entry. Position operands hold
 * and index for a specific position (or Position register), a position index, and a position type. A Position operands type determines
 * if the operands represents a global Position register entry, or a local position entry of the active program. The position index
 * determines if the entire position value will be used, or if a specific value of the position will be used.
 * 
 * -1    -> use the Point itself
 * 0 - 6 -> use specific value of the Point corresponding to the poisition index
 *
 * Robot Point operands are a place holder for the Robot's current position/orientaion or joint anhles and function similar to a Position
 * operand, whose position index is -1. SubExpression operands hold an entirely inidependent expression.
 *
 *
 * ConstantOp       ->  Constants
 * RobotPositionOp  ->  Robot's current position
 * RegisterOp       ->  Register values
 * PositionOp       ->  Position Register points/values
 */
public class RegisterExpression {
	private final RobotRun robotRun;
	private final ArrayList<Object> parameters;

	/**
	 * Creates an empty expression
	 */
	public RegisterExpression(RobotRun robotRun) {
		this.robotRun = robotRun;
		parameters = new ArrayList<Object>();
	}

	/**
	 * Creates an expression from a String. THe format of the String must strictly
	 * include only the following substrings, wach separating by only spaces:
	 * 
	 * '+', '-', '*', '/',
	 * '%', '|', ')', or '('  -> operators
	 * R[x]                   -> Register operand
	 * P[x]
	 * P[x, y]
	 * PR[x]
	 * PR[x, y]               -> Position operand
	 * LPos
	 * JPos
	 * LPos[x]
	 * JPos[x]                -> Robot Point operand
	 * z                      -> Floating-point value
	 * 
	 * where x and y are positive integer values and
	 * z is a valid Floating-point value
	 * 
	 * @parameter exprString  A String, which contains a valid set of the above
	 *                        substrings, each separated by only spaces
	 * @throws IllegalArgumentException  If anything aside from the parameters
	 *                                   defined above exists in the string
	 */
	public RegisterExpression(RobotRun robotRun, String exprString) throws IllegalArgumentException {
		this.robotRun = robotRun;
		parameters = new ArrayList<Object>();
		// Split all the parameters into individual Strings
		String[] paramList = exprString.split(" ");

		for (String param : paramList) {
			// Parse operator
			if (Pattern.matches("[^0123456789]", param)) {
				switch (param) {
				case "+":
					parameters.add(Operator.ADDTN);
					break;
				case "-":
					parameters.add(Operator.SUBTR);
					break;
				case "*":
					parameters.add(Operator.MULT);
					break;
				case "/":
					parameters.add(Operator.DIV);
					break;
				case "%":
					parameters.add(Operator.MOD);
					break;
				case "|":
					parameters.add(Operator.INTDIV);
					break;
				case "(":
					parameters.add(Operator.PAR_OPEN);
					break;
				case ")":
					parameters.add(Operator.PAR_CLOSE);
					break;
				default:
					throw new IllegalArgumentException( String.format("'%s' is not a valid operator!", param) );
				}

			} else if (Pattern.matches("R\\[[0123456789]+\\]", param)) {
				// Parse Register operand
				String idxVal = param.substring(2, param.length() - 1);
				int idx = Integer.parseInt(idxVal);
				parameters.add(new RegisterOp(robotRun, idx));

			} else if (Pattern.matches("P\\[[0123456789]+\\]", param)) {
				// Parse Position operand (local)
				String idxVal = param.substring(2, param.length() - 1);
				int idx = Integer.parseInt(idxVal);
				parameters.add(new PositionOp(robotRun, idx, PositionType.LOCAL));

			} else if (Pattern.matches("P\\[[0123456789]+,[0123456789]+\\]", param)) {
				// Parse Position operand (local, value)
				int commaIdx = param.indexOf(',');
				String idxVal = param.substring(2, commaIdx),
						pdxVal = param.substring(commaIdx + 1, param.length() - 1);
				int idx = Integer.parseInt(idxVal);
				int pdx = Integer.parseInt(pdxVal);
				parameters.add(new PositionOp(robotRun, idx, pdx, PositionType.LOCAL));

			} else if (Pattern.matches("PR\\[[0123456789]+\\]", param)) {
				// Parse Position operand (global)
				String idxVal = param.substring(3, param.length() - 1);
				int idx = Integer.parseInt(idxVal);
				parameters.add(new PositionOp(robotRun, idx, PositionType.GLOBAL));

			} else if (Pattern.matches("PR\\[[0123456789]+,[0123456789]+\\]", param)) {
				// Parse Position operand (global, value)
				int commaIdx = param.indexOf(',');
				String idxVal = param.substring(3, commaIdx),
						pdxVal = param.substring(commaIdx + 1, param.length() - 1);
				int idx = Integer.parseInt(idxVal);
				int pdx = Integer.parseInt(pdxVal);
				parameters.add(new PositionOp(robotRun, idx, pdx, PositionType.GLOBAL));

			} else if (param.equals("LPos")) {
				// Parse Robot Point operand (cartesian)
				parameters.add(new RobotPositionOp(robotRun, true));

			} else if (param.equals("LPos")) {
				// Parse Robot Point operand (joint)
				parameters.add(new RobotPositionOp(robotRun, false));

			} else if (Pattern.matches("LPos\\[[0123456789]+\\]", param)) {
				// Parse Robot Point operand (cartesian, value)
				String pdxVal = param.substring(5, param.length() - 1);
				int pdx = Integer.parseInt(pdxVal);
				parameters.add(new RobotPositionOp(robotRun, pdx, true));

			} else if (Pattern.matches("JPos\\[[0123456789]+\\]", param)) {
				// Parse Robot Point operand (joint, value)
				String pdxVal = param.substring(5, param.length() - 1);
				int pdx = Integer.parseInt(pdxVal);
				parameters.add(new RobotPositionOp(robotRun, pdx, false));

			} else {
				// Parse Floating-point value
				try {
					float val = Float.parseFloat(param);
					parameters.add(new ConstantOp(val));

				} catch (NumberFormatException NFEx) {
					throw new IllegalArgumentException( String.format("'%s' is not valid parameter type!", param.toString()) );
				}
			}
		}
	}

	/**
	 * Creates an expression with the given set of operands and operators.
	 */
	public RegisterExpression(RobotRun robotRun, Object... params) {
		this.robotRun = robotRun;
		parameters = new ArrayList<Object>();

		for (Object param : params) {
			addParameter(param);
		}
	}

	/**
	 * Adds the given parameter to the end of this expression
	 */
	public void addParameter(Object param) {

		if (param instanceof SubExpression) {
			// Add a copy of the given SubExpression
			parameters.add( ((SubExpression)param).clone() );

		} else if (param instanceof Operand || param instanceof Operator) {
			parameters.add(param);
		}
	}

	/**
	 * Adds the given parameter to the index in the expression
	 */
	public void addParameter(int idx, Object param) {

		if (param instanceof SubExpression) {
			// Add a copy of the given SubExpression
			parameters.add(idx, ((SubExpression)param).clone() );

		} else if (param instanceof Operand || param instanceof Operator) {
			parameters.add(idx, param);
		}
	}

	/**
	 * Sets the parameter at the given index to the given
	 * new pararmeter, in the expression.
	 */
	public Object setParameter(int idx, Object param) {
		Object oldVal = parameters.get(idx);

		if (param instanceof SubExpression) {
			// Add a copy of the given SubExpression
			parameters.set(idx, ((SubExpression)param).clone() );

		} else if (param instanceof Operand || param instanceof Operator) {
			parameters.set(idx, param);
		}

		return oldVal;
	}

	/**
	 * Removes the parameter at the given index from the expression
	 */
	public Object removeParameter(int idx) {
		return parameters.remove(idx);
	}

	/**
	 * This method will calculate the result of the current expression. The
	 * expression is evaluated from left to right, ignoring normal order of
	 * operations, however, parenthesis do act as normal. Each element is parsed
	 * individually, keeping track of a current resulting value for every single
	 * operation.
	 * If an open parenthesis is found, then the current working
	 * result is saved on the stack and the value is reset.
	 * If an operator is found, then the next value in the list is taken and the
	 * operator's operation is preformed on the current working result and the
	 * next value.
	 * If a closed parenthesis is found, then the current top of the stack value
	 * is taken off of the stack, the next operator is taken from the list of
	 * parameters, and its operation is preformed on the popped value and the
	 * working result.
	 * 
	 * @return
	 *
	 * Once the entire expression is processed and no errors are found, the result
	 * of the expression is returned as either a Floating-point value or a RegStmtPoint
	 * Object, depending on the nature of the expression.
	 *
	 * @throw ExpressionEvaluationException
	 * 
	 * Since, the expressions are only evaluated when a program is executed, it
	 * is possible that the expression may contain errors such as mssing arguments,
	 * invalid operation arguments, and so on. So, these errors are caught by this
	 * method and a new ExpressionEvaluationException is thrown with an error message
	 * indicating what the error was. 
	 */
	public Object evaluate() throws ExpressionEvaluationException {
		// Empty expression
		if (parameters.size() == 0) { return null; }

		try {
			int pdx = 0,
					len = parameters.size();
			Stack<Object> savedOps = new Stack<Object>();
			Object result = null;
			Operator op = Operator.PAR_OPEN;

			while (true) {
				Object param = parameters.get(pdx++);

				while (param == Operator.PAR_OPEN) {
					// Save current result and operator, when entering parenthesis
					savedOps.push(result);
					savedOps.push(op);
					result = null;
					op = Operator.PAR_OPEN;

					param = parameters.get(pdx++);
				}

				if (op == Operator.PAR_OPEN) {
					// Reset result, when entering parenthesis
					result = ((Operand)param).getValue();
				} else {
					result = evaluateOperation(result, ((Operand)param).getValue(), op);
				}

				if (pdx == len) {
					// Operand ends the expression
					return result;
				}

				op = (Operator)( parameters.get(pdx++) );

				while (op == Operator.PAR_CLOSE) {
					// Remove and evaluate saved value-operator pairs, when exiting parenthesis
					param = savedOps.pop();

					if (param == Operator.PAR_OPEN) {
						// Initial/Nested open parenthesis
						param = savedOps.pop();
					} else {
						// Previous result and operator exists
						result = evaluateOperation(savedOps.pop(), result, (Operator)param);
					}

					if (pdx == len) {
						// Parenthesis ends the expression
						return result;
					}

					op = (Operator)( parameters.get(pdx++) );
				}
			}

		} catch (NullPointerException NPEx) {
			// Missing a parameter
			throw new ExpressionEvaluationException(0, NPEx.getClass());

		} catch (IndexOutOfBoundsException IOOBEx) {
			// Invalid register index or missing parameter
			throw new ExpressionEvaluationException(0, IOOBEx.getClass());

		} catch (ClassCastException CCEx) {
			// Illegal parameters or operations
			throw new ExpressionEvaluationException(1, CCEx.getClass());

		} catch (ArithmeticException AEx) {
			// Illegal parameters or operations
			throw new ExpressionEvaluationException(2, AEx.getClass());

		} catch (EmptyStackException ESEx) {
			// Invalid parenthesis
			throw new ExpressionEvaluationException(3, ESEx.getClass());

		}
	}

	/**
	 * Evaluate the given parameters with the given operation. The only valid parameters are floating-point values
	 * and int arrays. The integer arrays should singeltons (for Registers) or tripletons (for Position Registers
	 * and Position Register Values).
	 * 
	 * @param param1  The first parameter of the opertion
	 * @param param2  The second parameter for the operation
	 * @param op      The operation to preform on the parameters
	 * @return        The result of the operation on param1 and param2
	 * 
	 * @throws ExpressionEvaluationException  if the given combination of parameters with the given
	 *                                        operation is illegal
	 */
	private Object evaluateOperation(Object a, Object b, Operator op) {
		if (a instanceof Float && b instanceof Float) {
			// Float-Float operation
			return evaluateFloatOperation((Float)a, (Float)b, op);
		} else if (a instanceof Point && b instanceof Point) {
			// Point-Point operation
			return evaluePointOperation((RegStmtPoint)a, (RegStmtPoint)b, op);
		}
		// Illegal operation
		throw new ExpressionEvaluationException(4);
	}

	private Float evaluateFloatOperation(Float a, Float b, Operator op) {
		// Float-to-Float operations
		switch(op) {
		case ADDTN:  return a + b;
		case SUBTR:  return a - b;
		case MULT:   return a * b;
		case DIV:    return a / b;
		case MOD:    return a % b;
		case INTDIV: return new Float(a.intValue() / b.intValue());
		default:
		}
		// Illegal operator
		throw new ExpressionEvaluationException(5);
	}

	private RegStmtPoint evaluePointOperation(RegStmtPoint a, RegStmtPoint b, Operator op) {
		// Point-to-Point operations
		switch(op) {
		case ADDTN:
			return a.add(b);
		case SUBTR:
			return a.subtract(b);
		default:
		}
		// Illegal operator
		throw new ExpressionEvaluationException(6);
	}

	/**
	 * Returns the number of operators AND operands in the expression
	 */
	public int parameterSize() { return parameters.size(); }

	/**
	 * Returns a list of the parameters in the expression, each in the
	 * form of a String and occupying individual elements in the list.
	 * 
	 * @returning  The list of parameters in the form of Strings
	 */
	public ArrayList<String> toStringArrayList() {
		ArrayList<String> paramList = new ArrayList<String>();

		for (Object param : parameters) {

			if (param == null) {
				paramList.add("_");
			} else {
				paramList.add(param.toString());
			}
		}

		return paramList;
	}

	/**
	 * Copies the current expression (cloning sub expressions) and
	 * returns the a new Expression with the duplicate set of parameters.
	 * 
	 * @returning  A copy of the this expression
	 */
	public RegisterExpression clone() {
		RegisterExpression copy = new RegisterExpression(robotRun);

		for (Object param : parameters) {

			if (param instanceof Operand) {
				copy.addParameter(((Operand)param).clone());
			} else {
				copy.addParameter(param);
			}
		}

		return copy;
	}

	public String toString() {
		String expressionString = new String();
		ArrayList<String> paramSet = toStringArrayList();

		for (int pdx = 0; pdx < paramSet.size(); ++pdx) {
			// Combine the list of parameter Strings, separating each by a single space
			expressionString += paramSet.get(pdx);

			if (pdx < (paramSet.size() - 1)) {
				expressionString += " ";
			}
		}

		return expressionString;
	}
}