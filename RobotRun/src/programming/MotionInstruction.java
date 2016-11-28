package programming;
import frame.Frame;
import frame.FrameFile;
import geom.Point;
import global.Fields;
import regs.*;
import robot.ArmModel;
import robot.RobotRun;

public final class MotionInstruction extends Instruction  {
	
	private final RobotRun robotRun;
	private int motionType;
	private int positionNum;
	private int offsetRegNum;
	private boolean offsetActive;
	private boolean isGPosReg;
	private float speed;
	private int termination;
	private int userFrame;
	private int toolFrame;
	private MotionInstruction circSubInstr;

	public MotionInstruction(RobotRun robotRun, int m, int p, boolean g, 
			float s, int t, int uf, int tf) {
		this.robotRun = robotRun;
		motionType = m;
		positionNum = p;
		offsetRegNum = -1;
		offsetActive = false;
		isGPosReg = g;
		speed = s;
		termination = t;
		userFrame = uf;
		toolFrame = tf;
		if(motionType != -1) {
			circSubInstr = new MotionInstruction(this.robotRun, -1, -1, false, 100, 0, uf, tf);
		} else {
			circSubInstr = null;
		}
	}

	public MotionInstruction(RobotRun robotRun, int m, int p, boolean g, float s, int t) {
		this.robotRun = robotRun;
		motionType = m;
		positionNum = p;
		offsetRegNum = -1;
		offsetActive = false;
		isGPosReg = g;
		speed = s;
		termination = t;
		userFrame = -1;
		toolFrame = -1;
		if(motionType != -1) {
			circSubInstr = new MotionInstruction(this.robotRun, -1, -1, false, 100, 0);
		} else {
			circSubInstr = null;
		}
	}

	public int getMotionType() { return motionType; }
	public void setMotionType(int in) { motionType = in; }
	public int getPositionNum() { return positionNum; }
	public void setPositionNum(int in) { positionNum = in; }  
	public int getOffset() { return offsetRegNum; }
	public void setOffset(int in) { offsetRegNum = in; }
	public boolean toggleOffsetActive() { return (offsetActive = !offsetActive); }
	public boolean usesGPosReg() { return isGPosReg; }
	public void setGlobalPosRegUse(boolean in) { isGPosReg = in; }
	public float getSpeed() { return speed; }
	public void setSpeed(float in) { speed = in; }
	public int getTermination() { return termination; }
	public void setTermination(int in) { termination = in; }
	public int getUserFrame() { return userFrame; }
	public void setUserFrame(int in) { userFrame = in; }
	public int getToolFrame() { return toolFrame; }
	public void setToolFrame(int in) { toolFrame = in; }
	public MotionInstruction getSecondaryPoint() { return circSubInstr; }
	public void setSecondaryPoint(MotionInstruction p) { circSubInstr = p; }

	public float getSpeedForExec(ArmModel model) {
		if(motionType == this.robotRun.MTYPE_JOINT) return speed;
		else return (speed / model.motorSpeed);
	}

	/**
	 * Verify that the given frame indices match those of the
	 * instructions frame indices.
	 */
	public boolean checkFrames(int activeToolIdx, int activeFrameIdx) {
		return (toolFrame == activeToolIdx) && (userFrame == activeFrameIdx);
	}

	/**
	 * Returns the unmodified point that is associate
	 * with this motion instruction.
	 *
	 * @param parent  The program to which this
	 *                instruction belongs
	 */
	public Point getPoint(Program parent) {
		Point pt = null;

		if (isGPosReg) {
			pt = ((PositionRegister)RegisterFile.getPReg(positionNum)).point;   

		} else if(positionNum != -1) {
			pt = parent.LPosReg.get(positionNum);
		}

		if (pt != null) {
			return pt.clone();
		}

		return null;
	}

	/**
	 * Returns the point associated with this motion instruction
	 * (can be either a position in the program or a global position
	 * register value) in Native Coordinates.
	 * 
	 * @param parent  The program, to which this instruction belongs
	 * @returning     The point associated with this instruction
	 */
	public Point getVector(Program parent) {
		Point pt;
		Point offset;

		pt = getPoint(parent);
		if(pt == null) return null;

		if(offsetRegNum != -1) {
			offset = ((PositionRegister)RegisterFile.getPReg(offsetRegNum)).point;
		} else {
			offset = new Point(this.robotRun);
		}

		if (userFrame != -1) {
			// Convert point into the Native Coordinate System
			Frame active = FrameFile.getUFrame(userFrame);
			pt = this.robotRun.removeFrame(pt, active.getOrigin(), active.getOrientation());
		}

		return pt.add(offset);
	} // end getVector()

	public Instruction clone() {
		Instruction copy = new MotionInstruction(this.robotRun, motionType, positionNum, isGPosReg, speed, termination, userFrame, toolFrame);
		copy.setIsCommented( isCommented() );

		return copy;
	}

	public String[] toStringArray() {
		String[] fields;
		int instrLen, subInstrLen;

		if(motionType == this.robotRun.MTYPE_CIRCULAR) {
			instrLen = offsetActive ? 7 : 6;
			subInstrLen = circSubInstr.offsetActive ? 5 : 4;      
			fields = new String[instrLen + subInstrLen];
		} else {
			instrLen = offsetActive ? 6 : 5;
			subInstrLen = 0;
			fields = new String[instrLen];
		}

		// Motion type
		switch(motionType) {
		case Fields.MTYPE_JOINT:
			fields[0] = "J";
			break;
		case Fields.MTYPE_LINEAR:
			fields[0] = "L";
			break;
		case Fields.MTYPE_CIRCULAR:
			fields[0] = "C";
			break;
		default:
			fields[0] = "\0";
		}

		// Regster type
		if (isGPosReg) {
			fields[1] = "PR[";
		} else {
			fields[1] = "P[";
		}

		// Register index
		if(positionNum == -1) {
			fields[2] = "...]";
		} else {
			fields[2] = String.format("%d]", positionNum + 1);
		}

		// Speed
		if (motionType == this.robotRun.MTYPE_JOINT) {
			fields[3] = String.format("%d%%", Math.round(speed * 100));
		} else {
			fields[3] = String.format("%dmm/s", (int)(speed));
		}

		// Termination percent
		if (termination == 0) {
			fields[4] = "FINE";
		} else {
			fields[4] = String.format("CONT%d", termination);
		}

		if(offsetActive) {
			if(offsetRegNum == -1) {
				fields[5] = "OFST PR[...]";
			} else {
				fields[5] = String.format("OFST PR[%d]", offsetRegNum + 1);
			}
		}

		if(motionType == this.robotRun.MTYPE_CIRCULAR) {
			String[] secondary = circSubInstr.toStringArray();
			fields[instrLen - 1] = "\n";
			fields[instrLen] = ":" + secondary[1];
			fields[instrLen + 1] = secondary[2];
			fields[instrLen + 2] = secondary[3];
			fields[instrLen + 3] = secondary[4];
			if(subInstrLen > 4) {
				fields[instrLen + 4] = secondary[5];
			}
		}

		return fields;
	}
} // end MotionInstruction class