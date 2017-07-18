package frame;

import geom.Point;
import geom.RMatrix;
import geom.RQuaternion;
import global.Fields;
import global.MyFloatFormat;
import global.RMath;
import processing.core.PVector;

/**
 * Defines user frames associated with a robotic arm.
 * 
 * @author Joshua Hooker
 */
public class UserFrame {
	
	/**
	 * The name associated with this frame.
	 */
	private String name;
	
	/**
	 * The origin of this frame's coordinate frame.
	 */
	private PVector originOffset;
	
	/**
	 * The orientation of this frame's coordinate frame.
	 */
	private RQuaternion orienOffset;
	
	/**
	 * The set of taught and untaught points for this frame's point teaching
	 * methods. A user frame has a maximum of 4 points that can be taught
	 * (three for orientation and one for the origin).
	 */
	private Point[] teachPoints;
	
	/**
	 * The last origin taught as a direct entry for this frame.
	 */
	private PVector originDirect;
	
	/**
	 * The last orientation offset taught as a direct entry for this frame.
	 */
	private RQuaternion orienDirect;

	/**
	 * Initialize all fields to their default values.
	 */
	public UserFrame() {
		name = "";
		originOffset = new PVector(0f, 0f, 0f);
		orienOffset = new RQuaternion();
		teachPoints = new Point[] { null, null, null, null };
		originDirect = new PVector(0f, 0f, 0f);
		orienDirect = new RQuaternion();
	}
	
	/**
	 * Defines a user frame with the given fields.
	 * 
	 * @param name			The name associated with the frame
	 * @param originOffset	The current origin offset of this frame
	 * @param orienOffset	The current orientation offset of this frame
	 * @param teachPoints	The set of taught and untaught points for this
	 * 						frame (must be of length 4)
	 * @param originDirect	The last origin taught to this frame with the
	 * 						direct entry method
	 * @param orienDirect	The last orientation taught to this with the direct
	 * 						entry method
	 */
	public UserFrame(String name, PVector originOffset, RQuaternion orienOffset,
			Point[] teachPoints, PVector originDirect, RQuaternion orienDirect) {
		
		this.name = name;
		this.originOffset = originOffset;
		this.orienOffset = orienOffset;
		this.teachPoints = teachPoints;
		this.originDirect = originDirect;
		this.orienDirect = orienDirect;
	}
	
	/**
	 * Similar to toStringArray, however, it converts the Frame's direct entry
	 * values instead of the current origin and axes of the Frame.
	 * 
	 * @returning  A 6x2-element String array
	 */
	public String[][] directEntryStringArray() {
		String[][] entries = new String[6][2];
		PVector originDirect = getOriginDirect();
		RQuaternion orienDirect = getOrienDirect();
		PVector xyz, wpr;

		if (originDirect == null) {
			xyz = new PVector(0f, 0f, 0f);
			
		} else {
			// Use previous value if it exists
			xyz = RMath.vToWorld(originDirect);
		}

		if (orienDirect == null) {
			wpr = new PVector(0f, 0f, 0f);
			
		} else {
			// Display in degrees
			wpr = RMath.nQuatToWEuler(orienDirect);
		}

		entries[0][0] = "X: ";
		entries[0][1] = String.format("%4.3f", xyz.x);
		entries[1][0] = "Y: ";
		entries[1][1] = String.format("%4.3f", xyz.y);
		entries[2][0] = "Z: ";
		entries[2][1] = String.format("%4.3f", xyz.z);
		// Display in terms of the World frame
		entries[3][0] = "W: ";
		entries[3][1] = String.format("%4.3f", wpr.x);
		entries[4][0] = "P: ";
		entries[4][1] = String.format("%4.3f", wpr.y);
		entries[5][0] = "R: ";
		entries[5][1] = String.format("%4.3f", wpr.z);

		return entries;
	}
	
	/**
	 * Returns the name associated with this frame
	 * 
	 * @return	This frame's name
	 */
	public String getName() {
		return name;
	}
	
	/**
	 * Returns this frame's orientation offset as a rotation matrix.
	 * 
	 * @return	The orientation offset of this frame
	 */
	public RMatrix getNativeAxisVectors() {
		return orienOffset.toMatrix();
	}
	
	/**
	 * Returns the last orientation taught to this frame with the direct entry
	 * method.
	 * 
	 * @return	The last direct entry orientation offset taught
	 */
	public RQuaternion getOrienDirect() {
		return orienDirect;
	}
	
	/**
	 * Returns the current orientation offset of this frame.
	 * 
	 * @return	This frame's orientation offset
	 */
	public RQuaternion getOrientation() {
		return orienOffset;
	}
	
	/**
	 * Returns the last origin taught to this frame with the direct entry
	 * method.
	 * 
	 * @return	the last direct entry origin taught
	 */
	public PVector getOriginDirect() {
		return originDirect;
	}
	
	/**
	 * Returns the current origin of this frame.
	 * 
	 * @return	This frame's origin
	 */
	public PVector getOrigin() {
		return originOffset;
	}

	/**
	 * TODO comment this
	 * 
	 * @param idx
	 * @return
	 */
	public Point getTeachPt(int idx) {

		if (idx >= 0 && idx < teachPoints.length) {
			return teachPoints[idx];
		}

		return null;
	}
	
	/**
	 * TODO comment this
	 * 
	 * @return
	 */
	public boolean is3PtComplete() {
		// Check if all points are taught for the three point method
		return teachPoints[0] != null && teachPoints[1] != null &&
				teachPoints[2] != null;
	}
	
	/**
	 * TODO comment this
	 * 
	 * @return
	 */
	public boolean is4PtComplete() {
		// Check if all points are taught for the fourth point method
		return teachPoints[0] != null && teachPoints[1] != null &&
				teachPoints[2] != null && teachPoints[3] != null;
	}

	/**
	 * TODO comment this
	 */
	public void reset() {
		name = "";
		originOffset.x = 0f;
		originOffset.y = 0f;
		originOffset.z = 0f;
		orienOffset.setValue(0, 1f);
		orienOffset.setValue(1, 0f);
		orienOffset.setValue(2, 0f);
		orienOffset.setValue(3, 0f);
		setTeachPt(null, 0);
		setTeachPt(null, 1);
		setTeachPt(null, 2);
		setTeachPt(null, 3);
		originDirect.x = 0f;
		originDirect.y = 0f;
		originDirect.z = 0f;
		orienDirect.setValue(0, 1f);
		orienDirect.setValue(1, 0f);
		orienDirect.setValue(2, 0f);
		orienDirect.setValue(3, 0f);
	}
	
	/**
	 * TODO comment this
	 * 
	 * @param newName
	 */
	public void setName(String newName) {
		name = newName;
	}
	
	/**
	 * TODO comment this
	 * 
	 * @param newOrien
	 */
	public void setOrienDirect(RQuaternion newOrien) {
		orienDirect = newOrien;
	}
	
	/**
	 * TODO comment this
	 * 
	 * @param newOrien
	 */
	public void setOrienOffset(RQuaternion newOrien) {
		orienOffset = newOrien;
	}
	
	/**
	 * TODO comment this
	 * 
	 * @param newOrigin
	 */
	public void setOriginDirect(PVector newOrigin) {
		originDirect = newOrigin;
	}
	
	/**
	 * TODO comment this
	 * 
	 * @param newOrigin
	 */
	public void setOrigin(PVector newOrigin) {
		originOffset = newOrigin;
	}

	/**
	 * TODO comment this
	 * 
	 * @param pt
	 * @param idx
	 */
	public void setTeachPt(Point pt, int idx) {
		if (idx >= 0 && idx < teachPoints.length) {
			teachPoints[idx] = pt;
		}
	}
	
	/**
	 * TODO comment this
	 * 
	 * @return
	 */
	public boolean teach3Pt() {
		if (is3PtComplete()) {
			Point pt0 = getTeachPt(0);
			Point pt1 = getTeachPt(1);
			Point pt2 = getTeachPt(2);
			// Form the orientation offset from the taught points
			RMatrix axesOffset = Fields.createAxesFromThreePoints(pt0.position,
					pt1.position, pt2.position);
			
			if (axesOffset != null) {
				// Set frame offsets
				setOrigin(pt0.position);
				setOrienOffset( RMath.matrixToQuat(axesOffset) );
				return true;
			}
		}
		
		return false;
	}
	
	/**
	 * TODO comment this
	 * 
	 * @return
	 */
	public boolean teach4Pt() {
		if (is4PtComplete()) {
			Point pt0 = getTeachPt(0);
			Point pt1 = getTeachPt(1);
			Point pt2 = getTeachPt(2);
			// Form the orientation offset from the taught points
			RMatrix axesOffset = Fields.createAxesFromThreePoints(pt0.position,
					pt1.position, pt2.position);
			
			if (axesOffset != null) {
				// Set frame offsets
				setOrigin(getTeachPt(3).position);
				setOrienOffset( RMath.matrixToQuat(axesOffset) );
				return true;
			}
		}
		
		return false;
	}
	
	/**
	 * TODO comment this
	 * 
	 * @return
	 */
	public boolean teachDirectEntry() {
		if (originDirect != null && orienDirect != null) {
			// Set frame offsets
			setOrigin(getOriginDirect().copy());
			setOrienOffset(getOrienDirect().clone());
			return true;
		}
		
		return false;
	}
	
	/**
	 * Converts the original toStringArray into a 2x1 String array, where the origin
	 * values are in the first element and the W, P, R values are in the second
	 * element (or in the case of a joint angles, J1-J3 on the first and J4-J6 on
	 * the second), where each element has space buffers.
	 * 
	 * @param displayCartesian  whether to display the joint angles or the cartesian
	 *                          values associated with the point
	 * @returning               A 2-element String array
	 */
	public String[] toLineStringArray() {
		String[] entries = toStringArray();
		String[] line = new String[2];
		// X, Y, Z with space buffers
		line[0] = String.format("%-12s %-12s %s", entries[0], entries[1], entries[2]);
		// W, P, R with space buffers
		line[1] = String.format("%-12s %-12s %s", entries[3], entries[4], entries[5]);

		return line;
	}

	/**
	 * Returns a string array, where each entry is one of
	 * the User frame's origin or orientation values:
	 * (X, Y, Z, W, P, and R) and their respective labels.
	 *
	 * @return  A 6-element String array
	 */
	public String[] toStringArray() {
		String[] values = new String[6];
		
		// Convert to world frame reference
		PVector displayOrigin = RMath.vToWorld(originOffset);
		/* Convert orientation in to euler angles, in degree, with reference
		 * to the world frame */
		PVector wpr = RMath.nQuatToWEuler(orienOffset);

		values[0] = MyFloatFormat.format(displayOrigin.x);
		values[1] = MyFloatFormat.format(displayOrigin.y);
		values[2] = MyFloatFormat.format( displayOrigin.z);
		values[3] = MyFloatFormat.format(wpr.x);
		values[4] = MyFloatFormat.format(wpr.y);
		values[5] = MyFloatFormat.format(wpr.z);

		return values;
	}
}
