package screen.edit_item;

import core.RobotRun;
import expression.OperandBool;
import robot.RoboticArm;
import screen.ScreenMode;
import screen.ScreenState;

public class ScreenSetBoolConst extends ST_ScreenEditItem {

	public ScreenSetBoolConst(ScreenState prevState, RobotRun r) {
		super(ScreenMode.SET_BOOL_CONST, prevState, r);
	}
	
	@Override
	protected void loadOptions() {
		options.addLine("1. False");
		options.addLine("2. True");
	}

	@Override
	public void actionEntr() {
		RoboticArm r = robotRun.getActiveRobot();
		r.getInstToEdit(robotRun.getActiveProg(), robotRun.getActiveInstIdx());
		
		if (options.getLineIdx() == 0) {
			((OperandBool)robotRun.opEdit).setValue(true);
		} else {
			((OperandBool)robotRun.opEdit).setValue(false);
		}

		robotRun.lastScreen();
	}
}
