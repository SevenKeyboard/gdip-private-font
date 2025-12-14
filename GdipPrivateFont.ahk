#Requires AutoHotkey v1.1.35+
#Include %A_ScriptDir%
#Include .\lib\GdipInit.ahk ;  Before creating a class instance, initialize with GdipInit.startup().
;==============================================================
; GdipPrivateFont — GDI+ private font collection helper
;
; GitHub: https://github.com/SevenKeyboard/gdip-private-font
; Author: SevenKeyboard Ltd. (2025)
; License: MIT License
;
; Documentation / References:
;   Font Functions
;     https://learn.microsoft.com/en-us/windows/win32/gdiplus/-gdiplus-font-flat
;   Status enumeration (gdiplustypes.h)
;     https://learn.microsoft.com/en-us/windows/win32/api/gdiplustypes/ne-gdiplustypes-status
;   Re: [Class] ImageButton
;     https://www.autohotkey.com/boards/viewtopic.php?style=23&t=1103&start=120
;   Fonts added with AddFontResourceEx are not working in GDI+
;     https://stackoverflow.com/questions/42595856/fonts-added-with-addfontresourceex-are-not-working-in-gdi
;==============================================================
class VersionManager_GdipPrivateFont
{
    static _ := VersionManager_GdipPrivateFont._init()
    _init()    {
        global
        GDIPPRIVATEFONT_VERSION := "1.0.0"
        if (!this._verCheck(GDIPINIT_VERSION, "1.0.0"))
            throw exception("GdipInit version 1.x is required (minimum 1.0.0).")
        return true
    }
    _verCheck(byRef actual, required)    {
        if !isSet(actual)
            return false
        actualMajor     := strSplit(actual, ".",, 2)[1]
        requiredMajor   := strSplit(required, ".",, 2)[1]
        if (actualMajor !== requiredMajor)
            return false
        return verCompare(actual, ">=" required)
    }
}
class GdipPrivateFont
{
    __new()    {
        this._filenames:={}, this._fontFamilies:={}, this._nameTofontFamily:={}
        if (format("{2}", this.gdipNewPrivateFontCollection(_), this._fontCollection:=_))
            this._fnCleanUpResources:=objBindMethod(this,"_cleanUpResources"), GdipInit.onShutdown(this._fnCleanUpResources)
        return this
    }
    __delete()    {
        this.releaseAllReferences(), this._cleanUpResources()
    }
    releaseAllReferences()    {
        if (this.hasKey("_fnCleanUpResources"))
            GdipInit.onShutdown(this._fnCleanUpResources,0), this.delete("_fnCleanUpResources")
    }
    _cleanUpResources(_*)    { ;  onExit
        for fontFamily in this._fontFamilies
            this.gdipDeleteFontFamily(fontFamily)
        this._filenames:={}, this._fontFamilies:={}, this._nameTofontFamily:={}
        if (this._fontCollection)
            this.gdipDeletePrivateFontCollection(this._fontCollection), this._fontCollection:=0
    }
    IsEnabled    {
        get  {
            return (!!this._fontCollection)
        }
    }
    ;--------------------------------------
    fileAdd(filename)    { ;  Absolute font file path (e.g. "C:\Windows\Fonts\NotoSansKR-Regular.otf")
        static Ok:=0
        if (!this.IsEnabled || filename=="")
            return false
        if !(bRet:=this._filenames.hasKey(filename))    {
            if (this.gdipPrivateAddFontFile(this._fontCollection,filename)==Ok)
                this._filenames[filename]:="", bRet:=true
        }
        return bRet
    }
    familyCreate(name)    { ;  "Noto Sans KR"
        if (!this.IsEnabled || name=="")
            return 0
        switch (this._nameTofontFamily.hasKey(name))
        {
            case true:      fontFamily:=this._nameTofontFamily[name]
            default:
                this.gdipCreateFontFamilyFromName(name, this._fontCollection, fontFamily:=0)
                if (fontFamily)
                    this._nameTofontFamily[name]:=fontFamily, this._fontFamilies[fontFamily]:=""
        }
        return fontFamily
    }
    familyDelete(name)    { ;  "Noto Sans KR"
        if (!this.IsEnabled || name=="")
            return
        if (this._nameTofontFamily.hasKey(name))
            this.gdipDeleteFontFamily(fontFamily:=this._nameTofontFamily[name]), this._nameTofontFamily.delete(name), this._fontFamilies.delete(fontFamily)
    }
    ;--------------------------------------
    /*
    gdipCreateFont(fontFamily, emSize, style, unit, byRef font)    { ;  GpStatus WINGDIPAPI GdipCreateFont( GDIPCONST GpFontFamily *fontFamily, REAL emSize, INT style, Unit unit, GpFont **font )
        return dllCall("Gdiplus.dll\GdipCreateFont", "Ptr",fontFamily, "Float",emSize, "Int",style, "Int",unit, "Ptr*",font:=0, "Int")
    }
    */
    gdipNewPrivateFontCollection(byRef fontCollection)    { ;  GpStatus WINGDIPAPI GdipNewPrivateFontCollection(GpFontCollection** fontCollection)
        return dllCall("Gdiplus.dll\GdipNewPrivateFontCollection", "Ptr*",fontCollection:=0, "Int")
    }
    gdipDeletePrivateFontCollection(byRef fontCollection)    { ;  GpStatus WINGDIPAPI GdipDeletePrivateFontCollection(GpFontCollection** fontCollection)
        return dllCall("Gdiplus.dll\GdipDeletePrivateFontCollection", "Ptr*",fontCollection:=0, "Int")
    }
    gdipPrivateAddFontFile(fontCollection, filename)    { ;  GpStatus WINGDIPAPI GdipPrivateAddFontFile(GpFontCollection* fontCollection, GDIPCONST WCHAR* filename )
        return format("{3}", varSetCapacity(buf,(strLen(filename)+1)*2,0)
            ,strPut(filename,&buf,"UTF-16")
            ,dllCall("Gdiplus.dll\GdipPrivateAddFontFile", "Ptr",fontCollection, "Ptr",&buf, "Int"))
    }
    gdipDeleteFontFamily(fontFamily)    { ;  GpStatus WINGDIPAPI GdipDeleteFontFamily(GpFontFamily *fontFamily)
        return dllCall("Gdiplus.dll\GdipDeleteFontFamily", "Ptr",fontFamily, "Int")
    }
    gdipCreateFontFamilyFromName(name, fontCollection, byRef FontFamily)    { ;  GpStatus WINGDIPAPI GdipCreateFontFamilyFromName(GDIPCONST WCHAR *name, GpFontCollection *fontCollection, GpFontFamily **FontFamily)
        return format("{3}", varSetCapacity(buf,(strLen(name)+1)*2,0)
            ,strPut(name,&buf,"UTF-16")
            ,dllCall("Gdiplus.dll\GdipCreateFontFamilyFromName", "Ptr",&buf, "Ptr",fontCollection, "Ptr*",FontFamily:=0, "Int"))
    }
}