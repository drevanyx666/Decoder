--!strict

type DecodeResult = {method: string, result: string, score: number}

local Decoder: any = {}

Decoder.B64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
Decoder.B64UrlChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
Decoder.B32Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
Decoder.B62Chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
Decoder.B36Chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
Decoder.B58Chars = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
Decoder.B85Ascii = "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
Decoder.B91Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&()*+,./:;<=>?@[]^_`{|}~\""
Decoder.UuChars = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_"

Decoder.QwertyRows = {
	"1234567890-=",
	"qwertyuiop[]",
	"asdfghjkl;'",
	"zxcvbnm,./"
}

Decoder.MorseMap = {
	[".-"]="A",["-..."]="B",["-.-."]="C",["-.."]="D",["."]="E",["..-."]="F",["--."]="G",["...."]="H",
	[".."]="I",[".---"]="J",["-.-"]="K",[".-.."]="L",["--"]="M",["-."]="N",["---"]="O",[".--."]="P",
	["--.-"]="Q",[".-."]="R",["..."]="S",["-"]="T",["..-"]="U",["...-"]="V",[".--"]="W",["-..-"]="X",
	["-.--"]="Y",["--.."]="Z",[".----"]="1",["..---"]="2",["...--"]="3",["....-"]="4",["....."]="5",
	["-...."]="6",["--..."]="7",["---.."]="8",["----."]="9",["-----"]="0"
}

Decoder.BaconMap = {
	AAAAA="A",AAAAB="B",AAABA="C",AAABB="D",AABAA="E",AABAB="F",AABBA="G",AABBB="H",
	ABAAA="I",ABAAB="J",ABABA="K",ABABB="L",ABBAA="M",ABBAB="N",ABBBA="O",ABBBB="P",
	BAAAA="Q",BAAAB="R",BAABA="S",BAABB="T",BABAA="U",BABAB="V",BABBA="W",BABBB="X",BBAAA="Y",BBAAB="Z"
}

Decoder.PolybiusMap = {
	["11"]="A",["12"]="B",["13"]="C",["14"]="D",["15"]="E",["21"]="F",["22"]="G",["23"]="H",["24"]="I",["25"]="K",
	["31"]="L",["32"]="M",["33"]="N",["34"]="O",["35"]="P",["41"]="Q",["42"]="R",["43"]="S",["44"]="T",["45"]="U",
	["51"]="V",["52"]="W",["53"]="X",["54"]="Y",["55"]="Z"
}

Decoder.LeetMap = {
	["0"]="O",["1"]="I",["3"]="E",["4"]="A",["5"]="S",["6"]="G",["7"]="T",["8"]="B",["9"]="G",
	["@"]="A",["$"]="S",["|"]="I",["!"]="I",["+"]="T",["("]="C",[")"]="C",["["]="C",["]"]="D",
	["<"]="C",[">"]="C",["{"]="C",["}"]="C"
}

Decoder.HtmlEnts = {
	["&amp;"]="&",["&lt;"]="<",["&gt;"]=">",["&quot;"]='"',["&apos;"]="'",["&nbsp;"]=" ",["&copy;"]="©",["&reg;"]="®"
}

Decoder.ZwChars = {
	["\u200b"]=true,["\u200c"]=true,["\u200d"]=true,["\u200e"]=true,["\u200f"]=true,["\u2060"]=true,
	["\u2062"]=true,["\u2063"]=true,["\u2064"]=true,["\ufeff"]=true,["\u202a"]=true,["\u202b"]=true,
	["\u202c"]=true,["\u202d"]=true,["\u202e"]=true,["\u2066"]=true,["\u2067"]=true,["\u2068"]=true,["\u2069"]=true
}

function Decoder.Base64(Txt: string): string?
	Txt = Txt:gsub("%s+", "")
	if #Txt < 4 then return nil end
	local Valid: number = 0
	for I = 1, #Txt do
		local C: string = Txt:sub(I,I)
		if Decoder.B64Chars:find(C, 1, true) or C == "=" then Valid = Valid + 1 end
	end
	if Valid / #Txt < 0.8 then return nil end
	while #Txt % 4 ~= 0 do Txt = Txt .. "=" end
	Txt = Txt:gsub("[^" .. Decoder.B64Chars:gsub("[-]", "%%-") .. "=]", "")
	local R: string = (Txt:gsub(".", function(X: string): string
		if X == "=" then return "" end
		local F: number? = Decoder.B64Chars:find(X, 1, true)
		if not F then return "" end
		F = F - 1
		local Bin: string = ""
		for I = 6, 1, -1 do
			Bin = Bin .. (F % 2^I - F % 2^(I-1) > 0 and "1" or "0")
		end
		return Bin
	end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(X: string): string
		if #X ~= 8 then return "" end
		local C: number = 0
		for I = 1, 8 do
			C = C + (X:sub(I,I) == "1" and 2^(8-I) or 0)
		end
		return string.char(C)
	end))
	local Printable: number = 0
	for I = 1, #R do
		local B: number = R:sub(I,I):byte()
		if B >= 32 and B <= 126 then Printable = Printable + 1 end
	end
	return Printable / #R > 0.7 and R or nil
end

function Decoder.Base16(Txt: string): string?
	return Decoder.Hex(Txt)
end

function Decoder.Base64Url(Txt: string): string?
	Txt = Txt:gsub("%s+", "")
	if #Txt < 4 then return nil end
	local Valid: number = 0
	for I = 1, #Txt do
		local C: string = Txt:sub(I,I)
		if Decoder.B64UrlChars:find(C, 1, true) or C == "=" then Valid = Valid + 1 end
	end
	if Valid / #Txt < 0.8 then return nil end
	Txt = Txt:gsub("[-]", "+"):gsub("_", "/")
	while #Txt % 4 ~= 0 do Txt = Txt .. "=" end
	return Decoder.Base64(Txt)
end

function Decoder.Base32(Txt: string): string?
	Txt = Txt:upper():gsub("%s+", "")
	if #Txt < 5 then return nil end
	local Valid: number = 0
	for I = 1, #Txt do
		local C: string = Txt:sub(I,I)
		if Decoder.B32Chars:find(C, 1, true) or C == "=" then Valid = Valid + 1 end
	end
	if Valid / #Txt < 0.8 then return nil end
	local Bin: string = ""
	for I = 1, #Txt do
		local C: string = Txt:sub(I,I)
		if C ~= "=" then
			local Val: number? = Decoder.B32Chars:find(C, 1, true)
			if Val then
				Val = Val - 1
				for J = 4, 0, -1 do
					Bin = Bin .. (Val >= 2^J and "1" or "0")
					Val = Val % 2^J
				end
			end
		end
	end
	local Res: string = ""
	for I = 1, #Bin - 7, 8 do
		local Byte: string = Bin:sub(I, I+7)
		Res = Res .. string.char(tonumber(Byte, 2) or 0)
	end
	return Decoder.ScoreResult(Res) > 40 and Res or nil
end

function Decoder.Base62(Txt: string): string?
	Txt = Txt:gsub("%s+", "")
	if #Txt < 8 then return nil end
	local Valid: number = 0
	for I = 1, #Txt do
		if Decoder.B62Chars:find(Txt:sub(I,I), 1, true) then Valid = Valid + 1 end
	end
	if Valid / #Txt < 0.9 then return nil end
	local Num: number = 0
	for I = 1, #Txt do
		local Pos: number? = Decoder.B62Chars:find(Txt:sub(I,I), 1, true)
		if not Pos then return nil end
		Num = Num * 62 + (Pos - 1)
	end
	local Res: string = ""
	while Num > 0 do
		Res = string.char(Num % 256) .. Res
		Num = math.floor(Num / 256)
	end
	if #Res == 0 then return nil end
	if not Res:match("[%a]") then return nil end
	return Decoder.ScoreResult(Res) > 60 and Res or nil
end

function Decoder.Base36(Txt: string): string?
	Txt = Txt:upper():gsub("%s+", "")
	if #Txt < 8 then return nil end
	local Valid: number = 0
	for I = 1, #Txt do
		if Decoder.B36Chars:find(Txt:sub(I,I), 1, true) then Valid = Valid + 1 end
	end
	if Valid / #Txt < 0.9 then return nil end
	local Num: number = 0
	for I = 1, #Txt do
		local Pos: number? = Decoder.B36Chars:find(Txt:sub(I,I), 1, true)
		if not Pos then return nil end
		Num = Num * 36 + (Pos - 1)
	end
	local Res: string = ""
	while Num > 0 do
		Res = string.char(Num % 256) .. Res
		Num = math.floor(Num / 256)
	end
	if #Res == 0 then return nil end
	if not Res:match("[%a]") then return nil end
	return Decoder.ScoreResult(Res) > 60 and Res or nil
end

function Decoder.Base58(Txt: string): string?
	Txt = Txt:gsub("%s+", "")
	if #Txt < 2 then return nil end
	local Valid: number = 0
	for I = 1, #Txt do
		if Decoder.B58Chars:find(Txt:sub(I,I), 1, true) then Valid = Valid + 1 end
	end
	if Valid / #Txt < 0.9 then return nil end
	local Num: number = 0
	for I = 1, #Txt do
		local Pos: number? = Decoder.B58Chars:find(Txt:sub(I,I), 1, true)
		if not Pos then return nil end
		Num = Num * 58 + (Pos - 1)
	end
	local Res: string = ""
	while Num > 0 do
		Res = string.char(Num % 256) .. Res
		Num = math.floor(Num / 256)
	end
	for I = 1, #Txt do
		if Txt:sub(I,I) == "1" then Res = "\0" .. Res else break end
	end
	if #Res == 0 then return nil end
	return Decoder.ScoreResult(Res) > 40 and Res or nil
end

function Decoder.Base85(Txt: string): string?
	local HasDelim: boolean = Txt:find("<~") ~= nil or Txt:find("~>") ~= nil
	Txt = Txt:gsub("^<~", ""):gsub("~>$", ""):gsub("%s+", "")
	if #Txt < 5 then return nil end
	local Valid: number = 0
	local ZCount: number = 0
	for I = 1, #Txt do
		local C: string = Txt:sub(I,I)
		if C == "z" then
			ZCount = ZCount + 1
		elseif Decoder.B85Ascii:find(C, 1, true) then
			Valid = Valid + 1
		end
	end
	if not HasDelim and (Valid + ZCount) / #Txt < 0.8 then return nil end
	local Res: string = ""
	local I: number = 1
	while I <= #Txt do
		if Txt:sub(I,I) == "z" then
			if (I - 1) % 5 == 0 then
				Res = Res .. "\0\0\0\0"
				I = I + 1
			else
				return nil
			end
		else
			local Chunk: string = Txt:sub(I, I+4)
			local OrigLen: number = #Chunk
			if #Chunk < 5 then
				Chunk = Chunk .. string.rep("u", 5 - #Chunk)
			end
			local Val: number = 0
			for J = 1, 5 do
				local C: string = Chunk:sub(J,J)
				local Pos: number? = Decoder.B85Ascii:find(C, 1, true)
				if not Pos then break end
				Val = Val * 85 + (Pos - 1)
			end
			local Bytes: string = ""
			for J = 3, 0, -1 do
				Bytes = Bytes .. string.char(math.floor(Val / 256^J) % 256)
			end
			if OrigLen < 5 then
				Bytes = Bytes:sub(1, OrigLen - 1)
			end
			Res = Res .. Bytes
			I = I + 5
		end
	end
	return Decoder.ScoreResult(Res) > 40 and Res or nil
end

function Decoder.Base91(Txt: string): string?
	Txt = Txt:gsub("%s+", "")
	if #Txt < 4 then return nil end
	local Valid: number = 0
	for I = 1, #Txt do
		if Decoder.B91Chars:find(Txt:sub(I,I), 1, true) then Valid = Valid + 1 end
	end
	if Valid / #Txt < 0.8 then return nil end
	local Res: string = ""
	local V: number = -1
	local B: number = 0
	local N: number = 0
	for I = 1, #Txt do
		local C: string = Txt:sub(I,I)
		local P: number? = Decoder.B91Chars:find(C, 1, true)
		if P then
			P = P - 1
			if V < 0 then
				V = P
			else
				V = V + P * 91
				if V % 2^13 > 88 then
					B = B + (V % 2^13) * 2^N
					N = N + 13
				else
					B = B + (V % 2^14) * 2^N
					N = N + 14
				end
				while true do
					Res = Res .. string.char(B % 256)
					B = math.floor(B / 256)
					N = N - 8
					if N <= 7 then break end
				end
				V = -1
			end
		end
	end
	if V >= 0 then
		Res = Res .. string.char((B + V * 2^N) % 256)
	end
	return Decoder.ScoreResult(Res) > 40 and Res or nil
end

function Decoder.Uuencode(Txt: string): string?
	local Lines: {string} = {}
	for Line in Txt:gmatch("[^\r\n]+") do
		Lines[#Lines + 1] = Line
	end
	if #Lines < 3 then return nil end
	if not Lines[1]:find("^begin %d+ ") then return nil end
	if not Lines[#Lines]:find("^end") then return nil end
	local Res: string = ""
	for I = 2, #Lines - 1 do
		local Line: string = Lines[I]
		if #Line == 0 then continue end
		local Len: number = Line:sub(1,1):byte() - 32
		if Len < 0 or Len > 45 then continue end
		local Data: string = Line:sub(2)
		local Decoded: string = ""
		local J: number = 1
		while J <= #Data and #Decoded < Len do
			if J + 3 > #Data then break end
			local Chunk: string = Data:sub(J, J+3)
			local Vals: {number} = {}
			for K = 1, 4 do
				local B: number = Chunk:sub(K,K):byte() - 32
				if B == 64 then B = 0 end
				Vals[K] = B % 64
			end
			local Val: number = Vals[1] * 262144 + Vals[2] * 4096 + Vals[3] * 64 + Vals[4]
			Decoded = Decoded .. string.char(math.floor(Val / 65536) % 256)
			if #Decoded < Len then
				Decoded = Decoded .. string.char(math.floor(Val / 256) % 256)
			end
			if #Decoded < Len then
				Decoded = Decoded .. string.char(Val % 256)
			end
			J = J + 4
		end
		Res = Res .. Decoded:sub(1, Len)
	end
	if #Res == 0 then return nil end
	return Decoder.ScoreResult(Res) > 40 and Res or nil
end

function Decoder.QuotedPrintable(Txt: string): string?
	if not Txt:find("=") then return nil end
	local EqCount: number = 0
	for I = 1, #Txt do
		if Txt:sub(I,I) == "=" then EqCount = EqCount + 1 end
	end
	if EqCount < 2 then return nil end
	local Res: string = Txt:gsub("=\r?\n", "")
	Res = Res:gsub("=(%x%x)", function(H: string): string
		return string.char(tonumber(H, 16) or 0)
	end)
	if Res == Txt then return nil end
	return Decoder.ScoreResult(Res) > 40 and Res or nil
end

function Decoder.Hex(Txt: string): string?
	local Clean: string = Txt:gsub("%s+", ""):gsub("^0x", ""):gsub("\\x", "")
	if #Clean < 2 or #Clean % 2 ~= 0 then return nil end
	for I = 1, #Clean do
		if not Clean:sub(I,I):match("[0-9a-fA-F]") then return nil end
	end
	local R: string = Clean:gsub("..", function(X: string): string
		return string.char(tonumber(X, 16) or 0)
	end)
	if R == "" then return nil end
	return Decoder.ScoreResult(R) > 40 and R or nil
end

function Decoder.Binary(Txt: string): string?
	local Clean: string = Txt:gsub("%s+", ""):gsub("^0b", "")
	if #Clean < 8 then return nil end
	for I = 1, #Clean do
		local C: string = Clean:sub(I,I)
		if C ~= "0" and C ~= "1" then return nil end
	end
	local Res: string = ""
	for I = 1, #Clean - 7, 8 do
		Res = Res .. string.char(tonumber(Clean:sub(I, I+7), 2) or 0)
	end
	if Res == "" then return nil end
	return Decoder.ScoreResult(Res) > 40 and Res or nil
end

function Decoder.Octal(Txt: string): string?
	local Clean: string = Txt:gsub("%s+", ""):gsub("\\", "")
	if #Clean < 3 or #Clean % 3 ~= 0 then return nil end
	local R: string = Clean:gsub("%d%d%d", function(X: string): string
		local Val: number? = tonumber(X, 8)
		if not Val or Val > 255 then return "" end
		return string.char(Val)
	end)
	if R == "" then return nil end
	return Decoder.ScoreResult(R) > 40 and R or nil
end

function Decoder.AsciiCodes(Txt: string): string?
	if not Txt:match("[,%s%-_/]") then return nil end
	local Res: string = ""
	local Count: number = 0
	for Num in Txt:gmatch("[^,%s%-_/]+") do
		if not Num:match("^%d+$") then return nil end
		local N: number? = tonumber(Num)
		if N and N >= 0 and N <= 255 then
			Res = Res .. string.char(N)
			Count = Count + 1
		else
			return nil
		end
	end
	return Count > 2 and Res or nil
end

function Decoder.Decimal(Txt: string): string?
	return Decoder.AsciiCodes(Txt)
end

function Decoder.MorseDecode(Txt: string): string?
	local Res: string = ""
	local Count: number = 0
	for Word in Txt:gmatch("[^/|]+") do
		for Code in Word:gmatch("%S+") do
			local C: string? = Decoder.MorseMap[Code]
			if C then
				Res = Res .. C
				Count = Count + 1
			end
		end
		Res = Res .. " "
	end
	return Count > 2 and Res:sub(1, -2) or nil
end

function Decoder.Caesar(Txt: string, Shift: number): string?
	local Res: string = ""
	local Count: number = 0
	for I = 1, #Txt do
		local C: string = Txt:sub(I,I)
		local Up: boolean = C == C:upper()
		C = C:upper()
		if C:match("[A-Z]") then
			local Pos: number = C:byte() - 65
			local NewPos: number = (Pos - Shift) % 26
			Res = Res .. (Up and string.char(65 + NewPos) or string.char(97 + NewPos))
			Count = Count + 1
		else
			Res = Res .. Txt:sub(I,I)
		end
	end
	return Count > 5 and Res or nil
end

function Decoder.Atbash(Txt: string): string?
	local Res: string = ""
	local Count: number = 0
	for I = 1, #Txt do
		local C: string = Txt:sub(I,I)
		local Up: boolean = C == C:upper()
		C = C:upper()
		if C:match("[A-Z]") then
			local Pos: number = C:byte() - 65
			local NewPos: number = 25 - Pos
			Res = Res .. (Up and string.char(65 + NewPos) or string.char(97 + NewPos))
			Count = Count + 1
		else
			Res = Res .. Txt:sub(I,I)
		end
	end
	return Count > 5 and Res or nil
end

function Decoder.Rot13(Txt: string): string?
	return Decoder.Caesar(Txt, 13)
end

function Decoder.Rot5(Txt: string): string?
	local Res: string = ""
	local Count: number = 0
	for I = 1, #Txt do
		local C: string = Txt:sub(I,I)
		if C:match("%d") then
			Res = Res .. tostring(((tonumber(C) or 0) + 5) % 10)
			Count = Count + 1
		else
			Res = Res .. C
		end
	end
	return Count > 2 and Res or nil
end

function Decoder.Rot18(Txt: string): string?
	local R13: string? = Decoder.Rot13(Txt)
	if not R13 then return nil end
	return Decoder.Rot5(R13)
end

function Decoder.Rot47(Txt: string): string?
	local Res: string = ""
	local Count: number = 0
	for I = 1, #Txt do
		local C: number = Txt:sub(I,I):byte()
		if C >= 33 and C <= 126 then
			C = ((C - 33 + 47) % 94) + 33
			Count = Count + 1
		end
		Res = Res .. string.char(C)
	end
	return Count > 5 and Res or nil
end

function Decoder.A1Z26(Txt: string): string?
	local Res: string = ""
	local Count: number = 0
	for Num in Txt:gmatch("%d+") do
		local N: number? = tonumber(Num)
		if N and N >= 1 and N <= 26 then
			Res = Res .. string.char(64 + N)
			Count = Count + 1
		end
	end
	return Count > 2 and Res or nil
end

function Decoder.BaconDecode(Txt: string): string?
	Txt = Txt:upper():gsub("[^AB]", "")
	if #Txt < 5 then return nil end
	local Res: string = ""
	local Count: number = 0
	for I = 1, #Txt, 5 do
		local Chunk: string = Txt:sub(I, I+4)
		if #Chunk == 5 then
			local C: string? = Decoder.BaconMap[Chunk]
			if C then
				Res = Res .. C
				Count = Count + 1
			end
		end
	end
	return Count > 2 and Res or nil
end

function Decoder.PolybiusDecode(Txt: string): string?
	Txt = Txt:gsub("%s+", "")
	if #Txt < 2 or #Txt % 2 ~= 0 then return nil end
	local Res: string = ""
	local Count: number = 0
	for I = 1, #Txt, 2 do
		local C: string? = Decoder.PolybiusMap[Txt:sub(I, I+1)]
		if C then
			Res = Res .. C
			Count = Count + 1
		end
	end
	return Count > 2 and Res or nil
end

function Decoder.KeyboardShift(Txt: string, Dir: string): string?
	local Res: string = ""
	local Count: number = 0
	for I = 1, #Txt do
		local C: string = Txt:sub(I,I)
		local Orig: string = C
		C = C:lower()
		local Found: boolean = false
		for _, Row: string in Decoder.QwertyRows do
			local Pos: number? = Row:find(C, 1, true)
			if Pos then
				local NewPos: number = Pos
				if Dir == "right" then
					NewPos = Pos + 1
					if NewPos > #Row then NewPos = 1 end
				elseif Dir == "left" then
					NewPos = Pos - 1
					if NewPos < 1 then NewPos = #Row end
				end
				local NewC: string = Row:sub(NewPos, NewPos)
				if Orig == Orig:upper() and Orig:match("[a-zA-Z]") then NewC = NewC:upper() end
				Res = Res .. NewC
				Count = Count + 1
				Found = true
				break
			end
		end
		if not Found then Res = Res .. Orig end
	end
	return Count > 3 and Res or nil
end

function Decoder.Url(Txt: string): string?
	Txt = Txt:gsub("+", " ")
	local Res: string = Txt:gsub("%%(%x%x)", function(H: string): string
		return string.char(tonumber(H, 16) or 0)
	end)
	return Res ~= Txt and Res or nil
end

function Decoder.Html(Txt: string): string?
	local Orig: string = Txt
	for Ent, Char in pairs(Decoder.HtmlEnts) do
		Txt = Txt:gsub(Ent, Char)
	end
	Txt = Txt:gsub("&#(%d+);", function(N: string): string
		return string.char(tonumber(N) or 0)
	end)
	Txt = Txt:gsub("&#x(%x+);", function(H: string): string
		return string.char(tonumber(H, 16) or 0)
	end)
	return Txt ~= Orig and Txt or nil
end

function Decoder.LeetDecode(Txt: string): string?
	local Res: string = ""
	local Count: number = 0
	for I = 1, #Txt do
		local C: string = Txt:sub(I,I)
		local Decoded: string? = Decoder.LeetMap[C]
		if Decoded then
			Res = Res .. Decoded
			Count = Count + 1
		else
			Res = Res .. C
		end
	end
	return Count > 3 and Res or nil
end

function Decoder.Reverse(Txt: string): string?
	if #Txt < 5 then return nil end
	return Txt:reverse()
end

function Decoder.UnicodeEscape(Txt: string): string?
	if not Txt:find("\\u") and not Txt:find("\\U") then return nil end
	local Res: string = Txt:gsub("\\u(%x%x%x%x)", function(H: string): string
		local Val: number? = tonumber(H, 16)
		if Val then
			local S: boolean, C: any = pcall(utf8.char, Val)
			if S then return C end
		end
		return "\\u" .. H
	end)
	Res = Res:gsub("\\U(%x%x%x%x%x%x%x%x)", function(H: string): string
		local Val: number? = tonumber(H, 16)
		if Val then
			local S: boolean, C: any = pcall(utf8.char, Val)
			if S then return C end
		end
		return "\\U" .. H
	end)
	Res = Res:gsub("\\u{(%x+)}", function(H: string): string
		local Val: number? = tonumber(H, 16)
		if Val then
			local S: boolean, C: any = pcall(utf8.char, Val)
			if S then return C end
		end
		return "\\u{" .. H .. "}"
	end)
	return Res ~= Txt and Res or nil
end

function Decoder.Railfence(Txt: string, Rails: number): string?
	if Rails < 2 or #Txt < Rails then return nil end
	local Fence: {{[number]: any}} = {}
	for I = 1, Rails do Fence[I] = {} end
	local Rail: number = 1
	local Dir: number = 1
	for I = 1, #Txt do
		Fence[Rail][I] = 1
		Rail = Rail + Dir
		if Rail == 1 or Rail == Rails then Dir = -Dir end
	end
	local Idx: number = 1
	for R = 1, Rails do
		for C = 1, #Txt do
			if Fence[R][C] then
				Fence[R][C] = Txt:sub(Idx, Idx)
				Idx = Idx + 1
			end
		end
	end
	local Res: string = ""
	Rail = 1
	Dir = 1
	for I = 1, #Txt do
		Res = Res .. (Fence[Rail][I] or "")
		Rail = Rail + Dir
		if Rail == 1 or Rail == Rails then Dir = -Dir end
	end
	return Res ~= Txt and Res or nil
end

function Decoder.Zerowidth(Txt: string): string?
	local Zw: string = ""
	for I = 1, #Txt do
		if Decoder.ZwChars[Txt:sub(I,I)] then Zw = Zw .. Txt:sub(I,I) end
	end
	if #Zw < 8 then return nil end
	local Chars: {string} = {}
	local Counts: {[string]: number} = {}
	for I = 1, #Zw do
		local C: string = Zw:sub(I,I)
		if not Counts[C] then
			Counts[C] = 0
			Chars[#Chars + 1] = C
		end
		Counts[C] = Counts[C] + 1
	end
	if #Chars < 2 or #Chars > 4 then return nil end
	local Perms: {{string}} = {}
	if #Chars == 2 then
		Perms = {{Chars[1], Chars[2]}, {Chars[2], Chars[1]}}
	elseif #Chars == 3 then
		Perms = {
			{Chars[1], Chars[2], Chars[3]}, {Chars[1], Chars[3], Chars[2]},
			{Chars[2], Chars[1], Chars[3]}, {Chars[2], Chars[3], Chars[1]},
			{Chars[3], Chars[1], Chars[2]}, {Chars[3], Chars[2], Chars[1]}
		}
	else
		Perms = {
			{Chars[1],Chars[2],Chars[3],Chars[4]},{Chars[1],Chars[2],Chars[4],Chars[3]},
			{Chars[1],Chars[3],Chars[2],Chars[4]},{Chars[1],Chars[3],Chars[4],Chars[2]},
			{Chars[1],Chars[4],Chars[2],Chars[3]},{Chars[1],Chars[4],Chars[3],Chars[2]},
			{Chars[2],Chars[1],Chars[3],Chars[4]},{Chars[2],Chars[1],Chars[4],Chars[3]},
			{Chars[2],Chars[3],Chars[1],Chars[4]},{Chars[2],Chars[3],Chars[4],Chars[1]},
			{Chars[2],Chars[4],Chars[1],Chars[3]},{Chars[2],Chars[4],Chars[3],Chars[1]},
			{Chars[3],Chars[1],Chars[2],Chars[4]},{Chars[3],Chars[1],Chars[4],Chars[2]},
			{Chars[3],Chars[2],Chars[1],Chars[4]},{Chars[3],Chars[2],Chars[4],Chars[1]},
			{Chars[3],Chars[4],Chars[1],Chars[2]},{Chars[3],Chars[4],Chars[2],Chars[1]},
			{Chars[4],Chars[1],Chars[2],Chars[3]},{Chars[4],Chars[1],Chars[3],Chars[2]},
			{Chars[4],Chars[2],Chars[1],Chars[3]},{Chars[4],Chars[2],Chars[3],Chars[1]},
			{Chars[4],Chars[3],Chars[1],Chars[2]},{Chars[4],Chars[3],Chars[2],Chars[1]}
		}
	end
	local BestResult: string = ""
	local BestScore: number = 0
	for _, Perm in ipairs(Perms) do
		local Bin: string = Zw
		if #Perm == 2 then
			Bin = Bin:gsub(Perm[1], "0"):gsub(Perm[2], "1")
		elseif #Perm == 3 then
			Bin = Bin:gsub(Perm[1], "0"):gsub(Perm[2], "1"):gsub(Perm[3], " ")
		else
			Bin = Bin:gsub(Perm[1], "0"):gsub(Perm[2], "1"):gsub(Perm[3], " "):gsub(Perm[4], "")
		end
		local Decoded: string = ""
		for Chunk in Bin:gmatch("%S+") do
			if #Chunk % 8 == 0 then
				for I = 1, #Chunk, 8 do
					local Val: number? = tonumber(Chunk:sub(I, I+7), 2)
					if Val and Val > 0 and Val < 128 then
						Decoded = Decoded .. string.char(Val)
					end
				end
			end
		end
		if #Decoded > 0 and Decoded:match("%w") then
			local Score: number = Decoder.ScoreResult(Decoded)
			if Score > BestScore then
				BestScore = Score
				BestResult = Decoded
			end
		end
	end
	return BestScore > 40 and BestResult or nil
end

function Decoder.Substitution(Txt: string): string?
	if #Txt < 30 then return nil end
	local Freq: {[string]: number} = {}
	local Total: number = 0
	for I = 1, #Txt do
		local C: string = Txt:sub(I,I):upper()
		if C:match("[A-Z]") then
			Freq[C] = (Freq[C] or 0) + 1
			Total = Total + 1
		end
	end
	if Total < 30 then return nil end
	local CipherFreq: {{char: string, freq: number}} = {}
	for C, Count in pairs(Freq) do
		CipherFreq[#CipherFreq + 1] = {char = C, freq = Count / Total}
	end
	table.sort(CipherFreq, function(A: any, B: any): boolean return A.freq > B.freq end)
	local EngOrder: {string} = {"E","T","A","O","I","N","S","H","R","D","L","C","U","M","W","F","G","Y","P","B","V","K","J","X","Q","Z"}
	local Mapping: {[string]: string} = {}
	for I = 1, math.min(#CipherFreq, #EngOrder) do
		Mapping[CipherFreq[I].char] = EngOrder[I]
	end
	local Res: string = ""
	for I = 1, #Txt do
		local C: string = Txt:sub(I,I)
		local Up: boolean = C == C:upper()
		local Cu: string = C:upper()
		if Mapping[Cu] then
			Res = Res .. (Up and Mapping[Cu] or Mapping[Cu]:lower())
		else
			Res = Res .. C
		end
	end
	return Res ~= Txt and Res or nil
end

function Decoder.JwtDecode(Txt: string): string?
	local Parts: {string} = {}
	for Part in Txt:gmatch("[^.]+") do
		Parts[#Parts + 1] = Part
	end
	if #Parts ~= 3 then return nil end
	local Header: string? = Decoder.Base64Url(Parts[1])
	local Payload: string? = Decoder.Base64Url(Parts[2])
	if not Header or not Payload then return nil end
	if not Header:find("{") or not Payload:find("{") then return nil end
	local HttpService: HttpService = game:GetService("HttpService")
	local S1: boolean, H: any = pcall(function(): any return HttpService:JSONDecode(Header) end)
	local S2: boolean, P: any = pcall(function(): any return HttpService:JSONDecode(Payload) end)
	local HeaderStr: string = Header
	local PayloadStr: string = Payload
	if S1 and type(H) == "table" then HeaderStr = HttpService:JSONEncode(H) end
	if S2 and type(P) == "table" then PayloadStr = HttpService:JSONEncode(P) end
	return `Header: {HeaderStr}\n\nPayload: {PayloadStr}\n\nSignature: {Parts[3]}`
end

function Decoder.XorSingleByte(Txt: string): string?
	if #Txt < 10 then return nil end
	local Best: string = ""
	local BestScore: number = 0
	for Key = 0, 255 do
		local Decoded: string = ""
		local Printable: number = 0
		for I = 1, #Txt do
			local B: number = bit32.bxor(Txt:sub(I,I):byte(), Key)
			if B >= 32 and B <= 126 then Printable = Printable + 1 end
			Decoded = Decoded .. string.char(B)
		end
		if Printable / #Decoded < 0.85 then continue end
		local Score: number = Decoder.ScoreResult(Decoded)
		if Score > BestScore then
			BestScore = Score
			Best = Decoded
		end
	end
	return BestScore > 60 and Best or nil
end

function Decoder.DetectADFGX(Txt: string): boolean
	Txt = Txt:upper():gsub("%s+", "")
	if #Txt < 20 then return false end
	local Valid: number = 0
	for I = 1, #Txt do
		local C: string = Txt:sub(I,I)
		if C == "A" or C == "D" or C == "F" or C == "G" or C == "X" then Valid = Valid + 1 end
	end
	return Valid / #Txt > 0.95
end

function Decoder.DetectADFGVX(Txt: string): boolean
	Txt = Txt:upper():gsub("%s+", "")
	if #Txt < 20 then return false end
	local Valid: number = 0
	for I = 1, #Txt do
		local C: string = Txt:sub(I,I)
		if C == "A" or C == "D" or C == "F" or C == "G" or C == "V" or C == "X" then Valid = Valid + 1 end
	end
	return Valid / #Txt > 0.95
end

function Decoder.DetectVigenere(Txt: string): boolean
	if #Txt < 30 then return false end
	local Letters: number = 0
	for I = 1, #Txt do
		if Txt:sub(I,I):match("[A-Za-z]") then Letters = Letters + 1 end
	end
	if Letters / #Txt < 0.8 then return false end
	local Ioc: number = 0
	local Counts: {[string]: number} = {}
	for I = 1, #Txt do
		local C: string = Txt:sub(I,I):upper()
		if C:match("[A-Z]") then Counts[C] = (Counts[C] or 0) + 1 end
	end
	for C, Count in pairs(Counts) do
		Ioc = Ioc + Count * (Count - 1)
	end
	if Letters > 1 then Ioc = Ioc / (Letters * (Letters - 1)) end
	return Ioc > 0.038 and Ioc < 0.055
end

function Decoder.DetectRepeatingXor(Txt: string): boolean
	local HexTest: string? = Decoder.Hex(Txt)
	return HexTest ~= nil and #Txt > 20
end

function Decoder.GzipDetect(Txt: string): string?
	if #Txt < 10 then return nil end
	local B1: number = Txt:sub(1,1):byte()
	local B2: number = Txt:sub(2,2):byte()
	if B1 == 0x1f and B2 == 0x8b then return "GZIP"
	elseif B1 == 0x78 and (B2 == 0x01 or B2 == 0x9c or B2 == 0xda) then return "ZLIB"
	elseif Txt:sub(1, 8) == "Salted__" then return "OpenSSL"
	elseif B1 == 0x50 and B2 == 0x4b then return "ZIP"
	elseif Txt:sub(1, 6) == "\137PNG\r\n" then return "PNG"
	elseif Txt:sub(1, 2) == "\255\216" then return "JPEG"
	end
	return nil
end

function Decoder.ScoreResult(Txt: string): number
	if #Txt == 0 then return 0 end
	local Printable: number = 0
	local Vowels: number = 0
	local Letters: number = 0
	local Nulls: number = 0
	for I = 1, #Txt do
		local B: number = Txt:sub(I,I):byte()
		local C: string = Txt:sub(I,I):upper()
		if B == 0 then Nulls = Nulls + 1 end
		if B >= 32 and B <= 126 then Printable = Printable + 1 end
		if C:match("[A-Z]") then
			Letters = Letters + 1
			if C:match("[AEIOU]") then Vowels = Vowels + 1 end
		end
	end
	if Nulls > #Txt * 0.3 then return 0 end
	local Score: number = (Printable / #Txt) * 50
	if Letters > 0 then
		local VowelRatio: number = Vowels / Letters
		if VowelRatio >= 0.3 and VowelRatio <= 0.5 then Score = Score + 30
		elseif VowelRatio < 0.1 or VowelRatio > 0.7 then Score = Score - 20 end
	end
	if Txt:match("%w%w%w") then Score = Score + 20 end
	local Entropy: number = 0
	local Counts: {[number]: number} = {}
	for I = 1, #Txt do
		local B: number = Txt:sub(I,I):byte()
		Counts[B] = (Counts[B] or 0) + 1
	end
	for B, Count in pairs(Counts) do
		local P: number = Count / #Txt
		Entropy = Entropy - P * math.log(P) / math.log(2)
	end
	if #Txt > 50 and Entropy < 2 then Score = Score - 30 end
	return Score
end

function Decoder.Autodecode(Txt: string, Depth: number?): {DecodeResult}
	Depth = Depth or 1
	if Depth > 3 then return {} end
	local Results: {DecodeResult} = {}
	local Seen: {[string]: boolean} = {}
	local Compression: string? = Decoder.GzipDetect(Txt)
	if Compression then
		Results[#Results + 1] = {method = Compression, result = "Compressed/Binary data detected", score = 100}
		return Results
	end
	if Decoder.DetectADFGX(Txt) then
		Results[#Results + 1] = {method = "ADFGX", result = "Key required for decryption", score = 15}
	end
	if Decoder.DetectADFGVX(Txt) then
		Results[#Results + 1] = {method = "ADFGVX", result = "Key required for decryption", score = 15}
	end
	if Decoder.DetectVigenere(Txt) then
		Results[#Results + 1] = {method = "Vigenere", result = "Key required for decryption", score = 12}
	end
	if Decoder.DetectRepeatingXor(Txt) then
		Results[#Results + 1] = {method = "RepeatingXOR", result = "Key required for decryption", score = 10}
	end
	local JwtCheck: boolean, JwtRes: any = pcall(function(): string? return Decoder.JwtDecode(Txt) end)
	if JwtCheck and JwtRes and JwtRes ~= Txt and #JwtRes > 0 then
		Results[#Results + 1] = {method = "JWT", result = JwtRes, score = 95}
	end
	local Checks: {{name: string, fn: () -> string?}} = {
		{name = "Base64", fn = function(): string? return Decoder.Base64(Txt) end},
		{name = "Base64Url", fn = function(): string? return Decoder.Base64Url(Txt) end},
		{name = "Base32", fn = function(): string? return Decoder.Base32(Txt) end},
		{name = "Base62", fn = function(): string? return Decoder.Base62(Txt) end},
		{name = "Base58", fn = function(): string? return Decoder.Base58(Txt) end},
		{name = "Base36", fn = function(): string? return Decoder.Base36(Txt) end},
		{name = "Base85", fn = function(): string? return Decoder.Base85(Txt) end},
		{name = "Base91", fn = function(): string? return Decoder.Base91(Txt) end},
		{name = "Base16", fn = function(): string? return Decoder.Base16(Txt) end},
		{name = "Hex", fn = function(): string? return Decoder.Hex(Txt) end},
		{name = "Binary", fn = function(): string? return Decoder.Binary(Txt) end},
		{name = "Octal", fn = function(): string? return Decoder.Octal(Txt) end},
		{name = "AsciiCodes", fn = function(): string? return Decoder.AsciiCodes(Txt) end},
		{name = "Uuencode", fn = function(): string? return Decoder.Uuencode(Txt) end},
		{name = "QuotedPrintable", fn = function(): string? return Decoder.QuotedPrintable(Txt) end},
		{name = "XorSingleByte", fn = function(): string? return Decoder.XorSingleByte(Txt) end},
		{name = "Morse", fn = function(): string? return Decoder.MorseDecode(Txt) end},
		{name = "Atbash", fn = function(): string? return Decoder.Atbash(Txt) end},
		{name = "Rot13", fn = function(): string? return Decoder.Rot13(Txt) end},
		{name = "Rot5", fn = function(): string? return Decoder.Rot5(Txt) end},
		{name = "Rot18", fn = function(): string? return Decoder.Rot18(Txt) end},
		{name = "Rot47", fn = function(): string? return Decoder.Rot47(Txt) end},
		{name = "A1Z26", fn = function(): string? return Decoder.A1Z26(Txt) end},
		{name = "Bacon", fn = function(): string? return Decoder.BaconDecode(Txt) end},
		{name = "Polybius", fn = function(): string? return Decoder.PolybiusDecode(Txt) end},
		{name = "Url", fn = function(): string? return Decoder.Url(Txt) end},
		{name = "Html", fn = function(): string? return Decoder.Html(Txt) end},
		{name = "Leet", fn = function(): string? return Decoder.LeetDecode(Txt) end},
		{name = "UnicodeEscape", fn = function(): string? return Decoder.UnicodeEscape(Txt) end},
		{name = "Reverse", fn = function(): string? return Decoder.Reverse(Txt) end},
		{name = "Zerowidth", fn = function(): string? return Decoder.Zerowidth(Txt) end},
		{name = "KeyboardRight", fn = function(): string? return Decoder.KeyboardShift(Txt, "right") end},
		{name = "KeyboardLeft", fn = function(): string? return Decoder.KeyboardShift(Txt, "left") end},
		{name = "Substitution", fn = function(): string? return Decoder.Substitution(Txt) end}
	}
	for _, Check in ipairs(Checks) do
		local S: boolean, R: any = pcall(Check.fn)
		if S and R and R ~= Txt and #R > 0 and not Seen[R] then
			local Score: number = Decoder.ScoreResult(R)
			if Score > 40 then
				Seen[R] = true
				Results[#Results + 1] = {method = Check.name, result = R, score = Score}
				if Depth < 3 then
					local Nested: {DecodeResult} = Decoder.Autodecode(R, Depth + 1)
					for _, N in ipairs(Nested) do
						if N.score > 40 and not Seen[N.result] then
							Seen[N.result] = true
							Results[#Results + 1] = {
								method = Check.name .. " → " .. N.method,
								result = N.result,
								score = N.score
							}
						end
					end
				end
			end
		end
	end
	for Shift = 1, 25 do
		local S: boolean, R: any = pcall(function(): string? return Decoder.Caesar(Txt, Shift) end)
		if S and R and R ~= Txt and not Seen[R] then
			local Score: number = Decoder.ScoreResult(R)
			if Score > 40 then
				Seen[R] = true
				Results[#Results + 1] = {method = "Caesar" .. Shift, result = R, score = Score}
			end
		end
	end
	for Rails = 2, 8 do
		local S: boolean, R: any = pcall(function(): string? return Decoder.Railfence(Txt, Rails) end)
		if S and R and R ~= Txt and not Seen[R] then
			local Score: number = Decoder.ScoreResult(R)
			if Score > 40 then
				Seen[R] = true
				Results[#Results + 1] = {method = "Railfence" .. Rails, result = R, score = Score}
			end
		end
	end
	table.sort(Results, function(A: DecodeResult, B: DecodeResult): boolean return A.score > B.score end)
	return Results
end

return Decoder