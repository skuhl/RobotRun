package screen;

import core.RobotRun;
import enums.ScreenMode;
import programming.Instruction;
import programming.Program;

public class ScreenFindReplace extends ST_ScreenTextEntry {

	public ScreenFindReplace(RobotRun r) {
		super(ScreenMode.FIND_REPL, r);
	}
	
	@Override
	String loadHeader() {
		return robotRun.getActiveProg().getName();
	}
	
	@Override
	void loadContents() {
		contents.setLines(robotRun.loadInstructions(robotRun.getActiveProg()));
	}
	
	@Override
	void loadOptions() {
		options.addLine("Enter text to search for:");
		options.addLine("\0" + workingText);
	}
	
	@Override
	void loadLabels() {
		// F4, F5
		labels[0] = "";
		labels[1] = "";
		labels[2] = "";
		labels[3] = "[Confirm]";
		labels[4] = "[Cancel]";
	}

	@Override
	public void actionEntr() {
		robotRun.lastScreen();
	}
	
	@Override
	public void actionF1() {}

	@Override
	public void actionF2() {}
	
	@Override
	public void actionF3() {}
	
	@Override
	public void actionF4() {
		Program p = robotRun.getActiveProg();
		int lineIdx = 0;
		String s;

		for (Instruction instruct : p) {
			s = (lineIdx + 1) + ") " + instruct.toString();

			if (s.toUpperCase().contains(workingText.toString().toUpperCase())) {
				break;
			}

			lineIdx += 1;
		}

		robotRun.getScreenStates().pop();
		robotRun.setActiveInstIdx(lineIdx);
		robotRun.updateInstructions();
	}
	
	@Override
	public void actionF5() {
		robotRun.getScreenStates().pop();
		robotRun.updateInstructions();
	}
}