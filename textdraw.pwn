#include <a_samp>

#define FILTERSCRIPT

#include <YSI\y_commands>

#define MAX_TEXTDRAWS 				(100)
#define MAX_TEXTDRAW_STRING_LENGTH 	(128)

#define DIALOG_MAIN_MENU	    	(13573)
#define DIALOG_TEXTDRAW_MAIN	    (13574)
#define DIALOG_SET_TEXT	    		(13575)
#define DIALOG_POSITION	    		(13576)
#define DIALOG_POSITION_INPUT	   	(13577)
#define DIALOG_FONT	    			(13578)
#define DIALOG_FONT_SIZE	    	(13579)
#define DIALOG_FONT_SIZE_INPUT	   	(13580)
#define DIALOG_ALIGNMENT	    	(13581)
#define DIALOG_FONT_COLOR	    	(13582)
#define DIALOG_FONT_COLOR_INPUT	   	(13583)
#define DIALOG_BOX_OPTION	    	(13584)
#define DIALOG_BOX_SIZE	    		(13585)
#define DIALOG_BOX_SIZE_INPUT	   	(13586)
#define DIALOG_BOX_COLOR	    	(13587)
#define DIALOG_BOX_COLOR_INPUT	   	(13588)
#define DIALOG_OUTLINE_OPTION	   	(13589)
#define DIALOG_OUTLINE_SIZE	    	(13590)
#define DIALOG_SHADOW_SIZE	    	(13591)
#define DIALOG_OUTLINE_COLOR	   	(13592)
#define DIALOG_OUTLINE_COLOR_INPUT	(13593)
#define DIALOG_PREDEFINED_COLOR     (13594)

#define forex(%0,%1) for(new %0 = 0; %0 < %1; %0++)
#define IsNull(%1) ((!(%1[0])) || (((%1[0]) == '\1') && (!(%1[1]))))
#define RGBAToInt(%0,%1,%2,%3) ((16777216 * (%0)) + (65536 * (%1)) + (256 * (%2)) + (%3))

forward EditorTimer();

new EditTimer;

enum textdrawinfo
{
	Text:ID,
	Float:Pos[2],
	Font,
	Text[MAX_TEXTDRAW_STRING_LENGTH],
	Float:LetterSize[2],
	Float:TextSize[2],
	Alignment,
	TextColor,
	UseBox,
	BoxColor,
	ShadowSize,
	OutlineSize,
	OutlineColor,
	Proportional,
	Selectable,
	PreviewModel,
	Float:PreviewRotation[3],
	Float:PreviewZoom,
	PreviewColor[2],
}
new TextdrawInfo[MAX_TEXTDRAWS][textdrawinfo];

enum definedcolor
{
	Name[16],
	Color,
}
new PredefinedColors[][definedcolor] = {
{"Black",0x000000FF},
{"White",0xFFFFFFFF},
{"Red",0xFF0000FF},
{"Lime",0x00FF00FF},
{"Green",0x66AA66FF},
{"Blue",0x0000FFFF},
{"Yellow",0xFFFF00FF},
{"Purple",0xFF00FFFF},
{"Cyan",0x00FFFFFF},
};

#pragma unused PredefinedColors

stock strtok(const string[], &index)
{
	new length = strlen(string);
	while ((index < length) && (string[index] <= ' '))
	{
		index++;
	}

	new offset = index;
	new result[20];
	while ((index < length) && (string[index] > ' ') && ((index - offset) < (sizeof(result) - 1)))
	{
		result[index - offset] = string[index];
		index++;
	}
	result[index - offset] = EOS;
	return result;
}

stock ShowMainMenu(playerid)
{
    new string[2048];
	strcat(string,"Create Textdraw",sizeof(string));
	forex(i,MAX_TEXTDRAWS)
	{
	    if(TextdrawInfo[i][ID] == INVALID_TEXT_DRAW) continue;
	    else
	    {
	        if(TextdrawInfo[i][Font] == 4)
	        {
	            format(string,sizeof(string),"%s\nSprite:\t%16s",string,TextdrawInfo[i][Text]);
	        }
	        else if(TextdrawInfo[i][Font] == 5)
	        {
	            format(string,sizeof(string),"%s\nModel:\t%d",string,TextdrawInfo[i][PreviewModel]);
	        }
	        else
	        {
	            format(string,sizeof(string),"%s\nText:\t%16s",string,TextdrawInfo[i][Text]);
	        }
	    }
	}
	ShowPlayerDialog(playerid,DIALOG_MAIN_MENU,DIALOG_STYLE_LIST,"Main Menu",string,"Select","Exit");
	return 1;
}
stock ShowTextdrawMenu(playerid)
{
	new textdrawid = GetPVarInt(playerid,"EditTD");
	if(TextdrawInfo[textdrawid][Font] == 4)
	{
	    ShowPlayerDialog(playerid,DIALOG_TEXTDRAW_MAIN,DIALOG_STYLE_LIST,"Textdraw Options","Sprite\nPosition\nFont\nColor\nSize\nDuplicate\nTest Select\nDelete","Select","Back");
	}
	else if(TextdrawInfo[textdrawid][Font] == 5)
	{
	    ShowPlayerDialog(playerid,DIALOG_TEXTDRAW_MAIN,DIALOG_STYLE_LIST,"Textdraw Options","Model\nPosition\nFont\nColor\nBackground Color\nSize\nRotation & Zoom\nModel Color (Vehicle model only)\nDuplicate\nTest Select\nDelete","Select","Back");
	}
	else
	{
	    ShowPlayerDialog(playerid,DIALOG_TEXTDRAW_MAIN,DIALOG_STYLE_LIST,"Textdraw Options","Text\nPosition\nFont\nFont Size\nAlignment\nFont Color\nBox\nOutline\nProportional\nDuplicate\nTest Select\nDelete","Select","Back");
	}
	return 1;
}

stock GetTextdrawFreeSlot()
{
	forex(i,MAX_TEXTDRAWS)
	{
	    if(TextdrawInfo[i][ID] == INVALID_TEXT_DRAW)
	    {
	        return i;
	    }
	}
	return -1;
}
stock CreateTextdraw(Float:x,Float:y,text[])
{
	new textdrawid = GetTextdrawFreeSlot();
	if(textdrawid == -1) return -1;
	TextdrawInfo[textdrawid][ID] = TextDrawCreate(x,y,text);
	TextdrawInfo[textdrawid][Pos][0] = x;
	TextdrawInfo[textdrawid][Pos][1] = y;
	strmid(TextdrawInfo[textdrawid][Text],text,0,strlen(text),MAX_TEXTDRAW_STRING_LENGTH);
	SetTextdrawFont(textdrawid,3);
	SetTextdrawFontSize(textdrawid,0.5,1.0);
	SetTextdrawSize(textdrawid,10.0,140.0);
	SetTextdrawAlignment(textdrawid,2);
	SetTextdrawColor(textdrawid,0xFFFFFFFF);
	ToggleTextdrawBox(textdrawid,0);
	SetTextdrawBoxColor(textdrawid,0x000000AA);
	SetTextdrawShadow(textdrawid,0);
	SetTextdrawOutline(textdrawid,1);
	SetTextdrawOutlineColor(textdrawid,0x000000FF);
	ToggleTextdrawProportional(textdrawid,1);
	ToggleTextdrawSelectable(textdrawid,1);
	SetTextdrawPreviewModel(textdrawid,1337);
	SetTextdrawPreviewRot(textdrawid,0.0,0.0,0.0,1.0);
	SetTextdrawPreviewVehCol(textdrawid,1,1);
	TextDrawShowForAll(TextdrawInfo[textdrawid][ID]);
	return textdrawid;
}
stock SetTextdrawString(textdrawid,text[])
{
    strmid(TextdrawInfo[textdrawid][Text],text,0,strlen(text),MAX_TEXTDRAW_STRING_LENGTH);
    TextDrawSetString(TextdrawInfo[textdrawid][ID],text);
    return 1;
}
stock SetTextdrawPosition(textdrawid,Float:x,Float:y)
{
    TextdrawInfo[textdrawid][Pos][0] = x;
	TextdrawInfo[textdrawid][Pos][1] = y;
	TextDrawDestroy(TextdrawInfo[textdrawid][ID]);
	TextdrawInfo[textdrawid][ID] = TextDrawCreate(x,y,TextdrawInfo[textdrawid][Text]);
	TextDrawFont(TextdrawInfo[textdrawid][ID],TextdrawInfo[textdrawid][Font]);
	TextDrawTextSize(TextdrawInfo[textdrawid][ID],TextdrawInfo[textdrawid][TextSize][0],TextdrawInfo[textdrawid][TextSize][1]);
	TextDrawColor(TextdrawInfo[textdrawid][ID],TextdrawInfo[textdrawid][TextColor]);
	if(TextdrawInfo[textdrawid][Font] < 4)
	{
	    TextDrawLetterSize(TextdrawInfo[textdrawid][ID],TextdrawInfo[textdrawid][LetterSize][0],TextdrawInfo[textdrawid][LetterSize][1]);
	    TextDrawAlignment(TextdrawInfo[textdrawid][ID],TextdrawInfo[textdrawid][Alignment]);
	    TextDrawUseBox(TextdrawInfo[textdrawid][ID],TextdrawInfo[textdrawid][UseBox]);
		TextDrawBoxColor(TextdrawInfo[textdrawid][ID],TextdrawInfo[textdrawid][BoxColor]);
		TextDrawSetShadow(TextdrawInfo[textdrawid][ID],TextdrawInfo[textdrawid][ShadowSize]);
		TextDrawSetOutline(TextdrawInfo[textdrawid][ID],TextdrawInfo[textdrawid][OutlineSize]);
		TextDrawBackgroundColor(TextdrawInfo[textdrawid][ID],TextdrawInfo[textdrawid][OutlineColor]);
		TextDrawSetProportional(TextdrawInfo[textdrawid][ID],TextdrawInfo[textdrawid][Proportional]);
	}
	else if(TextdrawInfo[textdrawid][Font] == 5)
	{
	    TextDrawBackgroundColor(TextdrawInfo[textdrawid][ID],TextdrawInfo[textdrawid][OutlineColor]);
		TextDrawSetPreviewModel(TextdrawInfo[textdrawid][ID],TextdrawInfo[textdrawid][PreviewModel]);
		TextDrawSetPreviewRot(TextdrawInfo[textdrawid][ID],
			TextdrawInfo[textdrawid][PreviewRotation][0],TextdrawInfo[textdrawid][PreviewRotation][1],
			TextdrawInfo[textdrawid][PreviewRotation][2],TextdrawInfo[textdrawid][PreviewZoom]);
		TextDrawSetPreviewVehCol(TextdrawInfo[textdrawid][ID],TextdrawInfo[textdrawid][PreviewColor][0],TextdrawInfo[textdrawid][PreviewColor][1]);
	}
	TextDrawSetSelectable(TextdrawInfo[textdrawid][ID],TextdrawInfo[textdrawid][Selectable]);
	TextDrawShowForAll(TextdrawInfo[textdrawid][ID]);
	return 1;
}
stock DuplicateTextdraw(textdrawid)
{
	new td = CreateTextdraw(TextdrawInfo[textdrawid][Pos][0],TextdrawInfo[textdrawid][Pos][1],TextdrawInfo[textdrawid][Text]);
	if(td == -1) return td;
	SetTextdrawFont(td,TextdrawInfo[textdrawid][Font]);
	SetTextdrawSize(td,TextdrawInfo[textdrawid][TextSize][0],TextdrawInfo[textdrawid][TextSize][1]);
	SetTextdrawColor(td,TextdrawInfo[textdrawid][TextColor]);
	if(TextdrawInfo[textdrawid][Font] < 4)
	{
	    SetTextdrawFontSize(td,TextdrawInfo[textdrawid][LetterSize][0],TextdrawInfo[textdrawid][LetterSize][1]);
	    SetTextdrawAlignment(td,TextdrawInfo[textdrawid][Alignment]);
	    ToggleTextdrawBox(td,TextdrawInfo[textdrawid][UseBox]);
	    SetTextdrawBoxColor(td,TextdrawInfo[textdrawid][BoxColor]);
		SetTextdrawShadow(td,TextdrawInfo[textdrawid][ShadowSize]);
		SetTextdrawOutline(td,TextdrawInfo[textdrawid][OutlineSize]);
		SetTextdrawBoxColor(td,TextdrawInfo[textdrawid][OutlineColor]);
		ToggleTextdrawProportional(td,TextdrawInfo[textdrawid][Proportional]);
	}
	else if(TextdrawInfo[textdrawid][Font] == 5)
	{
	    SetTextdrawBoxColor(td,TextdrawInfo[textdrawid][OutlineColor]);
	    SetTextdrawPreviewModel(td,TextdrawInfo[textdrawid][PreviewModel]);
		SetTextdrawPreviewRot(td,
			TextdrawInfo[textdrawid][PreviewRotation][0],TextdrawInfo[textdrawid][PreviewRotation][1],
			TextdrawInfo[textdrawid][PreviewRotation][2],TextdrawInfo[textdrawid][PreviewZoom]);
		SetTextdrawPreviewVehCol(td,TextdrawInfo[textdrawid][PreviewColor][0],TextdrawInfo[textdrawid][PreviewColor][1]);
	}
	ToggleTextdrawSelectable(td,TextdrawInfo[textdrawid][Selectable]);
	TextDrawShowForAll(TextdrawInfo[textdrawid][ID]);
	return td;
}
stock SetTextdrawFont(textdrawid,font)
{
	TextdrawInfo[textdrawid][Font] = font;
	TextDrawFont(TextdrawInfo[textdrawid][ID],font);
	TextDrawHideForAll(TextdrawInfo[textdrawid][ID]);
	TextDrawShowForAll(TextdrawInfo[textdrawid][ID]);
	return 1;
}
stock SetTextdrawFontSize(textdrawid,Float:size_x,Float:size_y)
{
    TextdrawInfo[textdrawid][LetterSize][0] = size_x;
    TextdrawInfo[textdrawid][LetterSize][1] = size_y;
    TextDrawLetterSize(TextdrawInfo[textdrawid][ID],size_x,size_y);
    TextDrawHideForAll(TextdrawInfo[textdrawid][ID]);
	TextDrawShowForAll(TextdrawInfo[textdrawid][ID]);
    return 1;
}
stock SetTextdrawSize(textdrawid,Float:size_x,Float:size_y)
{
    TextdrawInfo[textdrawid][TextSize][0] = size_x;
    TextdrawInfo[textdrawid][TextSize][1] = size_y;
    TextDrawTextSize(TextdrawInfo[textdrawid][ID],size_x,size_y);
    TextDrawHideForAll(TextdrawInfo[textdrawid][ID]);
	TextDrawShowForAll(TextdrawInfo[textdrawid][ID]);
    return 1;
}
stock SetTextdrawAlignment(textdrawid,alignment)
{
    TextdrawInfo[textdrawid][Alignment] = alignment;
    TextDrawAlignment(TextdrawInfo[textdrawid][ID],alignment);
    TextDrawHideForAll(TextdrawInfo[textdrawid][ID]);
	TextDrawShowForAll(TextdrawInfo[textdrawid][ID]);
    return 1;
}
stock SetTextdrawColor(textdrawid,color)
{
	TextdrawInfo[textdrawid][TextColor] = color;
	TextDrawColor(TextdrawInfo[textdrawid][ID],color);
	TextDrawHideForAll(TextdrawInfo[textdrawid][ID]);
	TextDrawShowForAll(TextdrawInfo[textdrawid][ID]);
	return 1;
}
stock ToggleTextdrawBox(textdrawid,toggle)
{
	TextdrawInfo[textdrawid][UseBox] = toggle;
	TextDrawUseBox(TextdrawInfo[textdrawid][ID],toggle);
	TextDrawHideForAll(TextdrawInfo[textdrawid][ID]);
	TextDrawShowForAll(TextdrawInfo[textdrawid][ID]);
	return 1;
}
stock SetTextdrawBoxColor(textdrawid,color)
{
	TextdrawInfo[textdrawid][BoxColor] = color;
	TextDrawBoxColor(TextdrawInfo[textdrawid][ID],color);
	TextDrawHideForAll(TextdrawInfo[textdrawid][ID]);
	TextDrawShowForAll(TextdrawInfo[textdrawid][ID]);
	return 1;
}
stock SetTextdrawShadow(textdrawid,size)
{
    TextdrawInfo[textdrawid][ShadowSize] = size;
	TextDrawSetShadow(TextdrawInfo[textdrawid][ID],size);
	TextDrawHideForAll(TextdrawInfo[textdrawid][ID]);
	TextDrawShowForAll(TextdrawInfo[textdrawid][ID]);
	return 1;
}
stock SetTextdrawOutline(textdrawid,size)
{
	TextdrawInfo[textdrawid][OutlineSize] = size;
	TextDrawSetOutline(TextdrawInfo[textdrawid][ID],size);
	TextDrawHideForAll(TextdrawInfo[textdrawid][ID]);
	TextDrawShowForAll(TextdrawInfo[textdrawid][ID]);
	return 1;
}
stock SetTextdrawOutlineColor(textdrawid,color)
{
	TextdrawInfo[textdrawid][OutlineColor] = color;
	TextDrawBackgroundColor(TextdrawInfo[textdrawid][ID],color);
	TextDrawHideForAll(TextdrawInfo[textdrawid][ID]);
	TextDrawShowForAll(TextdrawInfo[textdrawid][ID]);
	return 1;
}
stock ToggleTextdrawProportional(textdrawid,toggle)
{
	TextdrawInfo[textdrawid][Proportional] = toggle;
	TextDrawSetProportional(TextdrawInfo[textdrawid][ID],toggle);
	TextDrawHideForAll(TextdrawInfo[textdrawid][ID]);
	TextDrawShowForAll(TextdrawInfo[textdrawid][ID]);
	return 1;
}
stock ToggleTextdrawSelectable(textdrawid,toggle)
{
    TextdrawInfo[textdrawid][Selectable] = toggle;
	TextDrawSetSelectable(TextdrawInfo[textdrawid][ID],toggle);
	TextDrawHideForAll(TextdrawInfo[textdrawid][ID]);
	TextDrawShowForAll(TextdrawInfo[textdrawid][ID]);
	return 1;
}
stock SetTextdrawPreviewModel(textdrawid,modelindex)
{
	TextdrawInfo[textdrawid][PreviewModel] = modelindex;
	TextDrawSetPreviewModel(TextdrawInfo[textdrawid][ID],modelindex);
	TextDrawHideForAll(TextdrawInfo[textdrawid][ID]);
	TextDrawShowForAll(TextdrawInfo[textdrawid][ID]);
	return 1;
}
stock SetTextdrawPreviewRot(textdrawid,Float:fRotX,Float:fRotY,Float:fRotZ,Float:fZoom = 1.0)
{
	TextdrawInfo[textdrawid][PreviewRotation][0] = fRotX;
	TextdrawInfo[textdrawid][PreviewRotation][1] = fRotY;
	TextdrawInfo[textdrawid][PreviewRotation][2] = fRotZ;
	TextdrawInfo[textdrawid][PreviewZoom] = fZoom;
	TextDrawSetPreviewRot(TextdrawInfo[textdrawid][ID],fRotX,fRotY,fRotZ,fZoom);
	TextDrawHideForAll(TextdrawInfo[textdrawid][ID]);
	TextDrawShowForAll(TextdrawInfo[textdrawid][ID]);
	return 1;
}
stock SetTextdrawPreviewVehCol(textdrawid,color1,color2)
{
	TextdrawInfo[textdrawid][PreviewColor][0] = color1;
	TextdrawInfo[textdrawid][PreviewColor][1] = color2;
	TextDrawSetPreviewVehCol(TextdrawInfo[textdrawid][ID],color1,color2);
	TextDrawHideForAll(TextdrawInfo[textdrawid][ID]);
	TextDrawShowForAll(TextdrawInfo[textdrawid][ID]);
	return 1;
}
stock ExportTextdraw(filename[])
{
	new File:output = fopen("output.pwn",io_write);
    new string[256];
    new idx = 1;
    fwrite(output,"#include <a_samp>\n\n#define FILTERSCRIPT\n\n");
    forex(i,MAX_TEXTDRAWS)
    {
        if(TextdrawInfo[i][ID] == INVALID_TEXT_DRAW) continue;
        format(string,sizeof(string),"new Text:Textdraw%d;\n",idx);
        fwrite(output,string);
        idx++;
    }
	fwrite(output,"\npublic OnFilterScriptInit()\n{\n");
	idx = 1;
	forex(textdrawid,MAX_TEXTDRAWS)
    {
        if(TextdrawInfo[textdrawid][ID] == INVALID_TEXT_DRAW) continue;
        format(string,sizeof(string),"\tTextdraw%d = TextDrawCreate(%f,%f,\"%s\");\n",idx,TextdrawInfo[textdrawid][Pos][0],TextdrawInfo[textdrawid][Pos][1],TextdrawInfo[textdrawid][Text]);
		fwrite(output,string);
		format(string,sizeof(string),"\tTextDrawFont(Textdraw%d,%d);\n",idx,TextdrawInfo[textdrawid][Font]);
		fwrite(output,string);
		if(TextdrawInfo[textdrawid][Font] < 4)
		{
		    format(string,sizeof(string),"\tTextDrawLetterSize(Textdraw%d,%f,%f);\n",idx,TextdrawInfo[textdrawid][LetterSize][0],TextdrawInfo[textdrawid][LetterSize][1]);
			fwrite(output,string);
			format(string,sizeof(string),"\tTextDrawTextSize(Textdraw%d,%f,%f);\n",idx,TextdrawInfo[textdrawid][TextSize][0],TextdrawInfo[textdrawid][TextSize][1]);
			fwrite(output,string);
			format(string,sizeof(string),"\tTextDrawAlignment(Textdraw%d,%d);\n",idx,TextdrawInfo[textdrawid][Alignment]);
			fwrite(output,string);
			format(string,sizeof(string),"\tTextDrawColor(Textdraw%d,0x%x);\n",idx,TextdrawInfo[textdrawid][TextColor]);
			fwrite(output,string);
			format(string,sizeof(string),"\tTextDrawUseBox(Textdraw%d,%d);\n",idx,TextdrawInfo[textdrawid][UseBox]);
			fwrite(output,string);
			format(string,sizeof(string),"\tTextDrawBoxColor(Textdraw%d,0x%x);\n",idx,TextdrawInfo[textdrawid][BoxColor]);
			fwrite(output,string);
			format(string,sizeof(string),"\tTextDrawSetShadow(Textdraw%d,%d);\n",idx,TextdrawInfo[textdrawid][ShadowSize]);
			fwrite(output,string);
			format(string,sizeof(string),"\tTextDrawSetOutline(Textdraw%d,%d);\n",idx,TextdrawInfo[textdrawid][OutlineSize]);
			fwrite(output,string);
			format(string,sizeof(string),"\tTextDrawBackgroundColor(Textdraw%d,0x%x);\n",idx,TextdrawInfo[textdrawid][OutlineColor]);
			fwrite(output,string);
			format(string,sizeof(string),"\tTextDrawSetProportional(Textdraw%d,%d);\n",idx,TextdrawInfo[textdrawid][Proportional]);
			fwrite(output,string);
			format(string,sizeof(string),"\tTextDrawSetSelectable(Textdraw%d,%d);\n\n",idx,TextdrawInfo[textdrawid][Selectable]);
   			fwrite(output,string);
		}
		else if(TextdrawInfo[textdrawid][Font] == 4)
		{
		    format(string,sizeof(string),"\tTextDrawTextSize(Textdraw%d,%f,%f);\n",idx,TextdrawInfo[textdrawid][TextSize][0],TextdrawInfo[textdrawid][TextSize][1]);
			fwrite(output,string);
			format(string,sizeof(string),"\tTextDrawColor(Textdraw%d,0x%x);\n",idx,TextdrawInfo[textdrawid][TextColor]);
			fwrite(output,string);
			format(string,sizeof(string),"\tTextDrawSetSelectable(Textdraw%d,%d);\n\n",idx,TextdrawInfo[textdrawid][Selectable]);
   			fwrite(output,string);
		}
		else if(TextdrawInfo[textdrawid][Font] == 5)
		{
		    format(string,sizeof(string),"\tTextDrawTextSize(Textdraw%d,%f,%f);\n",idx,TextdrawInfo[textdrawid][TextSize][0],TextdrawInfo[textdrawid][TextSize][1]);
			fwrite(output,string);
			format(string,sizeof(string),"\tTextDrawColor(Textdraw%d,0x%x);\n",idx,TextdrawInfo[textdrawid][TextColor]);
			fwrite(output,string);
			format(string,sizeof(string),"\tTextDrawBackgroundColor(Textdraw%d,0x%x);\n",idx,TextdrawInfo[textdrawid][OutlineColor]);
			fwrite(output,string);
			format(string,sizeof(string),"\tTextDrawSetPreviewModel(Textdraw%d,%d);\n",idx,TextdrawInfo[textdrawid][PreviewModel]);
			fwrite(output,string);
			format(string,sizeof(string),"\tTextDrawSetPreviewRot(Textdraw%d,%f,%f,%f,%f);\n",
				idx,TextdrawInfo[textdrawid][PreviewRotation][0],TextdrawInfo[textdrawid][PreviewRotation][1],
				TextdrawInfo[textdrawid][PreviewRotation][2],TextdrawInfo[textdrawid][PreviewZoom]);
			fwrite(output,string);
			format(string,sizeof(string),"\tTextDrawSetPreviewVehCol(Textdraw%d,%d,%d);\n",idx,TextdrawInfo[textdrawid][PreviewColor][0],TextdrawInfo[textdrawid][PreviewColor][1]);
			fwrite(output,string);
			format(string,sizeof(string),"\tTextDrawSetSelectable(Textdraw%d,%d);\n\n",idx,TextdrawInfo[textdrawid][Selectable]);
   			fwrite(output,string);
		}
        idx++;
    }
	fwrite(output,"\n");
	idx = 1;
	forex(i,MAX_TEXTDRAWS)
    {
        if(TextdrawInfo[i][ID] == INVALID_TEXT_DRAW) continue;
        format(string,sizeof(string),"\tTextDrawShowForAll(Textdraw%d);\n",idx);
		fwrite(output,string);
		idx++;
	}
	fwrite(output,"}\npublic OnFilterScriptExit()\n{\n");
	idx = 1;
	forex(i,MAX_TEXTDRAWS)
    {
        if(TextdrawInfo[i][ID] == INVALID_TEXT_DRAW) continue;
        format(string,sizeof(string),"\tTextDrawDestroy(Textdraw%d);\n",idx);
		fwrite(output,string);
		idx++;
	}
	fwrite(output,"}");
    fclose(output);
	return 1;
}

public OnFilterScriptInit()
{
    EditTimer = SetTimer("EditorTimer",100,1);
	forex(i,MAX_TEXTDRAWS)
	{
	    TextdrawInfo[i][ID] = INVALID_TEXT_DRAW;
	}
	printf("[ITDS] Ian's Textdraw Studio loaded!");
	return 1;
}

public OnFilterScriptExit()
{
    forex(i,MAX_TEXTDRAWS)
	{
	    if(TextdrawInfo[i][ID] == INVALID_TEXT_DRAW) continue;
		TextDrawDestroy(TextdrawInfo[i][ID]);
	}
	KillTimer(EditTimer);
    printf("[ITDS] Ian's Textdraw Studio unloaded!");
	return 1;
}

CMD:textdraw(playerid,params[])
{
    ShowMainMenu(playerid);
	return 1;
}

CMD:export(playerid,params[])
{
    if(!IsNull(params))
    {
    	new dir[32];
    	format(dir,sizeof(dir),"%s.pwn",params);
    	ExportTextdraw(dir);
    }
    return 1;
}

public EditorTimer()
{
	forex(playerid,MAX_PLAYERS)
	{
	    if(IsPlayerConnected(playerid) == 0) continue;
		if(GetPVarType(playerid,"EditType") != 0)
		{
		    new textdrawid = GetPVarInt(playerid,"EditTD");
			if(TextdrawInfo[textdrawid][ID] != INVALID_TEXT_DRAW)
			{
			    new str[64];
			    new keys,updown,leftright;
			    new Float:speed = 1.0;
			    new Float:directionX = 0.0;
			    new Float:directionY = 0.0;
				GetPlayerKeys(playerid,keys,updown,leftright);
				if(updown == 0 && leftright == 0) continue;
				if(((keys & (KEY_WALK)) == (KEY_WALK))) speed = 0.1;
				else if(((keys & (KEY_JUMP)) == (KEY_JUMP))) speed = 10.0;
				if(leftright > 0) directionX += speed;
				else if(leftright < 0) directionX -= speed;
				if(updown > 0) directionY += speed;
				else if(updown < 0) directionY -= speed;
			    switch(GetPVarInt(playerid,"EditType"))
			    {
			        case 1:
			        {
			            SetTextdrawPosition(textdrawid,(TextdrawInfo[textdrawid][Pos][0]+directionX),(TextdrawInfo[textdrawid][Pos][1]+directionY));
			            format(str,sizeof(str),"~n~~n~~n~~n~~n~~n~~n~~n~X: %.2f Y: %.2f",TextdrawInfo[textdrawid][Pos][0],TextdrawInfo[textdrawid][Pos][1]);
			        }
			        case 2:
			        {
			            directionX = (directionX/10);
			            directionY = (directionY/10);
			            SetTextdrawFontSize(textdrawid,(TextdrawInfo[textdrawid][LetterSize][0]+directionX),(TextdrawInfo[textdrawid][LetterSize][1]+directionY));
			            format(str,sizeof(str),"~n~~n~~n~~n~~n~~n~~n~~n~X: %.2f Y: %.2f",TextdrawInfo[textdrawid][LetterSize][0],TextdrawInfo[textdrawid][LetterSize][1]);
			        }
			        case 3:
			        {
			            SetTextdrawSize(textdrawid,(TextdrawInfo[textdrawid][TextSize][0]+directionX),(TextdrawInfo[textdrawid][TextSize][1]+directionY));
			            format(str,sizeof(str),"~n~~n~~n~~n~~n~~n~~n~~n~X: %.2f Y: %.2f",TextdrawInfo[textdrawid][TextSize][0],TextdrawInfo[textdrawid][TextSize][1]);
			        }
			        case 4:
			        {
                        SetTextdrawPreviewRot(textdrawid,
							(TextdrawInfo[textdrawid][PreviewRotation][0]+directionX),(TextdrawInfo[textdrawid][PreviewRotation][1]+directionY),
							TextdrawInfo[textdrawid][PreviewRotation][2],TextdrawInfo[textdrawid][PreviewZoom]);
                        format(str,sizeof(str),"~n~~n~~n~~n~~n~~n~~n~~n~X: %.2f Y: %.2f",TextdrawInfo[textdrawid][PreviewRotation][0],TextdrawInfo[textdrawid][PreviewRotation][1]);
			        }
			        case 5:
			        {
                        SetTextdrawPreviewRot(textdrawid,
							TextdrawInfo[textdrawid][PreviewRotation][0],TextdrawInfo[textdrawid][PreviewRotation][1],
							(TextdrawInfo[textdrawid][PreviewRotation][2]+directionX),(TextdrawInfo[textdrawid][PreviewZoom]+directionY));
                        format(str,sizeof(str),"~n~~n~~n~~n~~n~~n~~n~~n~Z: %.2f Zoom: %.2f",TextdrawInfo[textdrawid][PreviewRotation][2],TextdrawInfo[textdrawid][PreviewZoom]);
			        }
			        case 6:
			        {
			            new color1 = TextdrawInfo[textdrawid][PreviewColor][0];
			            new color2 = TextdrawInfo[textdrawid][PreviewColor][1];
			            if(directionX != 0.0)
			            {
							if(directionX == 10.0)
							{
							    color1 += 10;
							}
							else if(directionX == 1.0 || directionX == 0.1)
							{
							    color1++;
							}
							else if(directionX == -10.0)
							{
							    color1 -= 10;
							}
							else if(directionX == -1.0 || directionX == -0.1)
							{
							    color1--;
							}
							if(color1 > 255)
							{
							    color1 = (color1 - 255);
							}
							else if(color1 < 0)
							{
							    color1 = (color1 + 255);
							}
			            }
			            if(directionY != 0.0)
			            {
							if(directionY == 10.0)
							{
							    color2 -= 10;
							}
							else if(directionY == 1.0 || directionY == 0.1)
							{
							    color2--;
							}
							else if(directionY == -10.0)
							{
							    color2 += 10;
							}
							else if(directionY == -1.0 || directionY == -0.1)
							{
							    color2++;
							}
							if(color2 > 255)
							{
							    color2 = (color2 - 255);
							}
							else if(color2 < 0)
							{
							    color2 = (color2 + 255);
							}
			            }
			            SetTextdrawPreviewVehCol(textdrawid,color1,color2);
			            format(str,sizeof(str),"~n~~n~~n~~n~~n~~n~~n~~n~Color 1: %d Color 2: %d",color1,color2);
			        }
			    }
			    GameTextForPlayer(playerid,str,1000,5);
			}
			else
			{
			    DeletePVar(playerid,"EditTD");
			    DeletePVar(playerid,"EditType");
			}
		}
	}
	return 1;
}

public OnPlayerKeyStateChange(playerid,newkeys,oldkeys)
{
	if(((newkeys & KEY_SPRINT) && !(oldkeys & KEY_SPRINT)))
	{
	    if(GetPVarType(playerid,"EditType") != 0)
		{
		    DeletePVar(playerid,"EditType");
		    TogglePlayerControllable(playerid,1);
		    ShowTextdrawMenu(playerid);
		}
	}
	else if(((newkeys & KEY_YES) && !(oldkeys & KEY_YES)))
	{
	    new type = GetPVarInt(playerid,"EditType");
	    if(type == 4 || type == 5)
		{
		    SetPVarInt(playerid,"EditType",((type == 4) ? (5) : (4)));
		    SendClientMessage(playerid,-1,((type == 4) ? ("<TDS>: Switched to {ffff00}Z rotation&Zoom editing mode!") : ("<TDS>: Switched to {ffff00}X&Y rotation editing mode!")));
		}
	}
	return 1;
}
public OnDialogResponse(playerid,dialogid,response,listitem,inputtext[])
{
	switch(dialogid)
	{
	    case DIALOG_MAIN_MENU:
	    {
	        if(response)
	        {
	            if(listitem == 0)
	            {
	                new td = CreateTextdraw(320.0,50.0,"New Textdraw");
					if(td == -1) SendClientMessage(playerid,-1,"<ERROR>: Failed to create more textdraw!");
					else SendClientMessage(playerid,-1,"<TDS>: Textdraw created!");
	                ShowMainMenu(playerid);
	            }
	            else
	            {
	                new idx = 1;
	                forex(i,MAX_TEXTDRAWS)
	                {
	                    if(TextdrawInfo[i][ID] == INVALID_TEXT_DRAW) continue;
						if(listitem == idx)
						{
						    SetPVarInt(playerid,"EditTD",i);
						    ShowTextdrawMenu(playerid);
						    break;
						}
                        idx++;
	                }
	            }
	        }
	    }
	    case DIALOG_TEXTDRAW_MAIN:
	    {
	        if(response)
	        {
	            new textdrawid = GetPVarInt(playerid,"EditTD");
	            if(TextdrawInfo[textdrawid][Font] < 4)
	            {
					switch(listitem)
					{
					    case 0:
						{
						    ShowPlayerDialog(playerid,DIALOG_SET_TEXT,DIALOG_STYLE_INPUT,"Set Text","Please input text:","Input","Back");
						}
						case 1:
						{
						    ShowPlayerDialog(playerid,DIALOG_POSITION,DIALOG_STYLE_LIST,"Set Position","Manual input\nMove","Select","Back");
						}
						case 2:
						{
						    ShowPlayerDialog(playerid,DIALOG_FONT,DIALOG_STYLE_LIST,"Set Font","Font 1\nFont 2\nFont 3\nFont 4\nSprite\nModel Preview","Select","Back");
						}
						case 3:
						{
						    ShowPlayerDialog(playerid,DIALOG_FONT_SIZE,DIALOG_STYLE_LIST,"Set Font Size","Manual input\nStretch","Select","Back");
						}
						case 4:
						{
						    ShowPlayerDialog(playerid,DIALOG_ALIGNMENT,DIALOG_STYLE_LIST,"Set Alignment","Left\nCenter\nRight","Select","Back");
						}
						case 5:
						{
						    ShowPlayerDialog(playerid,DIALOG_FONT_COLOR,DIALOG_STYLE_LIST,"Set Font Color","Manual Input\nChoose predefined","Select","Back");
						}
						case 6:
						{
						    ShowPlayerDialog(playerid,DIALOG_BOX_OPTION,DIALOG_STYLE_LIST,"Box Option","Toggle\nSize\nColor","Select","Back");
						}
						case 7:
						{
						    ShowPlayerDialog(playerid,DIALOG_OUTLINE_OPTION,DIALOG_STYLE_LIST,"Outline Option","Outline Size\nShadow Size\nColor","Select","Back");
						}
						case 8:
						{
						    new use = TextdrawInfo[textdrawid][Proportional];
							if(use) use = 0;
							else use = 1;
							ToggleTextdrawProportional(textdrawid,use);
							ShowTextdrawMenu(playerid);
						}
						case 9:
						{
						    new td = DuplicateTextdraw(textdrawid);
							if(td == -1)
							{
								SendClientMessage(playerid,-1,"<ERROR>: Failed to create more textdraw!");
								ShowTextdrawMenu(playerid);
								return 0;
							}
							SetPVarInt(playerid,"EditTD",td);
							SendClientMessage(playerid,-1,"<TDS>: Textdraw has been duplicated!");
							ShowTextdrawMenu(playerid);
						}
						case 10:
						{
							SelectTextDraw(playerid,0xFF0000FF);
						}
						case 11:
						{
						    DeletePVar(playerid,"EditTD");
							TextDrawDestroy(TextdrawInfo[textdrawid][ID]);
							TextdrawInfo[textdrawid][ID] = INVALID_TEXT_DRAW;
						    ShowMainMenu(playerid);
						}
					}
				}
				else if(TextdrawInfo[textdrawid][Font] == 4)
				{
					switch(listitem)
					{
					    case 0:
						{
						    ShowPlayerDialog(playerid,DIALOG_SET_TEXT,DIALOG_STYLE_INPUT,"Set Text","Please input text:","Input","Back");
						}
						case 1:
						{
						    ShowPlayerDialog(playerid,DIALOG_POSITION,DIALOG_STYLE_LIST,"Set Position","Manual input\nMove","Select","Back");
						}
						case 2:
						{
						    ShowPlayerDialog(playerid,DIALOG_FONT,DIALOG_STYLE_LIST,"Set Font","Font 1\nFont 2\nFont 3\nFont 4\nSprite\nModel Preview","Select","Back");
						}
						case 3:
						{
						    ShowPlayerDialog(playerid,DIALOG_FONT_COLOR,DIALOG_STYLE_LIST,"Set Font Color","Manual Input\nChoose predefined","Select","Back");
						}
						case 4:
						{
						    ShowPlayerDialog(playerid,DIALOG_BOX_SIZE,DIALOG_STYLE_LIST,"Set Sprite Size","Manual input\nStretch","Select","Back");
						}
						case 5:
						{
						    new td = DuplicateTextdraw(textdrawid);
							if(td == -1)
							{
								SendClientMessage(playerid,-1,"<ERROR>: Failed to create more textdraw!");
								ShowTextdrawMenu(playerid);
								return 0;
							}
							SetPVarInt(playerid,"EditTD",td);
							SendClientMessage(playerid,-1,"<TDS>: Textdraw has been duplicated!");
							ShowTextdrawMenu(playerid);
						}
						case 6:
						{
						    SelectTextDraw(playerid,0xFF0000FF);
						}
						case 7:
						{
						    DeletePVar(playerid,"EditTD");
							TextDrawDestroy(TextdrawInfo[textdrawid][ID]);
							TextdrawInfo[textdrawid][ID] = INVALID_TEXT_DRAW;
						    ShowMainMenu(playerid);
						}
					}
				}
				else if(TextdrawInfo[textdrawid][Font] == 5)
				{
				    switch(listitem)
					{
					    case 0:
						{
						    ShowPlayerDialog(playerid,DIALOG_SET_TEXT,DIALOG_STYLE_INPUT,"Set Model","Please input model:","Input","Back");
						}
						case 1:
						{
						    ShowPlayerDialog(playerid,DIALOG_POSITION,DIALOG_STYLE_LIST,"Set Position","Manual input\nMove","Select","Back");
						}
						case 2:
						{
						    ShowPlayerDialog(playerid,DIALOG_FONT,DIALOG_STYLE_LIST,"Set Font","Font 1\nFont 2\nFont 3\nFont 4\nSprite\nModel Preview","Select","Back");
						}
						case 3:
						{
						    ShowPlayerDialog(playerid,DIALOG_FONT_COLOR,DIALOG_STYLE_LIST,"Set Font Color","Manual Input\nChoose predefined","Select","Back");
						}
						case 4:
						{
						    ShowPlayerDialog(playerid,DIALOG_OUTLINE_COLOR,DIALOG_STYLE_LIST,"Outline Color","Manual Input\nChoose predefined","Select","Back");
						}
						case 5:
						{
						    ShowPlayerDialog(playerid,DIALOG_BOX_SIZE,DIALOG_STYLE_LIST,"Set Model Size","Manual input\nStretch","Select","Back");
						}
						case 6:
						{
						    SetPVarInt(playerid,"EditType",4);
							TogglePlayerControllable(playerid,0);
							SendClientMessage(playerid,-1,"<TDS>: Use your {ffff00}WASD {ffffff}or {ffff00}Arrow keys {ffffff}to rotate or zoom the model!");
							SendClientMessage(playerid,-1,"<TDS>: You can hold {ffff00}~k~~SNEAK_ABOUT~ key {ffffff}to slow movement or hold {ffff00}~k~~PED_JUMPING~ key {ffffff}to speed up movement");
							SendClientMessage(playerid,-1,"<TDS>: Press {00ffff}~k~~CONVERSATION_YES~ key {ffffff}to switch between X&Y and Z&Zoom editing mode!");
							SendClientMessage(playerid,-1,"<TDS>: Press {00ffff}~k~~PED_SPRINT~ key {ffffff}to confirm model!");
						}
						case 7:
						{
						    SetPVarInt(playerid,"EditType",6);
							TogglePlayerControllable(playerid,0);
							SendClientMessage(playerid,-1,"<TDS>: Use your {ffff00}WASD {ffffff}or {ffff00}Arrow keys {ffffff}to change the color of the model!");
							SendClientMessage(playerid,-1,"<TDS>: You can hold {ffff00}~k~~SNEAK_ABOUT~ key {ffffff}to speed up the color selection by 10");
							SendClientMessage(playerid,-1,"<TDS>: Press {00ffff}~k~~PED_SPRINT~ key {ffffff}to confirm color!");
						}
						case 8:
						{
						    new td = DuplicateTextdraw(textdrawid);
							if(td == -1)
							{
								SendClientMessage(playerid,-1,"<ERROR>: Failed to create more textdraw!");
								ShowTextdrawMenu(playerid);
								return 0;
							}
							SetPVarInt(playerid,"EditTD",td);
							SendClientMessage(playerid,-1,"<TDS>: Textdraw has been duplicated!");
							ShowTextdrawMenu(playerid);
						}
						case 9:
						{
						    SelectTextDraw(playerid,0xFF0000FF);
						}
						case 10:
						{
						    DeletePVar(playerid,"EditTD");
							TextDrawDestroy(TextdrawInfo[textdrawid][ID]);
							TextdrawInfo[textdrawid][ID] = INVALID_TEXT_DRAW;
						    ShowMainMenu(playerid);
						}
					}
				}
	        }
	        else
	        {
	            DeletePVar(playerid,"EditTD");
	        }
	    }
	    case DIALOG_SET_TEXT:
	    {
	        if(response)
	        {
	            new string[(64+MAX_TEXTDRAW_STRING_LENGTH)];
	            new textdrawid = GetPVarInt(playerid,"EditTD");
	            if(TextdrawInfo[textdrawid][Font] == 5)
	            {
	                if(!IsNull(inputtext))
		            {
		                SetTextdrawPreviewModel(textdrawid,strval(inputtext));
					}
					format(string,sizeof(string),"{ffffff}Current Model: {ffff00}%d\n{ffffff}Please input text:",TextdrawInfo[textdrawid][PreviewModel]);
					ShowPlayerDialog(playerid,DIALOG_SET_TEXT,DIALOG_STYLE_INPUT,"Set Model",string,"Input","Back");
	            }
	            else
	            {
		            if(!IsNull(inputtext))
		            {
						SetTextdrawString(textdrawid,inputtext);
					}
					format(string,sizeof(string),"{ffffff}Current text: {ffff00}%s\n{ffffff}Please input text:",TextdrawInfo[textdrawid][Text]);
					ShowPlayerDialog(playerid,DIALOG_SET_TEXT,DIALOG_STYLE_INPUT,"Set Text",string,"Input","Back");
				}
	        }
	        else ShowTextdrawMenu(playerid);
	    }
		case DIALOG_POSITION:
		{
		    if(response)
		    {
		        new textdrawid = GetPVarInt(playerid,"EditTD");
		        if(listitem == 0)
		        {
		            new string[128];
		            format(string,sizeof(string),"Please input position below\nExample: \"320.0 240.0\"\nCurrent: %.2f %.2f",TextdrawInfo[textdrawid][Pos][0],TextdrawInfo[textdrawid][Pos][1]);
		            ShowPlayerDialog(playerid,DIALOG_POSITION_INPUT,DIALOG_STYLE_INPUT,"Input Position",string,"Input","Back");
		        }
		        else if(listitem == 1)
		        {
		            SetPVarInt(playerid,"EditType",1);
					TogglePlayerControllable(playerid,0);
					SendClientMessage(playerid,-1,"<TDS>: Use your {ffff00}WASD {ffffff}or {ffff00}Arrow keys {ffffff}to move the textdraw!");
					SendClientMessage(playerid,-1,"<TDS>: You can hold {ffff00}~k~~SNEAK_ABOUT~ key {ffffff}to slow movement or hold {ffff00}~k~~PED_JUMPING~ key {ffffff}to speed up movement");
					SendClientMessage(playerid,-1,"<TDS>: Press {00ffff}~k~~PED_SPRINT~ key {ffffff}to confirm position!");
		        }
		        
		    }
		    else ShowTextdrawMenu(playerid);
		}
		case DIALOG_POSITION_INPUT:
		{
		    if(response)
		    {
		        new string[128];
		        new textdrawid = GetPVarInt(playerid,"EditTD");
		        if(!IsNull(inputtext))
		        {
					new pos = strfind(inputtext," ");
					if(pos != -1)
					{
					    new Float:newpos[2];
						strmid(string,inputtext,0,pos,sizeof(string));
						newpos[0] = floatstr(string);
						strmid(string,inputtext,(pos+1),strlen(inputtext),sizeof(string));
						newpos[1] = floatstr(string);
						SetTextdrawPosition(textdrawid,newpos[0],newpos[1]);
					}
		        }
	            format(string,sizeof(string),"Please input position below\nExample: \"320.0 240.0\"\nCurrent: %.2f %.2f",TextdrawInfo[textdrawid][Pos][0],TextdrawInfo[textdrawid][Pos][1]);
	            ShowPlayerDialog(playerid,DIALOG_POSITION_INPUT,DIALOG_STYLE_INPUT,"Input Position",string,"Input","Back");
		    }
		    else ShowTextdrawMenu(playerid);
		}
		case DIALOG_FONT:
		{
		    if(response)
		    {
		        new textdrawid = GetPVarInt(playerid,"EditTD");
				SetTextdrawFont(textdrawid,listitem);
		        ShowPlayerDialog(playerid,DIALOG_FONT,DIALOG_STYLE_LIST,"Set Font","Font 1\nFont 2\nFont 3\nFont 4\nSprite\nModel Preview","Select","Back");
		    }
		    else ShowTextdrawMenu(playerid);
		}
		case DIALOG_FONT_SIZE:
		{
		    if(response)
		    {
		        new textdrawid = GetPVarInt(playerid,"EditTD");
		        if(listitem == 0)
		        {
		            new string[128];
		            format(string,sizeof(string),"Please input size below\nExample: \"1.0 2.0\"\nCurrent: %.2f %.2f",TextdrawInfo[textdrawid][LetterSize][0],TextdrawInfo[textdrawid][LetterSize][1]);
		            ShowPlayerDialog(playerid,DIALOG_FONT_SIZE_INPUT,DIALOG_STYLE_INPUT,"Input Text Size",string,"Input","Back");
		        }
		        else if(listitem == 1)
		        {
                    SetPVarInt(playerid,"EditType",2);
					TogglePlayerControllable(playerid,0);
					SendClientMessage(playerid,-1,"<TDS>: Use your {ffff00}WASD {ffffff}or {ffff00}Arrow keys {ffffff}to scale the font!");
					SendClientMessage(playerid,-1,"<TDS>: You can hold {ffff00}~k~~SNEAK_ABOUT~ key {ffffff}to slow movement or hold {ffff00}~k~~PED_JUMPING~ key {ffffff}to speed up movement");
					SendClientMessage(playerid,-1,"<TDS>: Press {00ffff}~k~~PED_SPRINT~ key {ffffff}to confirm size!");
		        }

		    }
		    else ShowTextdrawMenu(playerid);
		}
		case DIALOG_FONT_SIZE_INPUT:
		{
		    if(response)
		    {
		        new string[128];
		        new textdrawid = GetPVarInt(playerid,"EditTD");
		        if(!IsNull(inputtext))
		        {
				    new idx = 0;
				    new Float:newpos[2];
					string = strtok(inputtext,idx);
					newpos[0] = floatstr(string);
					string = strtok(inputtext,idx);
					newpos[1] = floatstr(string);
					SetTextdrawFontSize(textdrawid,newpos[0],newpos[1]);
		        }
		        format(string,sizeof(string),"Please input size below\nExample: \"1.0 2.0\"\nCurrent: %.2f %.2f",TextdrawInfo[textdrawid][LetterSize][0],TextdrawInfo[textdrawid][LetterSize][1]);
          		ShowPlayerDialog(playerid,DIALOG_FONT_SIZE_INPUT,DIALOG_STYLE_INPUT,"Input Text Size",string,"Input","Back");
		    }
		    else ShowTextdrawMenu(playerid);
		}
		case DIALOG_ALIGNMENT:
		{
		    if(response)
		    {
		        new textdrawid = GetPVarInt(playerid,"EditTD");
		    	SetTextdrawAlignment(textdrawid,(listitem+1));
		    	ShowPlayerDialog(playerid,DIALOG_ALIGNMENT,DIALOG_STYLE_LIST,"Set Alignment","Left\nCenter\nRight","Select","Back");
			}
			else ShowTextdrawMenu(playerid);
		}
		case DIALOG_FONT_COLOR:
		{
		    if(response)
		    {
		        if(listitem == 0)
		        {
		            ShowPlayerDialog(playerid,DIALOG_FONT_COLOR_INPUT,DIALOG_STYLE_INPUT,"Input Text Color","Please input color in RGBA format\nExample: \"255 0 0 255\"","Input","Back");
		        }
		        else if(listitem == 1)
		        {
		        
		        }
		    }
		    else ShowTextdrawMenu(playerid);
		}
		case DIALOG_FONT_COLOR_INPUT:
		{
		    if(response)
		    {
		        new textdrawid = GetPVarInt(playerid,"EditTD");
		        if(!IsNull(inputtext))
		        {
				    new idx = 0;
				    new string[128];
				    new color[4];
				    string = strtok(inputtext,idx);
					color[0] = strval(string);
					string = strtok(inputtext,idx);
					color[1] = strval(string);
					string = strtok(inputtext,idx);
					color[2] = strval(string);
					string = strtok(inputtext,idx);
					color[3] = strval(string);
					SetTextdrawColor(textdrawid,RGBAToInt(color[0],color[1],color[2],color[3]));
		        }
		        ShowPlayerDialog(playerid,DIALOG_FONT_COLOR_INPUT,DIALOG_STYLE_INPUT,"Input Text Size","Please input color in RGBA format\nExample: \"255 0 0 255\"","Input","Back");
            }
		    else ShowTextdrawMenu(playerid);
		}
		case DIALOG_BOX_OPTION:
		{
		    if(response)
		    {
		        new textdrawid = GetPVarInt(playerid,"EditTD");
		        if(listitem == 0)
		        {
					new use = TextdrawInfo[textdrawid][UseBox];
					if(use) use = 0;
					else use = 1;
					ToggleTextdrawBox(textdrawid,use);
					ShowPlayerDialog(playerid,DIALOG_BOX_OPTION,DIALOG_STYLE_LIST,"Box Option","Toggle\nSize\nColor","Select","Back");
		        }
		        else if(listitem == 1)
		        {
		            ShowPlayerDialog(playerid,DIALOG_BOX_SIZE,DIALOG_STYLE_LIST,"Set Box Size","Manual input\nStretch","Select","Back");
		        }
		        else if(listitem == 2)
		        {
		            ShowPlayerDialog(playerid,DIALOG_BOX_COLOR,DIALOG_STYLE_LIST,"Set Box Color","Manual Input\nChoose predefined","Select","Back");
		        }
		    }
		    else ShowTextdrawMenu(playerid);
		}
		case DIALOG_BOX_SIZE:
		{
		    new textdrawid = GetPVarInt(playerid,"EditTD");
		    if(response)
		    {
		        if(listitem == 0)
		        {
		            new string[128];
		            format(string,sizeof(string),"Please input size below\nExample: \"1.0 2.0\"\nCurrent: %.2f %.2f",TextdrawInfo[textdrawid][TextSize][0],TextdrawInfo[textdrawid][TextSize][1]);
		            ShowPlayerDialog(playerid,DIALOG_BOX_SIZE_INPUT,DIALOG_STYLE_INPUT,"Input Box Size",string,"Input","Back");
		        }
		        else if(listitem == 1)
		        {
                    SetPVarInt(playerid,"EditType",3);
					TogglePlayerControllable(playerid,0);
					SendClientMessage(playerid,-1,"<TDS>: Use your {ffff00}WASD {ffffff}or {ffff00}Arrow keys {ffffff}to scale the textdraw size!");
					SendClientMessage(playerid,-1,"<TDS>: You can hold {ffff00}~k~~SNEAK_ABOUT~ key {ffffff}to slow movement or hold {ffff00}~k~~PED_JUMPING~ key {ffffff}to speed up movement");
					SendClientMessage(playerid,-1,"<TDS>: Press {00ffff}~k~~PED_SPRINT~ key {ffffff}to confirm size!");
		        }
		    }
		    else
			{
			    if(TextdrawInfo[textdrawid][Font] == 4 || TextdrawInfo[textdrawid][Font] == 5) ShowTextdrawMenu(playerid);
			    else ShowPlayerDialog(playerid,DIALOG_BOX_OPTION,DIALOG_STYLE_LIST,"Box Option","Toggle\nSize\nColor","Select","Back");
			}
		}
		case DIALOG_BOX_SIZE_INPUT:
		{
		    if(response)
		    {
		        new string[128];
		        new textdrawid = GetPVarInt(playerid,"EditTD");
		        if(!IsNull(inputtext))
		        {
				    new idx = 0;
				    new Float:newpos[2];
					string = strtok(inputtext,idx);
					newpos[0] = floatstr(string);
					string = strtok(inputtext,idx);
					newpos[1] = floatstr(string);
					SetTextdrawSize(textdrawid,newpos[0],newpos[1]);
		        }
		        format(string,sizeof(string),"Please input size below\nExample: \"1.0 2.0\"\nCurrent: %.2f %.2f",TextdrawInfo[textdrawid][TextSize][0],TextdrawInfo[textdrawid][TextSize][1]);
          		ShowPlayerDialog(playerid,DIALOG_BOX_SIZE_INPUT,DIALOG_STYLE_INPUT,"Input Box Size",string,"Input","Back");
		    }
		    else ShowPlayerDialog(playerid,DIALOG_BOX_OPTION,DIALOG_STYLE_LIST,"Box Option","Toggle\nSize\nColor","Select","Back");
		}
		case DIALOG_BOX_COLOR:
		{
			if(response)
			{
			    if(listitem == 0)
		        {
		            ShowPlayerDialog(playerid,DIALOG_BOX_COLOR_INPUT,DIALOG_STYLE_INPUT,"Input Box Color","Please input color in RGBA format\nExample: \"255 0 0 255\"","Input","Back");
		        }
		        else if(listitem == 1)
		        {
		        
		        }
			}
			else ShowPlayerDialog(playerid,DIALOG_BOX_OPTION,DIALOG_STYLE_LIST,"Box Option","Toggle\nSize\nColor","Select","Back");
		}
		case DIALOG_BOX_COLOR_INPUT:
		{
		    if(response)
		    {
		        new textdrawid = GetPVarInt(playerid,"EditTD");
		        if(!IsNull(inputtext))
		        {
				    new idx = 0;
				    new string[128];
				    new color[4];
				    string = strtok(inputtext,idx);
					color[0] = strval(string);
					string = strtok(inputtext,idx);
					color[1] = strval(string);
					string = strtok(inputtext,idx);
					color[2] = strval(string);
					string = strtok(inputtext,idx);
					color[3] = strval(string);
					SetTextdrawBoxColor(textdrawid,RGBAToInt(color[0],color[1],color[2],color[3]));
		        }
		        ShowPlayerDialog(playerid,DIALOG_BOX_COLOR_INPUT,DIALOG_STYLE_INPUT,"Input Box Size","Please input color in RGBA format\nExample: \"255 0 0 255\"","Input","Back");
		    }
		    else ShowPlayerDialog(playerid,DIALOG_BOX_OPTION,DIALOG_STYLE_LIST,"Box Option","Toggle\nSize\nColor","Select","Back");
		}
		case DIALOG_OUTLINE_OPTION:
		{
		    if(response)
		    {
		        new textdrawid = GetPVarInt(playerid,"EditTD");
		        new string[128];
				if(listitem == 0)
				{
					format(string,sizeof(string),"Please input outline size below\nCurrent size: %d",TextdrawInfo[textdrawid][OutlineSize]);
				    ShowPlayerDialog(playerid,DIALOG_OUTLINE_SIZE,DIALOG_STYLE_INPUT,"Input Outline Size",string,"Input","Back");
				}
				else if(listitem == 1)
				{
				    format(string,sizeof(string),"Please input shadow size below\nCurrent size: %d",TextdrawInfo[textdrawid][ShadowSize]);
				    ShowPlayerDialog(playerid,DIALOG_SHADOW_SIZE,DIALOG_STYLE_INPUT,"Input Shadow Size",string,"Input","Back");
				}
				else if(listitem == 2)
				{
				    ShowPlayerDialog(playerid,DIALOG_OUTLINE_COLOR,DIALOG_STYLE_LIST,"Outline Color","Manual Input\nChoose predefined","Select","Back");
				}
		    }
		    else ShowTextdrawMenu(playerid);
		}
		case DIALOG_OUTLINE_SIZE:
		{
		    if(response)
		    {
		        new textdrawid = GetPVarInt(playerid,"EditTD");
	        	new string[128];
		        if(!IsNull(inputtext))
		        {
		            new size = strval(inputtext);
					SetTextdrawOutline(textdrawid,size);
		        }
		        format(string,sizeof(string),"Please input outline size below\nCurrent size: %d",TextdrawInfo[textdrawid][OutlineSize]);
		    	ShowPlayerDialog(playerid,DIALOG_OUTLINE_SIZE,DIALOG_STYLE_INPUT,"Input Outline Size",string,"Input","Back");
			}
			else ShowPlayerDialog(playerid,DIALOG_OUTLINE_OPTION,DIALOG_STYLE_LIST,"Outline Option","Outline Size\nShadow Size\nColor","Select","Back");
		}
		case DIALOG_SHADOW_SIZE:
		{
		    if(response)
		    {
		        new textdrawid = GetPVarInt(playerid,"EditTD");
	        	new string[128];
		        if(!IsNull(inputtext))
		        {
		            new size = strval(inputtext);
					SetTextdrawShadow(textdrawid,size);
		        }
		        format(string,sizeof(string),"Please input shadow size below\nCurrent size: %d",TextdrawInfo[textdrawid][ShadowSize]);
		    	ShowPlayerDialog(playerid,DIALOG_SHADOW_SIZE,DIALOG_STYLE_INPUT,"Input Shadow Size",string,"Input","Back");
			}
			else ShowPlayerDialog(playerid,DIALOG_OUTLINE_OPTION,DIALOG_STYLE_LIST,"Outline Option","Outline Size\nShadow Size\nColor","Select","Back");
		}
		case DIALOG_OUTLINE_COLOR:
		{
		    new textdrawid = GetPVarInt(playerid,"EditTD");
		    if(response)
		    {
                if(listitem == 0)
		        {
		            ShowPlayerDialog(playerid,DIALOG_OUTLINE_COLOR_INPUT,DIALOG_STYLE_INPUT,"Input Outline Color","Please input color in RGBA format\nExample: \"255 0 0 255\"","Input","Back");
		        }
		        else if(listitem == 1)
		        {

		        }
		    }
		    else
		    {
		    	if(TextdrawInfo[textdrawid][Font] == 5) ShowTextdrawMenu(playerid);
		    	else ShowPlayerDialog(playerid,DIALOG_OUTLINE_OPTION,DIALOG_STYLE_LIST,"Outline Option","Outline Size\nShadow Size\nColor","Select","Back");
			}
		}
		case DIALOG_OUTLINE_COLOR_INPUT:
		{
		    if(response)
		    {
		        new textdrawid = GetPVarInt(playerid,"EditTD");
		        if(!IsNull(inputtext))
		        {
				    new idx = 0;
				    new string[128];
				    new color[4];
				    string = strtok(inputtext,idx);
					color[0] = strval(string);
					string = strtok(inputtext,idx);
					color[1] = strval(string);
					string = strtok(inputtext,idx);
					color[2] = strval(string);
					string = strtok(inputtext,idx);
					color[3] = strval(string);
					SetTextdrawOutlineColor(textdrawid,RGBAToInt(color[0],color[1],color[2],color[3]));
		        }
		        ShowPlayerDialog(playerid,DIALOG_OUTLINE_COLOR_INPUT,DIALOG_STYLE_INPUT,"Input Outline Color","Please input color in RGBA format\nExample: \"255 0 0 255\"","Input","Back");
		    }
		    else ShowPlayerDialog(playerid,DIALOG_OUTLINE_COLOR,DIALOG_STYLE_LIST,"Outline Color","Manual Input\nChoose predefined","Select","Back");
		}
	}
	return 1;
}
