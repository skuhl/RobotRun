package screen;

import window.DisplayMode;

public enum ScreenType implements DisplayMode {
	TYPE_DEFAULT,
	TYPE_OPT_MENU,
	TYPE_LINE_SELECT,
	TYPE_LIST_CONTENTS,
	TYPE_CONFIRM_CANCEL,
	TYPE_INSTRUCT_EDIT,
	TYPE_EXPR_EDIT,
	TYPE_TEACH_POINTS,
	TYPE_TEXT_ENTRY,
	TYPE_NUM_ENTRY,
	TYPE_POINT_ENTRY;
}