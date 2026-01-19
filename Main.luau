--!strict

type DecodeResult = {method: string, result: string, score: number}

local GetService: (any, string) -> any = clonefunction and clonefunction(game.GetService) or game.GetService
local Reference: (any) -> any = cloneref or function(X: any): any return X end

local Services: any = setmetatable({}, {
	__index = function(S: any, N: any): any
		S[N] = Reference(GetService(game, N))
		return S[N]
	end
})

local Decoder: any = loadstring(game:HttpGet("https://raw.githubusercontent.com/drevanyx666/Decoder/refs/heads/main/DecodeModule.luau"))()

local function ScoreResult(Original: string, Decoded: string): number
	if not Decoded or Decoded == Original or #Decoded == 0 then return 0 end
	
	local Printable: number = 0
	local Alpha: number = 0
	local Digit: number = 0
	local Space: number = 0
	local Special: number = 0
	
	for I: number = 1, #Decoded do
		local Byte: number = string.byte(Decoded, I)
		
		if Byte >= 32 and Byte <= 126 then
			Printable += 1
			
			if (Byte >= 65 and Byte <= 90) or (Byte >= 97 and Byte <= 122) then
				Alpha += 1
			elseif Byte >= 48 and Byte <= 57 then
				Digit += 1
			elseif Byte == 32 then
				Space += 1
			else
				Special += 1
			end
		end
	end
	
	if Printable == 0 then return 0 end
	
	local PrintableRatio: number = Printable / #Decoded
	if PrintableRatio < 0.8 then return 0 end
	
	local Score: number = PrintableRatio * 100
	
	local AlphaRatio: number = Alpha / #Decoded
	Score += AlphaRatio * 50
	
	local SpaceRatio: number = Space / #Decoded
	if SpaceRatio > 0.05 and SpaceRatio < 0.3 then
		Score += 30
	end
	
	local LengthRatio: number = #Decoded / #Original
	if LengthRatio > 0.3 and LengthRatio < 3 then
		Score += 20
	end
	
	return Score
end

local function ProcessText(Lbl: any): ()
	local Txt: string = Lbl.Text
	
	if #Txt >= 4 then
		local Results: {DecodeResult} = {}
		
		local Methods: {{name: string, decoder: (string) -> string?}} = {
			{name = "Morse", decoder = function(T: string): string? return Decoder.MorseDecode(T) end},
			{name = "Base64", decoder = function(T: string): string? return Decoder.Base64(T) end},
			{name = "Base64Url", decoder = function(T: string): string? return Decoder.Base64Url(T) end},
			{name = "Base32", decoder = function(T: string): string? return Decoder.Base32(T) end},
			{name = "Base62", decoder = function(T: string): string? return Decoder.Base62(T) end},
			{name = "Base58", decoder = function(T: string): string? return Decoder.Base58(T) end},
			{name = "Base36", decoder = function(T: string): string? return Decoder.Base36(T) end},
			{name = "Base85", decoder = function(T: string): string? return Decoder.Base85(T) end},
			{name = "Base91", decoder = function(T: string): string? return Decoder.Base91(T) end},
			{name = "Hex", decoder = function(T: string): string? return Decoder.Hex(T) end},
			{name = "Binary", decoder = function(T: string): string? return Decoder.Binary(T) end},
			{name = "Octal", decoder = function(T: string): string? return Decoder.Octal(T) end},
			{name = "ASCII", decoder = function(T: string): string? return Decoder.AsciiCodes(T) end},
			{name = "Atbash", decoder = function(T: string): string? return Decoder.Atbash(T) end},
			{name = "Rot13", decoder = function(T: string): string? return Decoder.Rot13(T) end},
			{name = "Rot5", decoder = function(T: string): string? return Decoder.Rot5(T) end},
			{name = "Rot18", decoder = function(T: string): string? return Decoder.Rot18(T) end},
			{name = "Rot47", decoder = function(T: string): string? return Decoder.Rot47(T) end},
			{name = "A1Z26", decoder = function(T: string): string? return Decoder.A1Z26(T) end},
			{name = "Bacon", decoder = function(T: string): string? return Decoder.BaconDecode(T) end},
			{name = "Polybius", decoder = function(T: string): string? return Decoder.PolybiusDecode(T) end},
			{name = "URL", decoder = function(T: string): string? return Decoder.Url(T) end},
			{name = "HTML", decoder = function(T: string): string? return Decoder.Html(T) end},
			{name = "Leet", decoder = function(T: string): string? return Decoder.LeetDecode(T) end},
			{name = "Unicode", decoder = function(T: string): string? return Decoder.UnicodeEscape(T) end},
			{name = "Reverse", decoder = function(T: string): string? return Decoder.Reverse(T) end},
			{name = "Zerowidth", decoder = function(T: string): string? return Decoder.Zerowidth(T) end},
			{name = "KeyboardRight", decoder = function(T: string): string? return Decoder.KeyboardShift(T, "right") end},
			{name = "KeyboardLeft", decoder = function(T: string): string? return Decoder.KeyboardShift(T, "left") end},
			{name = "Substitution", decoder = function(T: string): string? return Decoder.Substitution(T) end},
			{name = "JWT", decoder = function(T: string): string? return Decoder.JwtDecode(T) end},
			{name = "XOR", decoder = function(T: string): string? return Decoder.XorSingleByte(T) end},
			{name = "Uuencode", decoder = function(T: string): string? return Decoder.Uuencode(T) end},
			{name = "QuotedPrintable", decoder = function(T: string): string? return Decoder.QuotedPrintable(T) end},
		}
		
		for MethodIdx: number, Method: {name: string, decoder: (string) -> string?} in Methods do
			local _, Result: any = pcall(Method.decoder, Txt)
			if Result and Result ~= Txt then
				local Score: number = ScoreResult(Txt, Result)
				if Score > 0 then
					table.insert(Results, {
						method = Method.name,
						result = Result,
						score = Score
					})
				end
			end
		end
		
		for Shift: number = 1, 25 do
			local _, Caesar: any = pcall(Decoder.Caesar, Txt, Shift)
			if Caesar and Caesar ~= Txt then
				local Score: number = ScoreResult(Txt, Caesar)
				if Score > 0 then
					table.insert(Results, {
						method = `Caesar{Shift}`,
						result = Caesar,
						score = Score
					})
				end
			end
		end
		
		for Rails: number = 2, 8 do
			local _, Rail: any = pcall(Decoder.Railfence, Txt, Rails)
			if Rail and Rail ~= Txt then
				local Score: number = ScoreResult(Txt, Rail)
				if Score > 0 then
					table.insert(Results, {
						method = `Railfence{Rails}`,
						result = Rail,
						score = Score
					})
				end
			end
		end
		
		if #Results > 0 then
			table.sort(Results, function(A: DecodeResult, B: DecodeResult): boolean
				return A.score > B.score
			end)
			
			local Best: DecodeResult = Results[1]
			Lbl.Text = `"{Txt}" - {Best.method}: "{Best.result}"`
			Lbl.Font = Enum.Font.SourceSans
		end
	end
end

for Idx: number, Obj: Instance in Services.Workspace:GetDescendants() do
	if Obj:IsA("TextLabel") or Obj:IsA("TextButton") or Obj:IsA("TextBox") then
		ProcessText(Obj)
	end
end

Services.Workspace.DescendantAdded:Connect(function(Obj: Instance): ()
	if Obj:IsA("TextLabel") or Obj:IsA("TextButton") or Obj:IsA("TextBox") then
		ProcessText(Obj)
	end
end)
