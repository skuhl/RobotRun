package screen.cnfrm_cncl;

import core.RobotRun;
import enums.ScreenMode;
import screen.Screen;

public abstract class ST_ScreenConfirmCancel extends Screen {

	public ST_ScreenConfirmCancel(ScreenMode m, RobotRun r) {
		super(m, r);
	}
	
	@Override
	protected String loadHeader() {
		return robotRun.getActiveProg().getName();
	}
	
	@Override
	protected void loadContents() {}
	
	@Override
	protected void loadLabels() {
		// F4, F5
		labels[0] = "";
		labels[1] = "";
		labels[2] = "";
		labels[3] = "[Confirm]";
		labels[4] = "[Cancel]";
	}
	
	@Override
	protected void loadVars() {}
		
	@Override
	public void actionUp() {}
	
	@Override
	public void actionDn() {}
	
	@Override
	public void actionLt() {}
	
	@Override
	public void actionRt() {}
	
	@Override
	public void actionEntr() {}
	
	@Override
	public void actionF1() {}
	
	@Override
	public void actionF2() {}
	
	@Override
	public void actionF3() {}
	
	@Override
	public void actionF4() {}
	
	@Override
	public void actionF5() {}

}