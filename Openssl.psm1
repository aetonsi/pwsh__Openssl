New-Variable -Option Constant -Scope Script -Name OPENSSL_BIN -Value "openssl.exe"
New-Variable -Option Constant -Scope Script -Name OPENSSL_ALGO -Value "aes-256-cbc"
New-Variable -Option Constant -Scope Script -Name OPENSSL_ITER -Value 1000000
New-Variable -Option Constant -Scope Script -Name OPENSSL_PARAMS_COMMON -Value "-$OPENSSL_ALGO", "-pbkdf2", "-salt", "-iter=$OPENSSL_ITER", "-pass=stdin" # https://stackoverflow.com/a/55975571
New-Variable -Option Constant -Scope Script -Name OPENSSL_PARAMS_ENC -Value "enc", "-e"
New-Variable -Option Constant -Scope Script -Name OPENSSL_PARAMS_DEC -Value "enc", "-d"
New-Variable -Option Constant -Scope Script -Name OPENSSL_PARAMS_SPEED -Value "speed", "-decrypt"
New-Variable -Option Constant -Scope Script -Name OPENSSL_PARAMS_SPEED_ALGO -Value "$OPENSSL_ALGO"


function Get-Base64EncodedFilePlaintextSize {
	# calculates the plaintext size of a base64 encoded file
	Param (
		[Parameter(Mandatory=$true)] [string] $in
	)

	###################################

	$filecontent = Get-Content -raw -path $in
	$n = $filecontent.Trim().Length # necessary because encryption leaves an empty newline
	$y = 0
	$y = If($filecontent -match '=$'){1}
	$y = If($filecontent -match '==$'){2}
	$x = [math]::Ceiling($n / 4) * 3 - $y # https://stackoverflow.com/a/45732035
	return $x
}

function Invoke-OpensslSpeed {
	# runs `openssl speed`
	Param (
		[Parameter(Mandatory=$true)] [string] $in, # input file (encrypted) path
		[Parameter(Mandatory=$false)] [switch] $base64, # whether or the input file had been base64 encoded
		[Parameter(Mandatory=$false)] [int] $seconds = 3 # duration of benchmark
	)

	###################################

	if ($base64) {
		$bytes = Get-Base64EncodedFilePlaintextSize -in $in
	} else {
		$bytes = (Get-Item $in).Length
	}
	& $OPENSSL_BIN $OPENSSL_PARAMS_SPEED -seconds="$seconds" -bytes="$bytes" $OPENSSL_PARAMS_SPEED_ALGO
}

function ConvertTo-OpensslEncrypted {
	# encrypts $in file with $pass, then [returns/outputs to file $out] the contents
	Param (
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)] [string] $pass, # password/key for encryption
		[Parameter(Mandatory=$true)] [string] $in, # input file (plaintext) path
		[Parameter(Mandatory=$false)] [string] $out = "", # output file path; if not specified, outputs to console
		[Parameter(Mandatory=$false)] [switch] $base64 # whether or the output should be base64 encoded
	)

	###################################

	$PARAM_OUT = If($out -ne "") {"-out=$out"} else {""}
	$PARAM_BASE64 = If($base64) {"-base64"} else {""}
	$encryptedtext = $pass | & $OPENSSL_BIN $OPENSSL_PARAMS_ENC $OPENSSL_PARAMS_COMMON $PARAM_BASE64 -in="$in" $PARAM_OUT
	if ($LASTEXITCODE -ne 0) {
		return $false
	} else {
		if ($out -ne "") {
			return $true
		} else {
			return $encryptedtext
		}
	}
}

function ConvertFrom-OpensslEncrypted {
	# decrypts $in file with $pass, then [returns/outputs to file $out] the contents
	Param (
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)] [string] $pass, # password/key for decryption
		[Parameter(Mandatory=$true)] [string] $in, # input file (encrypted) path
		[Parameter(Mandatory=$false)] [string] $out = "", # output file path; if not specified, outputs to console
		[Parameter(Mandatory=$false)] [switch] $base64 # whether or the input file had been base64 encoded
	)

	###################################

	$PARAM_OUT = If($out -ne "") {"-out=$out"} else {""}
	$PARAM_BASE64 = If($base64) {"-base64"} else {""}
	$plaintext = $pass | & $OPENSSL_BIN $OPENSSL_PARAMS_DEC $OPENSSL_PARAMS_COMMON $PARAM_BASE64 -in="$in" $PARAM_OUT
	if ($LASTEXITCODE -ne 0) {
		return $false
	} else {
		if ($out -ne "") {
			return $true
		} else {
			return $plaintext
		}
	}
}

function Read-OpensslEncryptedFileLineAsUtf8 {
	# decrypts $in file with $pass, then [returns/outputs to file $out] the contents of line n° $line (encoded as utf8nobom)
	Param (
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)] [string] $pass, # password/key for decryption
		[Parameter(Mandatory=$true)] [string] $in, # input file (encrypted) path
		[Parameter(Mandatory=$false)] [string] $out = "", # output file path; if not specified, outputs to console
		[Parameter(Mandatory=$true)] [int] $line, # line number to read in the plaintext file
		[Parameter(Mandatory=$false)] [switch] $base64 # whether or the input file had been base64 encoded
	)

	###################################

	if ($line -le 0) {
		return $false
	} else {
		$plaintext = $pass | ConvertFrom-OpensslEncrypted -base64:$base64 -in $in
		if ($plaintext -eq $false) {
			return $false
		} else {
			$splitplaintext = $plaintext -split '\r?\n'
			$splitplaintextcount = ($splitplaintext | Measure-Object).count
			if ($line -gt $splitplaintextcount) {
				return $false
			} else {
				if ($out -eq "") {
					return $splitplaintext[$line-1]
				} else {
					$splitplaintext[$line-1] | Out-File -Encoding utf8NoBOM -NoNewline -FilePath $out
					return $true
				}
			}
		}
	}
}


Export-ModuleMember -Function *
